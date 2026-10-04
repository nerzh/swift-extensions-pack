//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 09.03.2024.
//

import Foundation
import CEd25519
import Ed25519
#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(Crypto)
import Crypto
#endif


extension SEPCrypto {
    
    public final class Ed25519 {

        public enum KeyError: Error, LocalizedError, Equatable {
            case invalidPublicKeyLength(actual: Int)
            case invalidPrivateKeyLength(actual: Int)
            case nonCanonicalYCoordinate
            case undefinedMontgomeryCoordinate
            case zeroSharedSecret

            public var errorDescription: String? {
                switch self {
                case .invalidPublicKeyLength(let actual):
                    return "An Ed25519 public key must contain exactly 32 bytes; received \(actual)."
                case .invalidPrivateKeyLength(let actual):
                    return "The prepared private scalar must contain exactly 32 bytes; received \(actual)."
                case .nonCanonicalYCoordinate:
                    return "The Ed25519 y-coordinate must be less than 2^255 - 19."
                case .undefinedMontgomeryCoordinate:
                    return "The Montgomery coordinate is undefined for Ed25519 y = 1."
                case .zeroSharedSecret:
                    return "Key exchange produced an all-zero shared secret."
                }
            }
        }
        
        public static func createKeyPair(seed32Byte: Data) -> (public: Data, secret: Data) {
            let publicKeyPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: 32)
            let secretKeyPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
            
            var seed = seed32Byte
            seed.withUnsafeMutableBytes { (p: UnsafeMutableRawBufferPointer) in
                ed25519_create_keypair(publicKeyPtr, secretKeyPtr, p.bindMemory(to: UInt8.self).baseAddress)
            }
            
            let publicKey = UnsafeMutableBufferPointer<UInt8>.init(start: publicKeyPtr, count: 32)
            let secretKey = UnsafeMutableBufferPointer<UInt8>.init(start: secretKeyPtr, count: 64)
            defer {
                publicKey.deinitialize()
                publicKey.deallocate()
                secretKey.deinitialize()
                secretKey.deallocate()
            }
            
            /// Initialize a `Data(buffer: UnsafeMutableBufferPointer<SourceType>)` with copied memory content.
            return (public: Data(buffer: publicKey), secret: Data(buffer: secretKey))
        }
        
        public static func createKeyPairHex(seed32Byte: Data) -> (public: String, secret: String) {
            let keys: (public: Data, secret: Data) = createKeyPair(seed32Byte: seed32Byte)
            return (public: keys.public.toHexadecimal, secret: keys.secret.toHexadecimal)
        }
        
        public static func sign(message: Data, publicKey32byte: Data, secretKey64byte: Data) -> Data {
            let signaturePtr = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
            var message: [UInt8] = message.bytes
            var publicKey: [UInt8] = publicKey32byte.bytes
            var secretKey: [UInt8] = secretKey64byte.bytes
            
            ed25519_sign(signaturePtr, &message, message.count, &publicKey, &secretKey)
            
            let signature = UnsafeMutableBufferPointer<UInt8>.init(start: signaturePtr, count: 64)
            defer {
                signature.deinitialize()
                signature.deallocate()
            }

            return Data(buffer: signature)
        }
        
        public static func createPublicKey(secretKey: Data) -> Data {
            let publicKeyPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: 32)
            var secretKey: [UInt8] = secretKey.bytes
            
            ed25519_create_public_key(publicKeyPtr, &secretKey)
            
            let publicKey = UnsafeMutableBufferPointer<UInt8>.init(start: publicKeyPtr, count: 32)
            defer {
                publicKey.deinitialize()
                publicKey.deallocate()
            }

            return Data(buffer:publicKey)
        }
        
        /// Converts a 32-byte compressed Ed25519 public key to a 32-byte,
        /// little-endian Montgomery u-coordinate: (1 + y) / (1 - y) mod (2^255 - 19).
        /// The Edwards x-sign bit is ignored. Data slices are supported.
        ///
        /// This only converts coordinates: it does not check that the encoding
        /// represents a curve point or that the point belongs to the prime-order subgroup.
        /// - Throws: `KeyError` for an invalid length, noncanonical y, or y = 1.
        public static func edwardsToMontgomery(bytesData: Data) throws -> Data {
            guard bytesData.count == 32 else {
                throw KeyError.invalidPublicKeyLength(actual: bytesData.count)
            }
            do {
                return Data(try PublicKey(bytesData.bytes).toX25519())
            } catch Ed25519ConversionError.nonCanonicalPublicKey {
                throw KeyError.nonCanonicalYCoordinate
            } catch Ed25519ConversionError.undefinedMontgomeryCoordinate {
                throw KeyError.undefinedMontgomeryCoordinate
            }
        }

        /// Checks the coordinate encoding while preserving the original Edwards bytes.
        private static func validatedEdwardsPublicKey(_ data: Data) throws -> [UInt8] {
            guard data.count == 32 else {
                throw KeyError.invalidPublicKeyLength(actual: data.count)
            }
            let bytes = data.bytes
            var y = bytes
            y[31] &= 0x7f
            let prime: [UInt8] = [0xed] + [UInt8](repeating: 0xff, count: 30) + [0x7f]
            guard y.reversed().lexicographicallyPrecedes(prime.reversed()) else {
                throw KeyError.nonCanonicalYCoordinate
            }
            guard !(y[0] == 1 && y.dropFirst().allSatisfy { $0 == 0 }) else {
                throw KeyError.undefinedMontgomeryCoordinate
            }
            return bytes
        }
        
        /// Derives a prepared X25519 scalar by hashing an original 32-byte Ed25519 seed
        /// with SHA-512 and clamping the first 32 bytes. Do not pass an already prepared
        /// scalar or the expanded 64-byte secret returned by `createKeyPair(seed32Byte:)`.
        public static func convertEd25519ToX25519(ed25519PrivateKey: Data) -> Data {
            var sha512Hash: Data = .init(SHA512.hash(data: ed25519PrivateKey))
            
            sha512Hash[0] &= 248
            sha512Hash[31] &= 127
            sha512Hash[31] |= 64
            
            return sha512Hash[0...31]
        }
        
        /// Returns a 32-byte raw shared secret using a prepared 32-byte private scalar
        /// and the peer's original 32-byte compressed Ed25519 public key.
        ///
        /// Use `createKeyPair(seed32Byte:).secret.prefix(32)` or the result of
        /// `convertEd25519ToX25519(ed25519PrivateKey:)` as the private input, not a seed.
        /// The C implementation clamps the scalar without hashing and converts the
        /// Edwards public key internally. Do not pass `edwardsToMontgomery` output here.
        /// Public-key validation is limited to the coordinate encoding, not curve or
        /// subgroup membership; an all-zero shared secret is rejected.
        /// - Throws: `KeyError` for invalid input lengths, noncanonical y, y = 1,
        ///   or an all-zero shared secret.
        public static func getKeyExchange(privateKey: Data, publicKey: Data) throws -> Data {
            guard privateKey.count == 32 else {
                throw KeyError.invalidPrivateKeyLength(actual: privateKey.count)
            }
            let publicKey = try validatedEdwardsPublicKey(publicKey)
            let privateKey = privateKey.bytes
            var buffer: [UInt8] = .init(repeating: 0, count: 32)
            
            ed25519_key_exchange(&buffer, publicKey, privateKey)
            guard buffer.reduce(UInt8(0), |) != 0 else {
                throw KeyError.zeroSharedSecret
            }
            
            return Data(buffer)
        }
        
        public static func verify(signature: Data, message: Data, len: Int, publicKey: Data) -> Bool {
            var message: [UInt8] = message.bytes
            var publicKey: [UInt8] = publicKey.bytes
            var signature: [UInt8] = signature.bytes
            
            let int: Int32 = ed25519_verify(&signature, &message, len, &publicKey)
            
            return int == 1
        }
    }
}
