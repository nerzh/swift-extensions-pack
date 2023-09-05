//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 01.09.2023.
//

import Foundation

final public class SafeValue<Value> {
    private let lock: NSLock = .init()
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
    
    public func change(_ callback: (inout Value) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        callback(&_value)
    }
}

