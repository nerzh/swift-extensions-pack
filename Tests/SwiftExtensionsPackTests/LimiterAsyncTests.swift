import Dispatch
import XCTest
@testable import SwiftExtensionsPack

final class LimiterAsyncTests: XCTestCase, @unchecked Sendable {
    func testConcurrentCallersSeeOneDeadlineWhenTheWindowIsFull() async {
        let limiter = LimiterAsync(maxRequests: 5, per: 60)
        let attempts = await withTaskGroup(of: LimiterAsync.Acquisition.self) { group in
            for _ in 0..<40 {
                group.addTask { await limiter.tryAcquire() }
            }
            var attempts: [LimiterAsync.Acquisition] = []
            for await attempt in group { attempts.append(attempt) }
            return attempts
        }

        XCTAssertEqual(attempts.filter { $0 == .acquired }.count, 5)
        let deadlines = attempts.compactMap { attempt -> DispatchTime? in
            guard case .retryAt(let deadline) = attempt else { return nil }
            return deadline
        }
        XCTAssertEqual(deadlines.count, 35)
        guard let first = deadlines.first else { return XCTFail("Expected a deadline") }
        XCTAssertGreaterThan(first, .now())
        XCTAssertTrue(deadlines.allSatisfy { $0 == first })
    }

    func testNextCallerGetsThroughAfterTwoFullBatches() async {
        let limiter = LimiterAsync(maxRequests: 5, per: 0.05)
        let finished = expectation(description: "Third window opened")
        let worker = Task {
            for _ in 0..<5 {
                let acquired = await limiter.acquire()
                XCTAssertTrue(acquired)
            }
            guard case .retryAt(let secondWindow) = await limiter.tryAcquire() else {
                return XCTFail("Expected the first window to be full")
            }
            await withTaskGroup(of: Bool.self) { group in
                for _ in 0..<5 {
                    group.addTask { await limiter.acquire() }
                }
                for await acquired in group { XCTAssertTrue(acquired) }
            }
            XCTAssertGreaterThanOrEqual(DispatchTime.now(), secondWindow)
            let acquired = await limiter.acquire()
            XCTAssertTrue(acquired)
            finished.fulfill()
        }
        await fulfillment(of: [finished], timeout: 3)
        worker.cancel()
    }

    func testCancellationAndStopReleaseWaitersDuringALongWindow() async {
        let limiter = LimiterAsync(maxRequests: 1, per: 60)
        let first = await limiter.acquire()
        XCTAssertTrue(first)

        let cancelled = expectation(description: "Cancelled caller finished")
        let stopped = expectation(description: "Stopped caller finished")
        let cancelledTask = Task {
            let acquired = await limiter.acquire()
            XCTAssertFalse(acquired)
            cancelled.fulfill()
        }
        let stoppedTask = Task {
            await limiter.run { isCancelled in
                XCTAssertTrue(isCancelled)
                stopped.fulfill()
            }
        }
        try? await Task.sleep(nanoseconds: 20_000_000)
        cancelledTask.cancel()
        await fulfillment(of: [cancelled], timeout: 1)
        guard case .retryAt = await limiter.tryAcquire() else {
            stoppedTask.cancel()
            return XCTFail("Cancelling a caller must preserve the active window")
        }
        await limiter.stop()
        await fulfillment(of: [stopped], timeout: 1)
        let result = await limiter.tryAcquire()
        XCTAssertEqual(result, .unavailable)
        stoppedTask.cancel()
    }
}
