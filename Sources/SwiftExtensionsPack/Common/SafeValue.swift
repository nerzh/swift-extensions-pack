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

final public class SendableValue<Value>: @unchecked Sendable {
    private var data: Value
    /// A attributes: .concurrent synchronization queue used to allow multiple reads to run
    /// in parallel while mutations are executed exclusively with barrier blocks.
    ///
    /// The main advantage over a serial queue is that independent `read()` calls
    /// do not block each other.
    private let queue = DispatchQueue(
        label: "SendableValue.queue",
        attributes: .concurrent
    )

    public init(_ val: Value) {
        self.data = val
    }

    /// Returns the currently stored value.
    ///
    /// - Warning: For reference-type values, this returns the underlying object
    ///   reference. Mutating that object outside of `change(_:)` bypasses this
    ///   wrapper's synchronization and may cause data races. Treat returned
    ///   reference values as read-only unless they are independently thread-safe.
    ///
    /// - Returns: The current value stored in this wrapper.
    public func read() async -> Value {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.data)
            }
        }
    }

    /// Mutates the stored value using an exclusive barrier operation.
    ///
    /// - Warning: The mutation is synchronized only for the duration of this
    ///   closure. Do not escape, store, or mutate reference-type values obtained
    ///   from `value` outside the closure; doing so bypasses this wrapper's
    ///   synchronization and may cause data races.
    ///
    /// - Parameter block: A closure that receives the stored value for mutation.
    /// - Returns: The value after mutation.
    @discardableResult
    public func change(
        _ block: @escaping @Sendable (inout Value) throws -> Void
    ) async throws -> Value {
        try await withCheckedThrowingContinuation { continuation in
            queue.async(flags: .barrier) {
                do {
                    try block(&self.data)
                    continuation.resume(returning: self.data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Mutates the stored value using an exclusive barrier operation.
    ///
    /// - Warning: The mutation is synchronized only for the duration of this
    ///   closure. Do not escape, store, or mutate reference-type values obtained
    ///   from `value` outside the closure; doing so bypasses this wrapper's
    ///   synchronization and may cause data races.
    ///
    /// - Parameter block: A closure that receives the stored value for mutation.
    /// - Returns: The value after mutation.
    @discardableResult
    public func change(
        _ block: @escaping @Sendable (inout Value) -> Void
    ) async -> Value {
        await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                block(&self.data)
                continuation.resume(returning: self.data)
            }
        }
    }
}

