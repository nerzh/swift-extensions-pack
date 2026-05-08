//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 11.06.2022.
//

import Foundation
import SwiftRegularExpression

extension String {
    
    public func dataFromHexThrowing() throws -> Data {
        guard let data = Data(hexString: self) else {
            throw SEPCommonError("Try get Data from hexString failed. Please, only hex format !")
        }
        return data
    }
    
    public var isHexNumber: Bool {
        filter(\.isHexDigit).count == count
    }
    
    public var hexToUInt: UInt {
        get throws {
            guard let value = UInt(self, radix: 16) else {
                throw SEPCommonError("Can not convert hex: \(self) to UInt")
            }
            return value
        }
    }
    
    // MARK: Text From Hex
    public init?(hexadecimal string: String, encoding: String.Encoding = .utf8) {
        guard let data = string.hexToData else { return nil }
        self.init(data: data, encoding: encoding)
    }
    
    public func toText(encoding: String.Encoding = .utf8) -> String? {
        String(hexadecimal: self, encoding: encoding)
    }

    // MARK: Data From Hex
    public var hexToData: Data? { Data(hexString: self) }
    public var dataFromHex: Data? { hexToData }

    public var textToHex: String {
        let data: Data = .init(self.utf8)
        return data.toHexadecimal
    }
    
    // MARK: Unicode
    /// "043d".hexToCharacter()
    /// Converte Hex Unicode to Character
    public func hexToCharacter() -> Character {
        var result = Character(UnicodeScalar(0)!)
        if let decimal = Int(self, radix: 16) {
            result = Character(UnicodeScalar(decimal)!)
        }
        return result
    }
    
    public var add0x: String {
        if !self[#"^0x"#] {
            return "0x\(self)"
        }
        return self
    }
    public var remove0x: String { self.replace(#"^0x"#, "") }
    public var delete0x: String { self.remove0x }
    
    /// this nedeed only for initializator Data(stringHex: hex)
    public var addFirstZeroToHexIfNeeded: String {
        if !self[#"^0x"#], self.count % 2 != 0 {
            return "0" + self
        }
        return self
    }
    
    public var hexClear: String {
        self.replace(#"^0x0+"#, "0x")
    }
    
    public func dataFromHexOrBase64() throws -> Data {
        if self.isHexNumber {
            return try self.remove0x.dataFromHexThrowing()
        } else if self.isBase64() {
            return Data(base64Encoded: self)!
        } else {
            throw SEPCommonError("\(self) undefined Data String format")
        }
    }
}

extension Data {

    public init?(hexString: String) {
        let hexString = hexString.addFirstZeroToHexIfNeeded
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var i = hexString.startIndex
        for _ in 0..<len {
            let j = hexString.index(i, offsetBy: 2)
            let bytes = hexString[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
    
    public var toHexadecimal: String {
        self.map { 
            let hex = String($0, radix: 16)
            return hex.count == 1 ? "0" + hex : hex
        }.joined()
    }
}

