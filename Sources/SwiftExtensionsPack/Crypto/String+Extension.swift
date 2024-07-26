//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 21.03.2023.
//

import Foundation
import SwiftRegularExpression

public extension String {
    
    var dataFromHex: Data? { Data(hexString: self) }
    
    func dataFromHexThrowing() throws -> Data {
        guard let data = Data(hexString: self) else {
            throw makeError(SEPCommonError("Try get Data from hexString failed. Please, only hex format !"))
        }
        return data
    }
    
    var isHexNumber: Bool {
        filter(\.isHexDigit).count == count
    }
    
    var hexToUInt: UInt {
        get throws {
            guard let value = UInt(self, radix: 16) else {
                throw SEPCommonError("Can not convert hex: \(self) to UInt")
            }
            return value
        }
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

