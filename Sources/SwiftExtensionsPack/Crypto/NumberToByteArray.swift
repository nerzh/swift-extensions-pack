//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 17.05.2023.
//

import Foundation

public protocol ToBytesConvertable: FixedWidthInteger {
    func toBytes(endian: Endianness) -> [UInt8]
    func toBytes(endian: Endianness, count: Int) -> [UInt8]
    init(_ bytes: [UInt8])
    init(_ bytes: [UInt8], endian: Endianness)
}


public enum Endianness {
    case bigEndian
    case littleEndian
}


public extension ToBytesConvertable {
    func toBytes(endian: Endianness) -> [UInt8] {
        let count: Int = MemoryLayout<Self>.size
        return toBytes(endian: endian, count: count)
    }
    
    func toBytes(endian: Endianness, count: Int) -> [UInt8] {
        var integer: Self
        switch endian {
        case .bigEndian: integer = self.bigEndian
        case .littleEndian: integer = self.littleEndian
        }
        
        return withUnsafePointer(to: &integer) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                [UInt8](UnsafeBufferPointer(start: $0, count: count))
            }
        }
    }
    
    init(_ bytes: [UInt8]) {
        self = Self.init(bytes, endian: .littleEndian)
    }
    
    init(_ bytes: [UInt8], endian: Endianness) {
        var bytes: [UInt8] = bytes
        if endian == .bigEndian {
            bytes = bytes.reversed()
        }
        let data: Data = .init(bytes)
        let number = data.withUnsafeBytes { $0.load(as: Self.self) }
        self = number
    }
}


extension UInt16: ToBytesConvertable {}
extension UInt32: ToBytesConvertable {}
extension UInt64: ToBytesConvertable {}
extension UInt: ToBytesConvertable {}


extension Int16: ToBytesConvertable {}
extension Int32: ToBytesConvertable {}
extension Int64: ToBytesConvertable {}
extension Int: ToBytesConvertable {}


