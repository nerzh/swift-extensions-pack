//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 15.05.2023.
//

import Foundation

public func randomBytes(count: UInt) -> [UInt8] {
    var generator = SystemRandomNumberGenerator()
    return (0..<count).map({ _ in UInt8.random(in: 0...UInt8.max, using: &generator) })
}

public func randomNumber(min: UInt, max: UInt) -> UInt {
    let range = max - min
    var bitsNeeded = UInt(ceil(log2(Double(range))))
    bitsNeeded = bitsNeeded == 0 ? 1 : bitsNeeded
    let bytesNeeded = UInt(ceil(Double(bitsNeeded) / 8.0))
    let mask: UInt = bitsNeeded >= 64 ? UInt.max : (1 << bitsNeeded) - 1
    
    while true {
        var numberValue: UInt = 0
        let res = randomBytes(count: bytesNeeded)
        var power = (bytesNeeded - 1) * 8
        power += 8
        for byte in res {
            power -= 8
            numberValue += UInt(byte) * (1 << power)
        }
        
        numberValue &= mask
        if numberValue < range {
            return min + numberValue
        }
    }
}
