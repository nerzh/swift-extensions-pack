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
    private let queue = DispatchQueue(
        label: "SendableValue.queue",
        attributes: .concurrent
    )

    public init(_ val: Value) {
        self.data = val
    }

    public func read() async -> Value {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.data)
            }
        }
    }

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

