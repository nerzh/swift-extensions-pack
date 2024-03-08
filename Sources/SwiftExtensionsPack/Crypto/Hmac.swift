//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 11.06.2022.
//

import Foundation
#if os(Linux)
import Crypto
#else
import CryptoKit
#endif

private typealias CryptoHMAC = HMAC

public extension SEPCrypto {
    enum HMAC: Cases {
        case sha256
        case sha384
        case sha512
        
        public func digest(data: Data, key: Data) -> Data {
            switch self {
            case .sha256:
                return hmac(SHA256.self, data: data, key: key)
            case .sha384:
                return hmac(SHA384.self, data: data, key: key)
            case .sha512:
                return hmac(SHA512.self, data: data, key: key)
            }
        }
        
        public func digest(data: Data, key: Data) -> String {
            let digest: Data = digest(data: data, key: key)
            return digest.toHexadecimal
        }
        
        public func digest(string: String, key: String) -> String {
            digest(data: Data(string.utf8), key: Data(key.utf8))
        }
        
        private func hmac<T: HashFunction>(_ t: T.Type, data: Data, key: Data) -> Data {
            let key = SymmetricKey(data: key)
            let signature = CryptoHMAC<T>.authenticationCode(for: data, using: key)
            return Data(signature)
        }
    }
}
