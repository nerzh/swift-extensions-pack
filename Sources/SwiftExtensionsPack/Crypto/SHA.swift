//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 14.03.2024.
//

import Foundation
#if os(Linux)
import Crypto
#else
import CryptoKit
#endif

public extension SEPCrypto {
    enum SHA {
        case sha256
        case sha384
        case sha512
        
        public func digest(data: Data) -> any Digest {
            switch self {
            case .sha256:
                SHA256.hash(data: data)
            case .sha384:
                SHA384.hash(data: data)
            case .sha512:
                SHA512.hash(data: data)
            }
        }
    }
}
