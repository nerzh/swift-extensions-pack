//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 21.03.2023.
//

import Foundation
#if os(Linux)
import Crypto
#else
import CryptoKit
#endif

@available(iOS 13.0, macOS 10.15, *)
public class SEPCrypto {}

@available(iOS 13.0, macOS 10.15, *)
public extension SEPCrypto {
    /// encrypt AES-256 GCM
    class func encryptAES256GCM(data: Data, key: Data, nonce: AES.GCM.Nonce = .init()) throws -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey, nonce: nonce)
        return sealedBox.combined!
    }

    /// decrypt AES-256 GCM
    class func decryptAES256GCM(data: Data, key: Data) throws -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
}

@available(iOS 13.0, macOS 10.15, *)
public extension String {

    func encryptAES256(key: Data, nonce: AES.GCM.Nonce = .init()) throws -> Data {
        guard let data: Data = self.data(using: .utf8) else {
            throw SEPCommonError("Failed to get Data from text")
        }
        return try SEPCrypto.encryptAES256GCM(data: data, key: key, nonce: nonce)
    }

    func decryptAES256(key: Data) throws -> Data {
        guard let hexData: Data = self.dataFromHex else {
            throw SEPCommonError("Try to get Data from hexString failed. Pleasw, only hex format !")
        }
        return try SEPCrypto.decryptAES256GCM(data: hexData, key: key)
    }

    func encryptAES256(key: Data, nonce: AES.GCM.Nonce = .init()) throws -> String {
        try (encryptAES256(key: key, nonce: nonce) as Data).toHexadecimal
    }

    func decryptAES256(key: Data) throws -> String {
        let data: Data = try decryptAES256(key: key)
        guard let text: String = String(data: data, encoding: .utf8) else {
            throw SEPCommonError("Try to get text from decryptrd Data failed.")
        }
        return text
    }

    /// Key will be converted to hex
    func encryptAES256(key: String, nonce: Data? = nil) throws -> String {
        let convertedKey: Data = try key.convertToAESKey()
        let convertedNonce: AES.GCM.Nonce = nonce == nil ? .init() : try .init(data: Data(SHA256.hash(data: nonce!))[0..<12])
        return try encryptAES256(key: convertedKey, nonce: convertedNonce)
    }

    /// Key will be converted to hex
    func decryptAES256(key: String) throws -> String {
        let convertedKey: Data = try key.convertToAESKey()
        return try decryptAES256(key: convertedKey)
    }
    
    func convertToAESKey() throws -> Data {
        let data: Data = Data(self.utf8)
        return Data(SHA256.hash(data: data))
    }
    
    func toAESKey() throws -> Data { try convertToAESKey() }
}
