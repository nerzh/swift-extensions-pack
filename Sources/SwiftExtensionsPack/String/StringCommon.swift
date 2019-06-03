//
//  StringCommon.swift
//  swift-extensions-pack
//
//  Created by Oleh Hudeichuk on 3/6/19.
//

import Foundation


// Converte Hex Unicode to Character
public func hexToCharacter(_ hexString: String) -> Character {
    var result = Character("")
    if let decimal = Int(hexString, radix: 16) {
        result = Character(UnicodeScalar(decimal)!)
    }
    return result
}
