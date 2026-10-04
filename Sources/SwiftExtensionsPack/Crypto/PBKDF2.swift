import Foundation
import CryptoExtras

extension SEPCrypto {
    public enum PBKDF2Error: Error, LocalizedError, Equatable {
        case invalidIterations(actual: Int)
        case invalidKeyLength(actual: Int)
        case derivationFailed

        public var errorDescription: String? {
            switch self {
            case .invalidIterations(let actual):
                return "PBKDF2 iterations must be positive and fit in UInt32; received \(actual)."
            case .invalidKeyLength(let actual):
                return "PBKDF2 key length must be positive, fit in UInt32 bytes, and fit in Int bits; received \(actual)."
            case .derivationFailed:
                return "PBKDF2-HMAC-SHA512 key derivation failed."
            }
        }
    }

    public static func pbkdf2SHA512(
        password: Data,
        salt: Data,
        iterations: Int,
        keyLength: Int
    ) throws -> Data {
        guard iterations > 0, UInt32(exactly: iterations) != nil else {
            throw PBKDF2Error.invalidIterations(actual: iterations)
        }
        // CryptoExtras converts rounds to UInt32, and Swift Crypto's SecureBytes
        // uses UInt32 capacity. SymmetricKey also represents the bit count as Int.
        guard keyLength > 0, UInt32(exactly: keyLength) != nil, keyLength <= Int.max / 8 else {
            throw PBKDF2Error.invalidKeyLength(actual: keyLength)
        }

        // CryptoExtras 5.0 force-unwraps input buffer addresses. Empty slices of
        // allocated storage keep a non-null address while passing zero bytes.
        let passwordBytes = (password.isEmpty ? [0] : Array(password)).prefix(password.count)
        let saltBytes = (salt.isEmpty ? [0] : Array(salt)).prefix(salt.count)

        do {
            let key = try KDF.Insecure.PBKDF2.deriveKey(
                from: passwordBytes,
                salt: saltBytes,
                using: .sha512,
                outputByteCount: keyLength,
                // TON requires exact iteration counts, including 1 and 390.
                unsafeUncheckedRounds: iterations
            )
            return key.withUnsafeBytes { Data($0) }
        } catch {
            throw PBKDF2Error.derivationFailed
        }
    }
}
