import Foundation
import SwiftExtensionsPack
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class NetCancellationTests: XCTestCase {
    private let baseURL = "https://example.test/resource"

    @MainActor
    func testAlreadyCancelledTaskDoesNotCreateNetworkTask() async throws {
        guard #available(macOS 12, *) else { throw XCTSkip("Async Net requires macOS 12") }
        let session = NetTestSession(reply: try successReply())
        let completed = expectation(description: "Request completed")
        let request = startRequest(session: session, completed: completed, cancelBeforeStart: true)

        guard await waitFor([completed]) else { request.cancel(); return }
        assertCancellation(await request.value)
        XCTAssertTrue(session.calls.value.isEmpty)
    }

    @MainActor
    func testCancellationDuringEncodingDoesNotCreateNetworkTask() async throws {
        guard #available(macOS 12, *) else { throw XCTSkip("Async Net requires macOS 12") }
        let session = NetTestSession(reply: try successReply())
        let completed = expectation(description: "Request completed")
        let request = startRequest(session: session, completed: completed, body: { .json(CancellingPayload()) })

        guard await waitFor([completed]) else { request.cancel(); return }
        assertCancellation(await request.value)
        XCTAssertTrue(session.calls.value.isEmpty)
    }

    @MainActor
    func testCancellationDuringTaskCreationCancelsWithoutResuming() async throws {
        guard #available(macOS 12, *) else { throw XCTSkip("Async Net requires macOS 12") }
        let session = NetTestSession(reply: try successReply(), onCreate: {
            withUnsafeCurrentTask { $0?.cancel() }
        })
        let completed = expectation(description: "Request completed")
        let request = startRequest(session: session, completed: completed)

        guard await waitFor([completed]) else { request.cancel(); return }
        assertCancellation(await request.value)
        XCTAssertEqual(session.calls.value.count, 1)
        let task = try XCTUnwrap(session.calls.value.first?.task)
        XCTAssertEqual(task.resumeCount.value, 0)
        XCTAssertEqual(task.cancelCount.value, 1)
    }

    @MainActor
    func testCancellationWhileWaitingFinishesWithoutTransportCallback() async throws {
        guard #available(macOS 12, *) else { throw XCTSkip("Async Net requires macOS 12") }
        let started = expectation(description: "Request started")
        let completed = expectation(description: "Request completed")
        let session = NetTestSession(onResume: { started.fulfill() })
        let request = startRequest(session: session, completed: completed)

        guard await waitFor([started]) else { request.cancel(); return }
        let task = try XCTUnwrap(session.calls.value.first?.task)
        request.cancel()
        guard await waitFor([completed]) else {
            task.complete(with: NetTestReply(error: URLError(.cancelled)))
            return
        }

        assertCancellation(await request.value)
        XCTAssertEqual(task.resumeCount.value, 1)
        XCTAssertEqual(task.cancelCount.value, 1)

        // Late transport callbacks and repeated cancellation must not resume the continuation again.
        task.complete(with: try successReply())
        task.complete(with: NetTestReply(error: URLError(.cancelled)))
        request.cancel()
        XCTAssertEqual(task.cancelCount.value, 1)
    }

    @MainActor
    func testCancellationToleratesSynchronousTransportCallback() async throws {
        guard #available(macOS 12, *) else { throw XCTSkip("Async Net requires macOS 12") }
        let started = expectation(description: "Request started")
        let completed = expectation(description: "Request completed")
        let session = NetTestSession(
            replyOnCancel: NetTestReply(error: URLError(.cancelled)),
            onResume: { started.fulfill() }
        )
        let request = startRequest(session: session, completed: completed)

        guard await waitFor([started]) else { request.cancel(); return }
        request.cancel()
        guard await waitFor([completed]) else { return }

        assertCancellation(await request.value)
        XCTAssertEqual(session.calls.value.first?.task.cancelCount.value, 1)
    }

    @MainActor
    func testResponseBeforeCancellationIsPreserved() async throws {
        guard #available(macOS 12, *) else { throw XCTSkip("Async Net requires macOS 12") }
        let started = expectation(description: "Request started")
        let completed = expectation(description: "Request completed")
        let session = NetTestSession(onResume: { started.fulfill() })
        let request = startRequest(session: session, completed: completed)

        guard await waitFor([started]) else { request.cancel(); return }
        let task = try XCTUnwrap(session.calls.value.first?.task)
        let reply = try successReply()
        task.complete(with: reply)
        request.cancel()
        guard await waitFor([completed]) else { return }

        let result = await request.value
        XCTAssertEqual(try result.get(), reply.data)
        XCTAssertEqual(task.cancelCount.value, 0)
    }

    @MainActor
    func testConcurrentResponseAndCancellationFinishOnlyOnce() async throws {
        guard #available(macOS 12, *) else { throw XCTSkip("Async Net requires macOS 12") }
        let reply = try successReply()
        for _ in 0..<10 {
            let started = expectation(description: "Request started")
            let completed = expectation(description: "Request completed")
            let raced = expectation(description: "Both racing operations returned")
            raced.expectedFulfillmentCount = 2
            let session = NetTestSession(onResume: { started.fulfill() })
            let request = startRequest(session: session, completed: completed)

            guard await waitFor([started]) else { request.cancel(); return }
            let task = try XCTUnwrap(session.calls.value.first?.task)
            DispatchQueue.global().async {
                request.cancel()
                raced.fulfill()
            }
            DispatchQueue.global().async {
                task.complete(with: reply)
                raced.fulfill()
            }
            guard await waitFor([raced, completed]) else { return }

            switch await request.value {
            case .success(let data):
                XCTAssertEqual(data, reply.data)
                XCTAssertEqual(task.cancelCount.value, 0)
            case .failure(let error):
                XCTAssertTrue(error is CancellationError)
                XCTAssertEqual(task.cancelCount.value, 1)
            }
        }
    }

    @MainActor
    func testCancellingOneRequestDoesNotCancelAnotherInTheSameSession() async throws {
        guard #available(macOS 12, *) else { throw XCTSkip("Async Net requires macOS 12") }
        let started = expectation(description: "Both requests started")
        started.expectedFulfillmentCount = 2
        let firstCompleted = expectation(description: "Cancelled request completed")
        let secondCompleted = expectation(description: "Other request completed")
        let session = NetTestSession(onResume: { started.fulfill() })
        let first = startRequest(session: session, completed: firstCompleted)
        let second = startRequest(session: session, completed: secondCompleted)

        guard await waitFor([started]) else { first.cancel(); second.cancel(); return }
        first.cancel()
        let tasks = session.calls.value.map(\.task)
        XCTAssertEqual(tasks.map { $0.cancelCount.value }.sorted(), [0, 1])
        let reply = try successReply()
        for task in tasks {
            task.complete(with: reply)
        }
        guard await waitFor([firstCompleted, secondCompleted]) else { second.cancel(); return }

        assertCancellation(await first.value)
        let result = await second.value
        XCTAssertEqual(try result.get(), reply.data)
    }

    @MainActor
    func testTransportCancellationErrorIsPreservedWithoutTaskCancellation() async throws {
        guard #available(macOS 12, *) else { throw XCTSkip("Async Net requires macOS 12") }
        let session = NetTestSession(reply: NetTestReply(error: URLError(.cancelled)))
        let completed = expectation(description: "Request completed")
        let request = startRequest(session: session, completed: completed)

        guard await waitFor([completed]) else { request.cancel(); return }
        guard case .failure(let error) = await request.value else {
            return XCTFail("Expected a transport cancellation error")
        }
        XCTAssertEqual((error as? URLError)?.code, .cancelled)
        XCTAssertEqual(session.calls.value.first?.task.cancelCount.value, 0)
    }

    @available(macOS 12, *)
    @MainActor
    private func startRequest(
        session: NetTestSession,
        completed: XCTestExpectation,
        body: @escaping @Sendable () -> NetBody? = { nil },
        cancelBeforeStart: Bool = false
    ) -> Task<Result<Data, any Error>, Never> {
        let url = baseURL
        return Task {
            defer { completed.fulfill() }
            if cancelBeforeStart {
                withUnsafeCurrentTask { $0?.cancel() }
            }
            do {
                let result = try await Net.sendRequest(url: url, method: "POST", body: body(), session: session)
                return .success(result.data)
            } catch {
                return .failure(error)
            }
        }
    }

    @available(macOS 12, *)
    @MainActor
    private func waitFor(_ expectations: [XCTestExpectation], file: StaticString = #filePath, line: UInt = #line) async -> Bool {
        let result = await XCTWaiter.fulfillment(of: expectations, timeout: 2)
        XCTAssertEqual(result, .completed, file: file, line: line)
        return result == .completed
    }

    private func successReply() throws -> NetTestReply {
        let url = try XCTUnwrap(URL(string: baseURL))
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        return NetTestReply(data: Data([0, 255, 42]), response: response)
    }

    private func assertCancellation(_ result: Result<Data, any Error>, file: StaticString = #filePath, line: UInt = #line) {
        guard case .failure(let error) = result else {
            return XCTFail("Expected CancellationError", file: file, line: line)
        }
        XCTAssertTrue(error is CancellationError, "Unexpected error: \(error)", file: file, line: line)
    }

    private struct CancellingPayload: Encodable {
        func encode(to encoder: any Encoder) throws {
            withUnsafeCurrentTask { $0?.cancel() }
            var container = encoder.singleValueContainer()
            try container.encode("cancel during encoding")
        }
    }
}
