//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 11.06.2022.
//

import Foundation
import SwiftRegularExpression

extension String {

    public init?(hexadecimal string: String, encoding: String.Encoding = .utf8) {
        guard let data = string.hexadecimalToData else { return nil }
        self.init(data: data, encoding: encoding)
    }

    public var hexadecimalToData: Data? {
        Data(hexString: self)
    }

    public var toHexadecimal: String {
        let data: Data = .init(self.utf8)
        return data.map { String(format: "%02x", $0) }.joined()
    }
    
    public func fromHexadecimal(encoding: String.Encoding = .utf8) -> String? {
        String(hexadecimal: self, encoding: encoding)
    }
    
    public var addHexZeroX: String {
        if !self[#"^0x"#] {
            return "0x\(self)"
        }
        return self
    }
    public var removeHexZeroX: String { self.replace(#"^0x"#, "") }
    public var deleteHexZeroX: String { self.removeHexZeroX }
    public var add0x: String { addHexZeroX }
    public var remove0x: String { self.removeHexZeroX }
    public var delete0x: String { self.removeHexZeroX }
    
    /// this nedeed only for initializator Data(stringHex: hex)
    public var addFirstZeroToHexIfNeeded: String {
        var result: String = self
        if !result[#"^0x"#], result.count % 2 != 0 {
            result = "0" + result
        }
        
        return result
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

