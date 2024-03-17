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

public func randomUInt(min: UInt, max: UInt) -> UInt {
    var generator = SystemRandomNumberGenerator()
    return UInt.random(in: min...max, using: &generator)
}

public func randomInt(min: Int, max: Int) -> Int {
    var generator = SystemRandomNumberGenerator()
    return Int.random(in: min...max, using: &generator)
}
