//
//  Limiter.swift
//  SwiftExtensionsPack
//
//  Created by Oleh Hudeichuk on 01.09.2025.
//

import Dispatch
import Foundation

public actor LimiterAsync {
    public enum Acquisition: Equatable, Sendable {
        case acquired
        /// Monotonic deadline shared by all callers waiting for this window to end.
        case retryAt(DispatchTime)
        /// The limiter is stopped, the capacity is zero, or the caller is cancelled.
        case unavailable
    }

    private let maxRequests: Int
    private let interval: TimeInterval
    private var windowEnd: DispatchTime = .now()
    private var currentCount = 0
    private var isStopped = false
    private var sleepers: [UUID: Task<Void, Error>] = [:]

    public init(maxRequests: Int, per interval: TimeInterval) {
        precondition(interval.isFinite && interval >= 0)
        self.maxRequests = maxRequests
        self.interval = interval
    }

    public func blockAllSlots(until deadline: DispatchTime) async {
        guard deadline > .now() else { return }
        currentCount = maxRequests
        windowEnd = max(windowEnd, deadline)
    }

    public func stop() async {
        isStopped = true
        for sleeper in sleepers.values {
            sleeper.cancel()
        }
    }

    @discardableResult
    public func run<T: Sendable>(_ operation: @Sendable (_ isCancelled: Bool) async throws -> T) async rethrows -> T {
        return try await operation(!(await acquire()))
    }

    @discardableResult
    public func run<T: Sendable>(_ operation: @Sendable () async throws -> T) async rethrows -> T {
        await acquire()
        return try await operation()
    }

    /// Takes one slot if available. A retry deadline does not reserve a slot.
    public func tryAcquire() -> Acquisition {
        guard !isStopped, !Task.isCancelled, maxRequests > 0 else { return .unavailable }

        let now = DispatchTime.now()
        if now >= windowEnd {
            windowEnd = now + interval
            currentCount = 0
        }
        guard currentCount < maxRequests else { return .retryAt(windowEnd) }

        currentCount += 1
        return .acquired
    }

    @discardableResult
    public func acquire() async -> Bool {
        while true {
            switch tryAcquire() {
            case .acquired:
                return true
            case .unavailable:
                return false
            case .retryAt(let deadline):
                let sleeper = Task {
                    let now = DispatchTime.now().uptimeNanoseconds
                    if deadline.uptimeNanoseconds > now {
                        try await Task.sleep(nanoseconds: deadline.uptimeNanoseconds - now)
                    }
                }
                let id = UUID()
                sleepers[id] = sleeper
                defer { sleepers[id] = nil }
                await withTaskCancellationHandler {
                    _ = await sleeper.result
                } onCancel: {
                    sleeper.cancel()
                }
            }
        }
    }
}
