//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 01.09.2023.
//

import Foundation

@frozen public struct SafeValue<Value> {
    private let lock: NSRecursiveLock = .init()
    private var _value: Value
    public var value: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
    }
    
    public init(_ value: Value) {
        _value = value
    }
    
    public mutating func change(_ callback: (inout Value) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        callback(&_value)
    }
}

