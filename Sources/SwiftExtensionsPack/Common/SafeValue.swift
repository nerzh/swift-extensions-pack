//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 01.09.2023.
//

import Foundation

final public class SafeValue<Value>: @unchecked Sendable {
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

    @discardableResult
    public func change<T>(_ callback: (inout Value) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return callback(&_value)
    }
}

