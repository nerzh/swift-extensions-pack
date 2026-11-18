//
//  HTTP.swift
//  swift-extensions-pack
//
//  Created by Oleh Hudeichuk on 2/6/19.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public protocol NetSessionFilePrtcl {

    var mimeType: NetMIMEType { get set }
    var data: Data { get set }
    var fileName: String { get set }
}

// MARK: Session File
public struct NetSessionFile: NetSessionFilePrtcl {

    public var data: Data
    public var fileName: String
    public var mimeType: NetMIMEType

    public init(data: Data, fileName: String, mimeType: NetMIMEType = .octetStream) {
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }
}

// MARK: Extension NSMutableData
extension NSMutableData {

    func appendString(_ string: String) {
        guard
            let data = string.data(
                using: String.Encoding.utf8,
                allowLossyConversion: false
            )
        else {
            fatalError("Can Not Convert String: \(string) to Data")
        }
        append(data)
    }
}

// MARK: Multipart
public class NetMultipartData {
    public var body: NSMutableData = NSMutableData()
    private var _boundary: String = ""
    private var boundaryPrefix: String = ""
    private var finishBoundary: String = ""
    public var boundary: String {
        set {
            _boundary = newValue
            boundaryPrefix = "--\(newValue)\r\n"
            finishBoundary = "--\(self.boundary)--"
        }
        get { return _boundary }
    }

    public init() {
        boundary = "Boundary-\(UUID().uuidString)"
    }

    public init(boundary: String) {
        self.boundary = boundary
    }

    public func append(_ name: String, _ value: Any) {
        body.appendString(boundaryPrefix)
        body.appendString(
            "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n"
        )
        body.appendString("\(value)\r\n")
    }

    public func appendFile(
        _ name: String,
        _ data: Data,
        _ fileName: String,
        mimeType: NetMIMEType = .octetStream
    ) {
        body.appendString(boundaryPrefix)
        body.appendString(
            "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n"
        )
        body.appendString("Content-Type: \(mimeType.rawValue)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
    }

    public func finalizeBodyAndGetData() -> NSMutableData {
        finalizeBody()
        return body
    }

    private func finalizeBody() {
        body.appendString(finishBoundary)
    }

    public func toRailsMultipartData(_ anyObject: Any) -> NSMutableData {
        func checkValue(_ parentName: String, _ anyObject: Any) {
            if let array = anyObject as? [Any] {
                for (index, element) in array.enumerated() {
                    var newNodeName: String = .init()
                    if isNumeric(element) || element is String {
                        newNodeName = "\(parentName)[]"
                    } else {
                        newNodeName = "\(parentName)[\(index)]"
                    }
                    checkValue(newNodeName, element)
                }
            } else if let dictionary = anyObject as? [String: Any] {
                for key in dictionary.keys {
                    let newNodeName =
                        parentName.count == 0
                        ? "\(key)" : "\(parentName)[\(key)]"
                    checkValue(newNodeName, dictionary[key]!)
                }
            } else {
                if let file = anyObject as? NetSessionFilePrtcl {
                    appendFile(
                        parentName,
                        file.data,
                        file.fileName,
                        mimeType: file.mimeType
                    )
                } else {
                    append(parentName, anyObject)
                }
            }
        }

        checkValue("", anyObject as AnyObject)
        return finalizeBodyAndGetData()
    }
}

// MARK: Extension Dictionary to Multipart (Recursive)
extension Dictionary {

    func toRailsMultipartData() -> NSMutableData {
        return NetMultipartData().toRailsMultipartData(self)
    }

    //    MARK: Ruby On Rails
    func toRailsQueryParams() -> String {
        return Net.toRailsQueryParams(self)
    }
}

//  MARK: Net
public final class Net {
    private static let sessionConfiguration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        //        config.timeoutIntervalForRequest  = 1000
        //        config.timeoutIntervalForResource = 0
        return config
    }()

    public static let sharedSession = URLSession(
        configuration: sessionConfiguration
    )

    public enum NetErrors: Error {
        case NotValidParams
        case SomeError
        case BadData
        case ConflictingContentType(expected: String, actual: String)
    }

    public static func sendRequest(
        url: String,
        method: String,
        headers: [String: String]? = nil,
        queryParams: [String: Any]? = nil,
        body: NetBody? = nil,
        session: URLSession? = nil,
        beforeResume: (() -> Void)? = {},
        afterResume: (() -> Void)? = {},
        _ handler: @escaping @Sendable (Data?, URLResponse?, Error?) throws ->
            Void = { _, _, _ in }
    ) throws {
        let request = try makeRequest(
            url: url,
            method: method,
            headers: headers,
            queryParams: queryParams,
            body: body
        )

        let dataTask = (session ?? sharedSession).dataTask(
            with: request,
            completionHandler: { (data, response, error) -> Void in
                // Keep the throwing signature for compatibility. Callback errors cannot
                // propagate through sendRequest's throws and must not trigger redelivery.
                try? handler(data, response, error)
            }
        )

        if let beforeResume = beforeResume { beforeResume() }
        dataTask.resume()
        if let afterResume = afterResume { afterResume() }
        // sharedSession.finishTasksAndInvalidate()
    }

    @available(iOS 13, *)
    @available(macOS 12, *)
    public static func sendRequest(
        url: String,
        method: String,
        headers: [String: String]? = nil,
        queryParams: [String: Any]? = nil,
        body: NetBody? = nil,
        session: URLSession? = nil
    ) async throws -> (data: Data, response: URLResponse) {
        let state = AsyncRequestState()
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            let request = try makeRequest(
                url: url,
                method: method,
                headers: headers,
                queryParams: queryParams,
                body: body
            )
            try Task.checkCancellation()

            return try await withCheckedThrowingContinuation { continuation in
                guard state.install(continuation) else { return }
                let task = (session ?? sharedSession).dataTask(with: request) { data, response, error in
                    if let data, let response {
                        state.finish(.success((data: data, response: response)))
                    } else if let error {
                        state.finish(.failure(error))
                    } else {
                        state.finish(.failure(SEPCommonError("No result from Net 🤔")))
                    }
                }
                state.start(task)
            }
        } onCancel: {
            state.cancel()
        }
    }

    @available(iOS 13, *)
    @available(macOS 12, *)
    private final class AsyncRequestState: Sendable {
        typealias Response = (data: Data, response: URLResponse)
        typealias Continuation = CheckedContinuation<Response, any Error>

        private enum State {
            case idle
            case waiting(Continuation, URLSessionDataTask?)
            case finished
        }

        private let state = SafeValue<State>(.idle)

        func install(_ continuation: Continuation) -> Bool {
            let installed = state.change { state in
                guard case .idle = state else { return false }
                state = .waiting(continuation, nil)
                return true
            }
            if !installed {
                // Cancellation may arrive before the continuation is installed.
                continuation.resume(throwing: CancellationError())
            }
            return installed
        }

        func start(_ task: URLSessionDataTask) {
            let shouldStart = state.change { state in
                guard case let .waiting(continuation, _) = state else { return false }
                state = .waiting(continuation, task)
                return true
            }
            // Never call URLSessionTask methods under the lock: callbacks may be synchronous.
            // If cancellation wins after registration, resume() cannot restart a cancelled task.
            if shouldStart {
                task.resume()
            } else {
                task.cancel()
            }
        }

        func finish(_ result: Result<Response, any Error>) {
            let continuation = state.change { state -> Continuation? in
                guard case let .waiting(continuation, _) = state else { return nil }
                state = .finished
                return continuation
            }
            continuation?.resume(with: result)
        }

        func cancel() {
            let pending = state.change { state -> (continuation: Continuation?, task: URLSessionDataTask?) in
                defer { state = .finished }
                guard case let .waiting(continuation, task) = state else { return (nil, nil) }
                return (continuation, task)
            }
            pending.task?.cancel()
            pending.continuation?.resume(throwing: CancellationError())
        }
    }

    private class func makeRequest(
        url: String,
        method: String,
        headers: [String: String]? = nil,
        queryParams: [String: Any]? = nil,
        body: NetBody? = nil
    ) throws -> URLRequest {
        guard var components = URLComponents(string: url) else {
            throw NetErrors.NotValidParams
        }
        let additionalQuery = paramsString(queryParams)
        if !additionalQuery.isEmpty {
            if let existingQuery = components.percentEncodedQuery, !existingQuery.isEmpty {
                let separator = existingQuery.hasSuffix("&") ? "" : "&"
                components.percentEncodedQuery = "\(existingQuery)\(separator)\(additionalQuery)"
            } else {
                components.percentEncodedQuery = additionalQuery
            }
        }
        guard let requestUrl = components.url else {
            throw NetErrors.NotValidParams
        }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers

        if let body {
            let encodedBody = try body.encoded()
            if let contentType = request.value(forHTTPHeaderField: "Content-Type"),
                contentType != encodedBody.contentType
            {
                throw NetErrors.ConflictingContentType(
                    expected: encodedBody.contentType,
                    actual: contentType
                )
            }
            request.setValue(encodedBody.contentType, forHTTPHeaderField: "Content-Type")
            request.httpBody = encodedBody.data
        }

        return request
    }

    public static func makeQueryParamsString(_ params: [String: Any]?) -> String
    {
        let queryParamsString = paramsString(params)
        return queryParamsString.isEmpty ? "" : "?\(queryParamsString)"
    }

    public static func paramsString(_ params: [String: Any]?) -> String {
        toRailsQueryParams(params)
    }

    public static func urlEncode(_ string: String) -> String {
        let allowedCharacters = CharacterSet(
            charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.-_"
        )
        return string.addingPercentEncoding(
            withAllowedCharacters: allowedCharacters
        ) ?? ""
    }

    public static func toQueryParams(_ params: [String: Any]?) -> String {
        var paramsString = ""
        var first = true
        let separator: Character = "&"
        guard let params = params else { return paramsString }

        for (key, value) in params {
            let encodedKey = urlEncode(key)
            if first {
                first = false
                paramsString += "\(encodedKey)=\(urlEncode("\(value)"))"
            } else {
                paramsString += "\(separator)\(encodedKey)=\(urlEncode("\(value)"))"
            }
        }

        return paramsString
    }

    public static func toRailsQueryParams(_ anyObject: Any?) -> String {
        func checkValue(
            _ parentName: String,
            _ anyObject: AnyObject,
            _ queryParams: inout String
        ) {
            if let array = anyObject as? [AnyObject] {
                for (index, element) in array.enumerated() {
                    var newNodeName: String = .init()
                    if isNumeric(element) || element is String {
                        newNodeName = "\(parentName)[]"
                    } else {
                        newNodeName = "\(parentName)[\(index)]"
                    }
                    checkValue(newNodeName, element, &queryParams)
                }
            } else if let dictionary = anyObject as? [String: AnyObject] {
                for key in dictionary.keys {
                    let newNodeName =
                        parentName.count == 0
                        ? "\(key)" : "\(parentName)[\(key)]"
                    checkValue(newNodeName, dictionary[key]!, &queryParams)
                }
            } else {
                let name = urlEncode(parentName)
                let value = urlEncode("\(anyObject)")
                let pair =
                    queryParams.count == 0
                    ? "\(name)=\(value)" : "&\(name)=\(value)"
                queryParams.append(pair)
            }
        }

        if anyObject == nil { return "" }
        var result = ""
        checkValue("", anyObject as AnyObject, &result)
        return result
    }
}
