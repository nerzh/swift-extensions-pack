//
//  SEPAtomic.swift
//  
//
//  Created by Oleh Hudeichuk on 05.04.2020.
//

import Foundation

/// @SEPAtomic var threadSafeVariable: [Int] = [1 , 2,  3]
@available(swift, introduced: 5.1)
@propertyWrapper
struct SEPAtomic<Value: AnyObject> {

    private var value: Value
    private let lock = NSLock()

    init(wrappedValue value: Value) {
        self.value = value
    }

    var wrappedValue: Value {
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
