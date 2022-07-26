//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 11.06.2022.
//

import Foundation
import SwiftRegularExpression

public extension String {

    init?(hexadecimal string: String, encoding: String.Encoding = .utf8) {
        guard let data = string.hexadecimalToData else { return nil }
        self.init(data: data, encoding: encoding)
    }

    var hexadecimalToData: Data? {
        Data(hexString: self)
    }

    var toHexadecimal: String {
        let data: Data = .init(self.utf8)
        return data.map { String(format: "%02x", $0) }.joined()
    }
    
    func fromHexadecimal(encoding: String.Encoding = .utf8) -> String? {
        String(hexadecimal: self, encoding: encoding)
    }
    
    var addHexZeroX: String {
        if !self[#"^0x"#] {
            return "0x\(self)"
        }
        return self
    }
    var removeHexZeroX: String { self.replace(#"^0x"#, "") }
    var deleteHexZeroX: String { self.removeHexZeroX }
    var add0x: String { addHexZeroX }
    var remove0x: String { self.removeHexZeroX }
    var delete0x: String { self.removeHexZeroX }
    
    /// this nedeed only for initializator Data(stringHex: hex)
    var addFirstZeroToHexIfNeeded: String {
        var result: String = self
        if !result[#"^0x"#], result.count % 2 != 0 {
            result = "0" + result
        }
        
        return result
    }
    
    var hexClear: String {
        self.replace(#"^0x0+"#, "0x")
    }
}

extension Data {

    init?(hexString: String) {
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
}


