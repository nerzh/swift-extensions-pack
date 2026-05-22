//
//  File.swift
//
//
//  Created by Oleh Hudeichuk on 21.03.2023.
//

import Foundation

public protocol ErrorCommon: Error, LocalizedError, CustomStringConvertible, CustomDebugStringConvertible, Decodable {
    var reason: String { get set }
    
    init()
    init(_ reason: String, file: String, function: String, line: Int)
    init(_ error: Error, errorLevel: ErrorCommonLevel, file: String, function: String, line: Int)
    init(_ error: Error, exReason: String, errorLevel: ErrorCommonLevel, file: String, function: String, line: Int)
    
    static func error(_ error: Error, file: String, function: String, line: Int) -> Self
}

public enum ErrorCommonLevel: Cases {
    case release
    case debug
}

extension ErrorCommon {
    private static var multipleUnderlyingErrorsUserInfoKey: String { "NSMultipleUnderlyingErrors" }
    private static var maxUnderlyingErrorDepth: Int { 5 }
    
    public var description: String { "\(reason)" }
    public var debugDescription: String { self.description }
    public var errorDescription: String? { self.description }
    public var failureReason: String? { self.description }
    public var recoverySuggestion: String? { self.description }
    public var helpAnchor: String? { self.description }
    #warning("if localizedDescription not defined we have sigterm for linux https://github.com/swiftlang/swift-corelibs-foundation/issues/5221")
    public var localizedDescription: String { self.description }
    
    public init(_ reason: String, file: String = #file, function: String = #function, line: Int = #line) {
        self.init()
        self.reason = "\(file), \(function), line \(line): \(reason)"
    }
    
    public init(_ error: Error, errorLevel: ErrorCommonLevel = .debug, file: String = #file, function: String = #function, line: Int = #line) {
        self.init(Self.getDetailedErrorMessage(error, errorLevel: errorLevel), file: file, function: function, line: line)
    }
    
    public init(_ error: Error, exReason: String, errorLevel: ErrorCommonLevel = .debug, file: String = #file, function: String = #function, line: Int = #line) {
        let textError: String = "[\(exReason)] \(Self.getDetailedErrorMessage(error, errorLevel: errorLevel))"
        self.init(textError, file: file, function: function, line: line)
    }
    
    public static func error(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) -> Self {
        Self(error, errorLevel: .debug, file: file, function: function, line: line)
    }
    
    private static func getDetailedErrorMessage(_ error: Error, errorLevel: ErrorCommonLevel = .debug) -> String {
        var collector: ErrorCommonMessageCollector = .init()
        var visitedNSErrors: Set<ObjectIdentifier> = .init()
        collectDetailedErrorMessage(error, errorLevel: errorLevel, collector: &collector, visitedNSErrors: &visitedNSErrors)
        return collector.message(defaultValue: String(reflecting: error))
    }
    
    private static func collectDetailedErrorMessage(
        _ error: Error,
        errorLevel: ErrorCommonLevel,
        collector: inout ErrorCommonMessageCollector,
        visitedNSErrors: inout Set<ObjectIdentifier>,
        depth: Int = 0
    ) {
        guard depth <= maxUnderlyingErrorDepth else {
            collector.add("Maximum underlying error depth reached.")
            return
        }
        
        if let localizedError = error as? LocalizedError {
            collector.add(localizedError.errorDescription)
            collector.add(localizedError.failureReason)
            collector.add(localizedError.recoverySuggestion)
            collector.add(localizedError.helpAnchor)
        }
        
        let nsError: NSError = error as NSError
        let nsErrorIdentifier: ObjectIdentifier = .init(nsError)
        guard visitedNSErrors.insert(nsErrorIdentifier).inserted else {
            collector.add("Cyclic NSError reference: domain: \(nsError.domain), code: \(nsError.code)")
            return
        }
        
        collectNSErrorMessage(nsError, errorLevel: errorLevel, collector: &collector, visitedNSErrors: &visitedNSErrors, depth: depth)
        collectCustomDescriptions(error, errorLevel: errorLevel, collector: &collector)
        
        if errorLevel == .release, collector.isEmpty {
            collector.add(String(describing: error))
        }
        
        if errorLevel == .debug {
            collector.add(String(reflecting: error))
        }
    }
    
    private static func collectNSErrorMessage(
        _ nsError: NSError,
        errorLevel: ErrorCommonLevel,
        collector: inout ErrorCommonMessageCollector,
        visitedNSErrors: inout Set<ObjectIdentifier>,
        depth: Int
    ) {
        collector.add(nsError.userInfo[NSLocalizedDescriptionKey] as? String)
        collector.add(nsError.userInfo[NSLocalizedFailureErrorKey] as? String)
        collector.add(nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String)
        collector.add(nsError.userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String)
        collector.add(nsError.userInfo[NSHelpAnchorErrorKey] as? String)
        
        if let recoveryOptions = nsError.userInfo[NSLocalizedRecoveryOptionsErrorKey] as? [String], !recoveryOptions.isEmpty {
            collector.add(recoveryOptions.joined(separator: ", "))
        }
        
        addMeaningfulLocalizedDescription(nsError, collector: &collector)
        collector.add(nsError.localizedFailureReason)
        collector.add(nsError.localizedRecoverySuggestion)
        collector.add(nsError.helpAnchor)
        
        if errorLevel == .debug {
            collector.add(nsError.userInfo[NSDebugDescriptionErrorKey] as? String)
            collector.add("domain: \(nsError.domain), code: \(nsError.code)")
            collectAdditionalNSErrorUserInfo(nsError, collector: &collector, visitedNSErrors: &visitedNSErrors, depth: depth)
        }
        
        collectUnderlyingErrors(nsError, errorLevel: errorLevel, collector: &collector, visitedNSErrors: &visitedNSErrors, depth: depth)
    }
    
    private static func addMeaningfulLocalizedDescription(_ nsError: NSError, collector: inout ErrorCommonMessageCollector) {
        let defaultDescription: String = NSError(domain: nsError.domain, code: nsError.code, userInfo: nil).localizedDescription
        if nsError.localizedDescription != defaultDescription {
            collector.add(nsError.localizedDescription)
        }
    }
    
    private static func collectCustomDescriptions(_ error: Error, errorLevel: ErrorCommonLevel, collector: inout ErrorCommonMessageCollector) {
        switch errorLevel {
        case .release:
            if collector.isEmpty {
                collector.add(((error as Any) as? CustomStringConvertible)?.description)
            }
        case .debug:
            collector.add(((error as Any) as? CustomDebugStringConvertible)?.debugDescription)
            collector.add(((error as Any) as? CustomStringConvertible)?.description)
        }
    }
    
    private static func collectAdditionalNSErrorUserInfo(
        _ nsError: NSError,
        collector: inout ErrorCommonMessageCollector,
        visitedNSErrors: inout Set<ObjectIdentifier>,
        depth: Int
    ) {
        let skippedKeys: Set<String> = [
            NSLocalizedDescriptionKey,
            NSLocalizedFailureErrorKey,
            NSLocalizedFailureReasonErrorKey,
            NSLocalizedRecoverySuggestionErrorKey,
            NSLocalizedRecoveryOptionsErrorKey,
            NSHelpAnchorErrorKey,
            NSDebugDescriptionErrorKey,
            NSUnderlyingErrorKey,
            multipleUnderlyingErrorsUserInfoKey
        ]
        
        for key in nsError.userInfo.keys.sorted() where !skippedKeys.contains(key) {
            guard let value = nsError.userInfo[key] else { continue }
            collectNSErrorUserInfoValue(value, key: key, collector: &collector, visitedNSErrors: &visitedNSErrors, depth: depth)
        }
    }
    
    private static func collectNSErrorUserInfoValue(
        _ value: Any,
        key: String,
        collector: inout ErrorCommonMessageCollector,
        visitedNSErrors: inout Set<ObjectIdentifier>,
        depth: Int
    ) {
        switch value {
        case let error as Error:
            collector.add("\(key):")
            collectDetailedErrorMessage(error, errorLevel: .debug, collector: &collector, visitedNSErrors: &visitedNSErrors, depth: depth + 1)
        case let string as String:
            collector.add("\(key): \(string)")
        case let string as NSString:
            collector.add("\(key): \(string as String)")
        case let url as URL:
            collector.add("\(key): \(url.absoluteString)")
        case let strings as [String]:
            if !strings.isEmpty {
                collector.add("\(key): \(strings.joined(separator: ", "))")
            }
        case let values as [Any]:
            for value in values {
                collectNSErrorUserInfoValue(value, key: key, collector: &collector, visitedNSErrors: &visitedNSErrors, depth: depth)
            }
        case let dictionary as [String: Any]:
            for dictionaryKey in dictionary.keys.sorted() {
                guard let dictionaryValue = dictionary[dictionaryKey] else { continue }
                collectNSErrorUserInfoValue(
                    dictionaryValue,
                    key: "\(key).\(dictionaryKey)",
                    collector: &collector,
                    visitedNSErrors: &visitedNSErrors,
                    depth: depth
                )
            }
        case let value as CustomStringConvertible:
            collector.add("\(key): \(value.description)")
        default:
            break
        }
    }
    
    private static func collectUnderlyingErrors(
        _ nsError: NSError,
        errorLevel: ErrorCommonLevel,
        collector: inout ErrorCommonMessageCollector,
        visitedNSErrors: inout Set<ObjectIdentifier>,
        depth: Int
    ) {
        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            collector.add("Underlying error:")
            collectDetailedErrorMessage(underlyingError, errorLevel: errorLevel, collector: &collector, visitedNSErrors: &visitedNSErrors, depth: depth + 1)
        }
        
        let multipleUnderlyingErrors: [Error]
        if let errors = nsError.userInfo[multipleUnderlyingErrorsUserInfoKey] as? [Error] {
            multipleUnderlyingErrors = errors
        } else if let errors = nsError.userInfo[multipleUnderlyingErrorsUserInfoKey] as? [NSError] {
            multipleUnderlyingErrors = errors
        } else {
            multipleUnderlyingErrors = []
        }
        
        for (index, error) in multipleUnderlyingErrors.enumerated() {
            collector.add("Underlying error \(index + 1):")
            collectDetailedErrorMessage(error, errorLevel: errorLevel, collector: &collector, visitedNSErrors: &visitedNSErrors, depth: depth + 1)
        }
    }
}

private struct ErrorCommonMessageCollector {
    private(set) var messages: [String] = []
    private var uniqueMessages: Set<String> = .init()
    
    var isEmpty: Bool { messages.isEmpty }
    
    mutating func add(_ message: String?) {
        guard let message = message?.trimmingCharacters(in: .whitespacesAndNewlines), !message.isEmpty else { return }
        guard uniqueMessages.insert(message).inserted else { return }
        messages.append(message)
    }
    
    func message(defaultValue: String) -> String {
        if messages.isEmpty { return defaultValue }
        return messages.joined(separator: "\n")
    }
}

public struct SEPCommonError: ErrorCommon {
    public var reason: String = ""
    public init() {}
}
