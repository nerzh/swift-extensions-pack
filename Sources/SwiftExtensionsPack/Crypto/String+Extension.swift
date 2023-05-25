//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 21.03.2023.
//

import Foundation
import SwiftRegularExpression

public extension String {
    func bytes(_ using: Encoding = .utf8) -> Int {
        self.data(using: using)?.count ?? 0
    }
    
    // TO DECODABLE STRUCT
    func toModel<T>(_ model: T.Type) -> T? where T : Decodable {
        guard let data = self.data(using: String.Encoding.utf8) else { return nil }
        return try? JSONDecoder().decode(model, from: data)
    }
    
    func getPointer<T>(_ handler: (_ pointer: UnsafePointer<T>, _ len: Int) throws -> Void) rethrows {
        var string = self
        try string.withUTF8 { (p: UnsafeBufferPointer<UInt8>) in
            try p.baseAddress?.withMemoryRebound(to: T.self, capacity: p.count) { (p2: UnsafePointer<T>) in
                try handler(p2, p.count)
            }
        }
    }
    
    var dataFromHex: Data? { Data(hexString: self) }
    
    func dataFromHexThrowing() throws -> Data {
        guard let data = Data(hexString: self) else {
            throw makeError(SEPCommonError.mess("Try get Data from hexString failed. Please, only hex format !"))
        }
        return data
    }
    
    var isHexNumber: Bool {
        filter(\.isHexDigit).count == count
    }
}


// MARK: Unicode
extension String {

    /// "043d".hexToCharacter()
    public func hexToCharacter() -> Character {
        return SwiftExtensionsPack.hexToCharacter(self)
    }
}


// MARK: BASE64
public extension String {
    
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    func isBase64() -> Bool {
        let regexp = #"^(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?$"#
        return self.trimmingCharacters(in: .whitespacesAndNewlines)[regexp]
    }
}

