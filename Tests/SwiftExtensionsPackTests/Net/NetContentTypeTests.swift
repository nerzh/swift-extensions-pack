import Foundation
import XCTest
@testable import SwiftExtensionsPack

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class NetContentTypeTests: XCTestCase {
    func testEquivalentMediaTypesAreAccepted() throws {
        let pairs = [
            ("application/json", "Application/JSON"),
            ("text/plain; charset=utf-8", "Text/Plain ; CHARSET=\"UTF-8\""),
            ("application/example; version=2; profile=\"a;b\"", "APPLICATION/EXAMPLE; PROFILE=\"a;b\"; VERSION=\"2\""),
            ("multipart/form-data; boundary=AbC", "Multipart/Form-Data; BOUNDARY=\"AbC\""),
            ("text/plain", " \tTEXT/PLAIN\t; ;\t"),
            (#"application/example; profile="a\"b\\c;d""#, #"Application/Example; PROFILE="a\"b\\c;d""#),
            ("application/example; version=two", #"application/example; version="t\wo""#),
            ("application/example; empty=\"\"", "Application/Example; EMPTY=\"\"")
        ]
        for (expected, actual) in pairs {
            XCTAssertNoThrow(try NetContentType.validate(expected))
            XCTAssertNoThrow(try NetContentType.validate(actual))
            XCTAssertEqual(try NetContentType(expected), try NetContentType(actual))
            let request = try makeRequest(expected: expected, actual: actual)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), expected)
            XCTAssertEqual(request.httpBody, Data([0, 255, 42]))
        }
    }

    func testDifferentBoundaryAndUnknownParameterValuesRemainConflicts() {
        let pairs = [
            ("multipart/form-data; boundary=AbC", "multipart/form-data; boundary=abc"),
            ("application/example; profile=Name", "application/example; profile=name"),
            ("text/plain; charset=utf-8", "text/plain; charset=iso-8859-1"),
            ("text/plain; charset=utf-8", "text/plain"),
            ("text/plain", "text/plain; charset=utf-8"),
            ("application/json", "application/problem+json")
        ]
        for (expected, actual) in pairs {
            XCTAssertThrowsError(try makeRequest(expected: expected, actual: actual)) { error in
                guard case Net.NetErrors.ConflictingContentType = error else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }
        }
    }

    func testRawBodyRejectsInvalidCustomMIMEType() {
        let invalid = [
            "", "json", "text/", "/plain", "text /plain", "text/ plain", "text/plain, text/html",
            "*/*", "text/*", "text/plain\r\nX-Injected: yes", "text/plain\nX: value", "text/plain\u{0}",
            "text/plain; charset", "text/plain; charset=", "text/plain; charset =utf-8",
            "text/plain; charset= utf-8", "text/plain; charset=\"unterminated",
            "text/plain; charset=\"trailing\\", "text/plain; charset=\"utf-8\"extra",
            "text/plain; charset=utf-8; CHARSET=utf-8", "text/plain; charset=utf-8; CHARSET=ascii",
            "text/plain; profile=\"line\r\nbreak\"", "text/plain; profile=\"\u{7f}\"",
            "text/plain; profile=\"escaped\\\nnewline\""
        ]
        for value in invalid {
            XCTAssertThrowsError(try NetContentType.validate(value), value)
            XCTAssertThrowsError(try NetContentType(value), value)
            XCTAssertThrowsError(try NetBody.raw(data: Data([42]), contentType: .custom(value)).encoded(), value) { error in
                guard case Net.NetErrors.InvalidContentType(let actual) = error else {
                    return XCTFail("Unexpected error: \(error)")
                }
                XCTAssertEqual(actual, value)
            }
        }
    }

    func testInvalidManualHeadersFailBeforeCreatingTaskEvenWithoutBody() {
        for value in ["text/plain\r\nX: yes", "text/plain\n", "text/plain; charset=\"utf-8", "text"] {
            let session = NetTestSession()
            let handlerCount = SafeValue(0)
            Net.sendRequest(
                url: "https://example.test", method: "POST", headers: ["cOnTeNt-TyPe": value], session: session
            ) { data, response, error in
                handlerCount.change { $0 += 1 }
                XCTAssertNil(data)
                XCTAssertNil(response)
                guard let error, case Net.NetErrors.InvalidContentType(let actual) = error else {
                    return XCTFail("Unexpected error: \(String(describing: error))")
                }
                XCTAssertEqual(actual, value)
            }
            XCTAssertTrue(session.calls.value.isEmpty)
            XCTAssertEqual(handlerCount.value, 1)
        }
    }

    func testDuplicateContentTypeHeaderNamesAreRejected() {
        let session = NetTestSession()
        let handlerCount = SafeValue(0)
        Net.sendRequest(
            url: "https://example.test", method: "POST",
            headers: ["Content-Type": "application/json", "content-type": "text/plain"],
            body: .json(["value": 1]), session: session
        ) { data, response, error in
            handlerCount.change { $0 += 1 }
            XCTAssertNil(data)
            XCTAssertNil(response)
            guard let error, case Net.NetErrors.InvalidContentType = error else {
                return XCTFail("Unexpected error: \(String(describing: error))")
            }
        }
        XCTAssertTrue(session.calls.value.isEmpty)
        XCTAssertEqual(handlerCount.value, 1)
    }

    func testMultipartHeaderCannotReplaceAutomaticallyGeneratedBoundary() {
        let session = NetTestSession()
        let actual = "multipart/form-data; boundary=incorrect"
        let handlerCount = SafeValue(0)
        Net.sendRequest(
            url: "https://example.test", method: "POST", headers: ["Content-Type": actual],
            body: .multipart([.field(name: "field", value: "value")]), session: session
        ) { data, response, error in
            handlerCount.change { $0 += 1 }
            XCTAssertNil(data)
            XCTAssertNil(response)
            guard let error, case Net.NetErrors.ConflictingContentType(let expected, let received) = error else {
                return XCTFail("Unexpected error: \(String(describing: error))")
            }
            XCTAssertTrue(expected.hasPrefix("multipart/form-data; boundary=Boundary-"))
            XCTAssertEqual(received, actual)
        }
        XCTAssertTrue(session.calls.value.isEmpty)
        XCTAssertEqual(handlerCount.value, 1)
    }

    func testInvalidMultipartMIMETypeFailsBeforeCreatingTask() {
        let session = NetTestSession()
        let handlerCount = SafeValue(0)
        let mime = "image/png\r\nX-Injected: yes"
        let file = NetSessionFile(data: Data([42]), fileName: "file.png", mimeType: .custom(mime))
        Net.sendRequest(
            url: "https://example.test", method: "POST", body: .multipart([.file(name: "file", file: file)]),
            session: session
        ) { data, response, error in
            handlerCount.change { $0 += 1 }
            XCTAssertNil(data)
            XCTAssertNil(response)
            guard let error, case Net.NetErrors.InvalidContentType(let actual) = error else {
                return XCTFail("Unexpected error: \(String(describing: error))")
            }
            XCTAssertEqual(actual, mime)
        }
        XCTAssertTrue(session.calls.value.isEmpty)
        XCTAssertEqual(handlerCount.value, 1)
    }

    private func makeRequest(expected: String, actual: String) throws -> URLRequest {
        let session = NetTestSession()
        let requestError = SafeValue<Error?>(nil)
        Net.sendRequest(
            url: "https://example.test", method: "POST", headers: ["Content-Type": actual],
            body: .raw(data: Data([0, 255, 42]), contentType: .custom(expected)), session: session
        ) { _, _, error in
            requestError.change { $0 = error }
        }
        if let error = requestError.value {
            throw error
        }
        return try XCTUnwrap(session.calls.value.first?.request)
    }
}
