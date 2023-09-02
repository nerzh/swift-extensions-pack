//
//  SEPAtomic.swift
//  
//
//  Created by Oleh Hudeichuk on 05.04.2020.
//

import Foundation

/// @Atomic var threadSafeVariable: [Int] = [1 , 2,  3]
@available(swift, introduced: 5.1)
@propertyWrapper
@frozen public struct Atomic<Value: AnyObject> {

    private var value: Value
    private let lock = NSLock()

    public init(wrappedValue value: Value) {
        self.value = value
    }

    public var wrappedValue: Value {
      get { return load() }
      set { store(newValue: newValue) }
    }

    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    mutating func store(newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}


@available(swift, introduced: 5.1)
@propertyWrapper
@frozen public struct AtomicOptional<Value: AnyObject> {

    private var value: Value?
    private let lock = NSLock()

    public init(wrappedValue value: Value?) {
        self.value = value
    }

    public var wrappedValue: Value? {
      get { return load() }
      set { store(newValue: newValue) }
    }

    func load() -> Value? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    mutating func store(newValue: Value?) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}
