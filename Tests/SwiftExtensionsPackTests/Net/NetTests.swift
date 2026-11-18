import Foundation
import SwiftExtensionsPack
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class NetTests: XCTestCase {
    private let baseURL = "https://example.test"

    func testQueryMergingPreservesExistingEscapesAndFragment() throws {
        let request = try makeRequest(
            url: baseURL + "/path%2Fpiece?token=a%2fb%2Bc%20d&literal=a+b&flag&empty=#section?ignored=1",
            queryParams: ["next": "x+y &=%#?/"]
        )

        XCTAssertEqual(
            request.url?.absoluteString,
            baseURL + "/path%2Fpiece?token=a%2fb%2Bc%20d&literal=a+b&flag&empty=&next=x%2By%20%26%3D%25%23%3F%2F#section?ignored=1"
        )
    }

    func testQueryMergingHandlesMissingEmptyAndTrailingSeparators() throws {
        let cases = [
            ("/path", "/path?page=2"),
            ("/path?", "/path?page=2"),
            ("/path#fragment", "/path?page=2#fragment"),
            ("/path?#fragment", "/path?page=2#fragment"),
            ("/path?old=1&", "/path?old=1&page=2"),
            ("/path?old=a?b", "/path?old=a?b&page=2")
        ]
        for (input, expected) in cases {
            let request = try makeRequest(url: baseURL + input, queryParams: ["page": 2])
            XCTAssertEqual(request.url?.absoluteString, baseURL + expected, input)
        }
    }

    func testDuplicateQueryNamesKeepExistingValuesBeforeNewValues() throws {
        let request = try makeRequest(
            url: baseURL + "/path?tag=one&tag=two#fragment", queryParams: ["tag": "three"]
        )

        XCTAssertEqual(request.url?.absoluteString, baseURL + "/path?tag=one&tag=two&tag=three#fragment")
    }

    func testEmptyQueryParametersDoNotAddQuestionMarksOrChangeExistingURL() throws {
        let inputs: [[String: Any]?] = [
            nil, [:], ["array": [String](), "object": [String: String]()]
        ]
        for params in inputs {
            for suffix in ["/path", "/path?#", "/path?old=%2f+z&flag#fragment"] {
                let request = try makeRequest(url: baseURL + suffix, queryParams: params)
                XCTAssertEqual(request.url?.absoluteString, baseURL + suffix)
            }
        }
    }

    func testQueryNamesCannotInjectExtraParametersOrFragments() throws {
        let name = "name&admin=true?#%+"
        let value = "a&b=c"
        let request = try makeRequest(queryParams: [name: value])
        let items = try queryItems(in: request)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, name)
        XCTAssertEqual(items.first?.value, value)
        XCTAssertEqual(request.url?.absoluteString, baseURL + "/resource?name%26admin%3Dtrue%3F%23%25%2B=a%26b%3Dc")
        XCTAssertNil(request.url?.fragment)
    }

    func testQueryEncodesUnicodeControlsAndLiteralPercentSequences() throws {
        let inputs = [
            ("ключ", "Привет 😀"),
            ("line\nbreak", "a\r\nb"),
            ("percent", "%2F"),
            ("", "value"),
            ("empty", "")
        ]
        for (name, value) in inputs {
            let request = try makeRequest(queryParams: [name: value])
            let items = try queryItems(in: request)
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items.first?.name, name)
            XCTAssertEqual(items.first?.value, value)
        }
        let percent = try makeRequest(queryParams: ["percent": "%2F"])
        XCTAssertEqual(percent.url?.query, "percent=%252F")
    }

    func testNestedQueryParametersPreserveRailsNamesAndArrayOrder() throws {
        let params: [String: Any] = [
            "user": ["name": "A & B", "roles": ["admin", "editor"]] as [String: Any],
            "items": [["id": 1], ["id": 2]]
        ]
        let request = try makeRequest(url: baseURL + "/resource?fixed=1", queryParams: params)
        let grouped = Dictionary(grouping: try queryItems(in: request), by: \.name)
            .mapValues { $0.map(\.value) }
        let expected: [String: [String?]] = [
            "fixed": ["1"], "user[name]": ["A & B"], "user[roles][]": ["admin", "editor"],
            "items[0][id]": ["1"], "items[1][id]": ["2"]
        ]

        XCTAssertEqual(grouped, expected)
    }

    func testArrayQueryAppendsToExistingArrayValues() throws {
        let request = try makeRequest(
            url: baseURL + "/resource?tags%5B%5D=base", queryParams: ["tags": ["first", "second"]]
        )
        let items = try queryItems(in: request)

        XCTAssertEqual(items.map(\.name), ["tags[]", "tags[]", "tags[]"])
        XCTAssertEqual(items.map(\.value), ["base", "first", "second"])
    }

    func testQueryOnlyRequestsNeverCreateBodyForAnyMethod() throws {
        for method in ["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE"] {
            let request = try makeRequest(method: method, queryParams: ["page": 2])
            XCTAssertEqual(request.httpMethod, method)
            XCTAssertEqual(request.url?.absoluteString, baseURL + "/resource?page=2")
            XCTAssertNil(request.httpBody, method)
            XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"), method)
        }
    }

    func testExplicitGETBodyIsPassedToTheSessionWithoutBeingDiscarded() throws {
        let bytes = Data([0, 255, 128])
        let request = try makeRequest(method: "GET", body: .raw(data: bytes))

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.httpBody, bytes)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/octet-stream")
    }

    func testSensitiveFormFieldsStayInBodyAndQueryStaysInURL() throws {
        let request = try makeRequest(
            method: "POST", queryParams: ["page": 2], body: .form(["password": "audit-secret"])
        )

        XCTAssertEqual(request.url?.absoluteString, baseURL + "/resource?page=2")
        XCTAssertEqual(request.httpBody, Data("password=audit-secret".utf8))
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
    }

    func testAllBodyFormatsSetContentTypeWithoutMovingQueryParameters() throws {
        let bodies: [(NetBody, String)] = [
            (.raw(data: Data([0, 255])), "application/octet-stream"),
            (.json(["secret": "value"]), "application/json"),
            (.form(["secret": "value"]), "application/x-www-form-urlencoded"),
            (.multipart([.field(name: "secret", value: "value")]), "multipart/form-data; boundary=")
        ]
        for (body, contentType) in bodies {
            let request = try makeRequest(method: "POST", queryParams: ["page": 2], body: body)
            XCTAssertEqual(request.url?.absoluteString, baseURL + "/resource?page=2")
            XCTAssertNotNil(request.httpBody)
            XCTAssertTrue(try XCTUnwrap(request.value(forHTTPHeaderField: "Content-Type")).hasPrefix(contentType))
        }
    }

    func testEmptyRawBodyIsDifferentFromMissingBody() throws {
        let empty = try makeRequest(method: "POST", body: .raw(data: Data()))
        let absent = try makeRequest(method: "POST")

        XCTAssertEqual(empty.httpBody, Data())
        XCTAssertEqual(empty.value(forHTTPHeaderField: "Content-Type"), "application/octet-stream")
        XCTAssertNil(absent.httpBody)
        XCTAssertNil(absent.value(forHTTPHeaderField: "Content-Type"))
    }

    func testMultipartPreservesAcceptAndCustomHeaders() throws {
        let request = try makeRequest(
            method: "POST", headers: ["Accept": "application/pdf", "X-Request-ID": "kept"],
            body: .multipart([.field(name: "caption", value: "Summer")])
        )

        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/pdf")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Request-ID"), "kept")
        let contentType = try XCTUnwrap(request.value(forHTTPHeaderField: "Content-Type"))
        let boundary = String(contentType.dropFirst("multipart/form-data; boundary=".count))
        let bytes = try XCTUnwrap(request.httpBody)
        XCTAssertFalse(boundary.isEmpty)
        XCTAssertTrue(bytes.starts(with: Data("--\(boundary)\r\n".utf8)))
        XCTAssertTrue(bytes.suffix(boundary.utf8.count + 4).elementsEqual(Data("--\(boundary)--".utf8)))
    }

    func testMatchingContentTypeIsAcceptedWithCaseInsensitiveHeaderName() throws {
        let request = try makeRequest(
            method: "POST", headers: ["cOnTeNt-TyPe": "application/json"], body: .json(["ok": true])
        )

        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(try JSONDecoder().decode([String: Bool].self, from: XCTUnwrap(request.httpBody)), ["ok": true])
    }

    func testConflictingContentTypeFailsBeforeCreatingOrResumingTask() {
        let bodies: [(NetBody, String)] = [
            (.raw(data: Data()), "application/octet-stream"),
            (.json(["ok": true]), "application/json"),
            (.form(["field": "value"]), "application/x-www-form-urlencoded"),
            (.multipart([.field(name: "field", value: "value")]), "multipart/form-data; boundary=")
        ]
        for (body, expectedPrefix) in bodies {
            let session = NetTestSession()
            defer { session.invalidateAndCancel() }
            let handlerCount = SafeValue(0)

            Net.sendRequest(
                url: baseURL, method: "POST", headers: ["content-type": "application/invalid"],
                body: body, session: session
            ) { data, response, error in
                handlerCount.change { $0 += 1 }
                XCTAssertNil(data)
                XCTAssertNil(response)
                guard let error, case Net.NetErrors.ConflictingContentType(let expected, let actual) = error else {
                    return XCTFail("Unexpected error: \(String(describing: error))")
                }
                XCTAssertTrue(expected.hasPrefix(expectedPrefix))
                XCTAssertEqual(actual, "application/invalid")
            }
            XCTAssertTrue(session.calls.value.isEmpty)
            XCTAssertEqual(handlerCount.value, 1)
        }
    }

    func testInvalidURLFailsBeforeCreatingTask() {
        let session = NetTestSession()
        defer { session.invalidateAndCancel() }
        let handlerCount = SafeValue(0)

        Net.sendRequest(
            url: "http://[invalid", method: "GET", queryParams: ["page": 2], session: session
        ) { data, response, error in
            handlerCount.change { $0 += 1 }
            XCTAssertNil(data)
            XCTAssertNil(response)
            guard let error, case Net.NetErrors.NotValidParams = error else {
                return XCTFail("Unexpected error: \(String(describing: error))")
            }
        }
        XCTAssertTrue(session.calls.value.isEmpty)
        XCTAssertEqual(handlerCount.value, 1)
    }

    func testCallbackReceivesJSONEncodingErrorBeforeCreatingTask() {
        let session = NetTestSession()
        defer { session.invalidateAndCancel() }
        let handlerCount = SafeValue(0)

        Net.sendRequest(
            url: baseURL, method: "POST", body: .json(FailingNetPayload()), session: session
        ) { data, response, error in
            handlerCount.change { $0 += 1 }
            XCTAssertNil(data)
            XCTAssertNil(response)
            XCTAssertEqual(error as? NetTestError, .encodingFailed)
        }
        XCTAssertTrue(session.calls.value.isEmpty)
        XCTAssertEqual(handlerCount.value, 1)
    }

    func testCallbackReceivesResponseAndResumesTaskOnce() throws {
        let url = try XCTUnwrap(URL(string: baseURL + "/resource"))
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil, headerFields: nil))
        let data = Data([0, 255, 42])
        let session = NetTestSession(reply: NetTestReply(data: data, response: response))
        defer { session.invalidateAndCancel() }
        let handlerCount = SafeValue(0)

        Net.sendRequest(
            url: url.absoluteString, method: "POST", body: .raw("request"), session: session
        ) { receivedData, receivedResponse, error in
            handlerCount.change { $0 += 1 }
            XCTAssertEqual(receivedData, data)
            XCTAssertEqual((receivedResponse as? HTTPURLResponse)?.statusCode, 201)
            XCTAssertNil(error)
        }

        XCTAssertEqual(handlerCount.value, 1)
        XCTAssertEqual(session.calls.value.count, 1)
        XCTAssertEqual(session.calls.value.first?.task.resumeCount.value, 1)
    }

    func testCallbackReceivesTransportError() {
        let session = NetTestSession(reply: NetTestReply(error: URLError(.timedOut)))
        defer { session.invalidateAndCancel() }
        let handlerCount = SafeValue(0)

        Net.sendRequest(
            url: baseURL, method: "GET", session: session
        ) { data, response, error in
            handlerCount.change { $0 += 1 }
            XCTAssertNil(data)
            XCTAssertNil(response)
            XCTAssertEqual((error as? URLError)?.code, .timedOut)
        }

        XCTAssertEqual(handlerCount.value, 1)
    }

    @MainActor
    func testAsyncAPIReturnsResponseData() async throws {
        guard #available(macOS 12, *) else { throw XCTSkip("Async Net requires macOS 12") }
        let url = try XCTUnwrap(URL(string: baseURL))
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil, headerFields: nil))
        let data = Data([0, 255, 42])
        let session = NetTestSession(reply: NetTestReply(data: data, response: response))
        defer { session.invalidateAndCancel() }

        let result = try await Net.sendRequest(
            url: baseURL, method: "POST", queryParams: ["page": 2], body: .json(["ok": true]), session: session
        )

        XCTAssertEqual(result.data, data)
        XCTAssertEqual((result.response as? HTTPURLResponse)?.statusCode, 201)
        XCTAssertEqual(session.calls.value.count, 1)
        XCTAssertEqual(session.calls.value.first?.request.url?.absoluteString, baseURL + "?page=2")
        XCTAssertEqual(session.calls.value.first?.request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    @MainActor
    func testAsyncAPIPropagatesTransportError() async throws {
        guard #available(macOS 12, *) else { throw XCTSkip("Async Net requires macOS 12") }
        let session = NetTestSession(reply: NetTestReply(error: URLError(.timedOut)))
        defer { session.invalidateAndCancel() }

        do {
            _ = try await Net.sendRequest(url: baseURL, method: "GET", session: session)
            XCTFail("Expected a transport error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .timedOut)
        }
    }

    @MainActor
    func testAsyncAPIPropagatesEncodingAndHeaderErrorsWithoutCreatingTask() async throws {
        guard #available(macOS 12, *) else { throw XCTSkip("Async Net requires macOS 12") }
        let session = NetTestSession()
        defer { session.invalidateAndCancel() }

        do {
            _ = try await Net.sendRequest(
                url: baseURL, method: "POST", body: .json(FailingNetPayload()), session: session
            )
            XCTFail("Expected an encoding error")
        } catch {
            XCTAssertEqual(error as? NetTestError, .encodingFailed)
        }
        do {
            _ = try await Net.sendRequest(
                url: baseURL, method: "POST", headers: ["Content-Type": "text/plain"],
                body: .json(["ok": true]), session: session
            )
            XCTFail("Expected a Content-Type conflict")
        } catch Net.NetErrors.ConflictingContentType(let expected, let actual) {
            XCTAssertEqual(expected, "application/json")
            XCTAssertEqual(actual, "text/plain")
        }
        XCTAssertTrue(session.calls.value.isEmpty)
    }

    @MainActor
    func testAsyncAPIThrowsWhenSessionReturnsNoResult() async throws {
        guard #available(macOS 12, *) else { throw XCTSkip("Async Net requires macOS 12") }
        let session = NetTestSession(reply: NetTestReply())
        defer { session.invalidateAndCancel() }

        do {
            _ = try await Net.sendRequest(url: baseURL, method: "GET", session: session)
            XCTFail("Expected a missing-result error")
        } catch {
            XCTAssertTrue(error is SEPCommonError)
        }
    }

    func testPublicQueryHelpersEscapeKeysAndOmitEmptyQuery() {
        XCTAssertEqual(Net.toQueryParams(["name&admin": "x+y"]), "name%26admin=x%2By")
        XCTAssertEqual(Net.paramsString(["name&admin": "x+y"]), "name%26admin=x%2By")
        XCTAssertEqual(Net.urlEncode("é😀"), "%C3%A9%F0%9F%98%80")
        XCTAssertEqual(Net.urlEncode("AZaz09.-_"), "AZaz09.-_")
        XCTAssertEqual(Net.makeQueryParamsString(["page": 2]), "?page=2")
        XCTAssertEqual(Net.makeQueryParamsString(nil), "")
        XCTAssertEqual(Net.makeQueryParamsString([:]), "")
        XCTAssertEqual(Net.makeQueryParamsString(["array": [String](), "object": [String: String]()]), "")
    }

    private func makeRequest(
        url: String? = nil,
        method: String = "GET",
        headers: [String: String]? = nil,
        queryParams: [String: Any]? = nil,
        body: NetBody? = nil
    ) throws -> URLRequest {
        let session = NetTestSession()
        defer { session.invalidateAndCancel() }
        let requestError = SafeValue<Error?>(nil)
        Net.sendRequest(
            url: url ?? baseURL + "/resource", method: method, headers: headers,
            queryParams: queryParams, body: body, session: session
        ) { _, _, error in
            requestError.change { $0 = error }
        }
        if let error = requestError.value {
            throw error
        }
        let calls = session.calls.value
        XCTAssertEqual(calls.count, 1)
        let call = try XCTUnwrap(calls.first)
        XCTAssertEqual(call.task.resumeCount.value, 1)
        return call.request
    }

    private func queryItems(in request: URLRequest) throws -> [URLQueryItem] {
        let url = try XCTUnwrap(request.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        return components.queryItems ?? []
    }
}
