//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 09.03.2024.
//

import Foundation
import CEd25519
import Ed25519
#if os(Linux)
import Crypto
#else
import CryptoKit
#endif


public extension SEPCrypto {
    
    final class Ed25519 {
        
        public class func createKeyPair(seed32Byte: Data) -> (public: Data, secret: Data) {
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
        
        public class func createKeyPairHex(seed32Byte: Data) -> (public: String, secret: String) {
            let keys: (public: Data, secret: Data) = createKeyPair(seed32Byte: seed32Byte)
            return (public: keys.public.toHexadecimal, secret: keys.secret.toHexadecimal)
        }
        
        public class func sign(message: Data, publicKey32byte: Data, secretKey64byte: Data) -> Data {
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
        
        public class func createPublicKey(secretKey: Data) -> Data {
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
        
        public class func edwardsToMontgomery(bytesData: Data) -> Data {
            var bytesData: Data = bytesData
            var y_coordinate: UInt8 = bytesData[31] & 0x7F
            if (bytesData[31] & 0x80) != 0 {
                y_coordinate += 0x80
            }
            bytesData.append(y_coordinate)
            
            return bytesData
        }
        
        public class func convertEd25519ToX25519(ed25519PrivateKey: Data) -> Data {
            var sha512Hash: Data = .init(SHA512.hash(data: ed25519PrivateKey))
            
            sha512Hash[0] &= 248
            sha512Hash[31] &= 127
            sha512Hash[31] |= 64
            
            return sha512Hash[0...31]
        }
        
        public class func getKeyExchange(privateKey: Data, publicKey: Data) -> Data {
            var privateKey: [UInt8] = privateKey.bytes
            var publicKey: [UInt8] = publicKey.bytes
            var buffer: [UInt8] = .init(repeating: 0, count: 32)
            
            ed25519_key_exchange(&buffer, &publicKey, &privateKey)
            
            return Data(buffer)
        }
        
        public class func verify(signature: Data, message: Data, len: Int, publicKey: Data) -> Bool {
            var message: [UInt8] = message.bytes
            var publicKey: [UInt8] = publicKey.bytes
            var signature: [UInt8] = signature.bytes
            
            let int: Int32 = ed25519_verify(&signature, &message, len, &publicKey)
            
            return int == 1
        }
    }
}
