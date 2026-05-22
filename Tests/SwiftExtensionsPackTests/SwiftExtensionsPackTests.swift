import Foundation
import XCTest
@testable import SwiftExtensionsPack

final class swift_extensions_packTests: XCTestCase {
    
    func testHMAC() async throws {
        let digest = SEPCrypto.HMAC.sha512.digest(string: "password_string", key: "mnemonic_string")
        XCTAssertEqual(digest, "8c47a8d170288876da8e897eb0c4d4bbb299b1d3c23b96c70e41efb7597f3644438935b93e230ae203785f16ea327d7851180e036487aeac0124a8d51f10879a")
    }
    
    func testEd25519() async throws {
        let pair = SEPCrypto.Ed25519.createKeyPair(seed32Byte: Data([UInt8](repeating: 1, count: 32).join("").utf8))
        XCTAssertEqual(pair.public.toHexadecimal, "48075a597e721a156e2e0799de5cc0c5324dc6e7eaf1cdd46250868ec53215dd")
        
        let publicKey = SEPCrypto.Ed25519.createPublicKey(secretKey: pair.secret)
        XCTAssertEqual(publicKey.toHexadecimal, "48075a597e721a156e2e0799de5cc0c5324dc6e7eaf1cdd46250868ec53215dd")
        
        let sec = SEPCrypto.Ed25519.createKeyPair(seed32Byte: Data([54, 127, 48, 121, 109, 102, 195, 17, 156, 118, 116, 221, 48, 227, 98, 172, 167, 41, 196, 109, 128, 145, 2, 212, 221, 19, 91, 148, 81, 230, 22, 159])).secret
        let signature = SEPCrypto.Ed25519.sign(
            message: Data([121, 233, 104, 121, 38, 187, 238, 146, 178, 255, 221, 55, 72, 228, 239, 159, 156, 182, 199, 245, 119, 97, 219, 98, 250, 253, 226, 135, 93, 61, 237, 54]),
            publicKey32byte: Data([228, 184, 8, 193, 149, 69, 212, 253, 77, 201, 8, 70, 165, 248, 138, 156, 17, 3, 227, 31, 16, 238, 9, 60, 224, 239, 152, 177, 62, 50, 178, 51]),
            secretKey64byte: sec)
        XCTAssertEqual(signature.toHexadecimal, "34f16f4074c4cb10b10bf909f9d8444c37bf683ae6f92f07a220fab5544034ecf871d5be7b51c0ef80849aa3e8198eb372967352017a6e6d763406da82d83c08")
    }
    
    func testRandom() async throws {
        for _ in 0...100000 {
            let num1 = randomUInt(min: 3, max: 4)
            XCTAssertTrue(num1 >= 3)
            XCTAssertTrue(num1 <= 4)
            
            let num2 = randomUInt(min: 0, max: UInt.max)
            XCTAssertTrue(num2 >= 0)
            XCTAssertTrue(num2 <= UInt.max - 1)
        }
    }
    
    func testErrorCommonExposesReasonThroughAllStringChannels() {
        let error = SEPCommonError("base reason", file: "File.swift", function: "load()", line: 12)
        let expected = "File.swift, load(), line 12: base reason"
        
        XCTAssertEqual(error.reason, expected)
        XCTAssertEqual(error.description, expected)
        XCTAssertEqual(error.debugDescription, expected)
        XCTAssertEqual(error.errorDescription, expected)
        XCTAssertEqual(error.failureReason, expected)
        XCTAssertEqual(error.recoverySuggestion, expected)
        XCTAssertEqual(error.helpAnchor, expected)
        XCTAssertEqual(error.localizedDescription, expected)
    }
    
    func testPlainSwiftErrorFallsBackToReflectingErrorInDebug() {
        let error = SEPCommonError(PlainTestError.broken)
        
        assertContains(error.reason, "PlainTestError.broken")
    }
    
    func testLocalizedErrorCollectsAllLocalizedFields() {
        let source = LocalizedVariantError(
            errorDescription: "localized primary",
            failureReason: "localized failure",
            recoverySuggestion: "localized recovery",
            helpAnchor: "localized help"
        )
        
        let error = SEPCommonError(source, file: "File.swift", function: "run()", line: 4)
        
        assertContains(error.reason, "localized primary")
        assertContains(error.reason, "localized failure")
        assertContains(error.reason, "localized recovery")
        assertContains(error.reason, "localized help")
    }
    
    func testLocalizedErrorCollectsPartialLocalizedFields() {
        let source = LocalizedVariantError(
            errorDescription: nil,
            failureReason: "only failure is set",
            recoverySuggestion: nil,
            helpAnchor: "only help is set"
        )
        
        let error = SEPCommonError(source, file: "File.swift", function: "run()", line: 5)
        
        assertContains(error.reason, "only failure is set")
        assertContains(error.reason, "only help is set")
    }
    
    func testCustomDescriptionsRespectErrorLevel() {
        let debugError = SEPCommonError(TextualVariantError(), errorLevel: .debug, file: "File.swift", function: "run()", line: 6)
        let releaseError = SEPCommonError(TextualVariantError(), errorLevel: .release, file: "File.swift", function: "run()", line: 7)
        
        assertContains(debugError.reason, "debug description text")
        assertContains(debugError.reason, "release description text")
        assertContains(releaseError.reason, "release description text")
        assertDoesNotContain(releaseError.reason, "debug description text")
    }
    
    func testNSErrorCollectsLocalizedDebugDomainAndAdditionalUserInfo() {
        let source = NSError(
            domain: "Extractor.NSError",
            code: 42,
            userInfo: [
                NSLocalizedDescriptionKey: "ns localized description",
                NSLocalizedFailureErrorKey: "ns failure",
                NSLocalizedFailureReasonErrorKey: "ns failure reason",
                NSLocalizedRecoverySuggestionErrorKey: "ns recovery",
                NSLocalizedRecoveryOptionsErrorKey: ["Retry", "Cancel"],
                NSHelpAnchorErrorKey: "ns help",
                NSDebugDescriptionErrorKey: "ns debug description",
                "RequestID": "req-42",
                "FailedURL": URL(string: "https://example.com/api")!
            ]
        )
        
        let debugError = SEPCommonError(source, errorLevel: .debug, file: "File.swift", function: "run()", line: 8)
        let releaseError = SEPCommonError(source, errorLevel: .release, file: "File.swift", function: "run()", line: 9)
        
        assertContains(debugError.reason, "ns localized description")
        assertContains(debugError.reason, "ns failure")
        assertContains(debugError.reason, "ns failure reason")
        assertContains(debugError.reason, "ns recovery")
        assertContains(debugError.reason, "Retry, Cancel")
        assertContains(debugError.reason, "ns help")
        assertContains(debugError.reason, "ns debug description")
        assertContains(debugError.reason, "domain: Extractor.NSError, code: 42")
        assertContains(debugError.reason, "RequestID: req-42")
        assertContains(debugError.reason, "FailedURL: https://example.com/api")
        
        assertContains(releaseError.reason, "ns localized description")
        assertContains(releaseError.reason, "ns failure reason")
        assertContains(releaseError.reason, "ns recovery")
        assertContains(releaseError.reason, "ns help")
        assertDoesNotContain(releaseError.reason, "ns debug description")
        assertDoesNotContain(releaseError.reason, "RequestID: req-42")
    }
    
    func testNSErrorCollectsUnderlyingAndMultipleUnderlyingErrors() {
        let first = NSError(domain: "Extractor.InnerOne", code: 11, userInfo: [NSLocalizedDescriptionKey: "first underlying"])
        let second = NSError(domain: "Extractor.InnerTwo", code: 12, userInfo: [NSLocalizedDescriptionKey: "second underlying"])
        let source = NSError(
            domain: "Extractor.Outer",
            code: 10,
            userInfo: [
                NSLocalizedDescriptionKey: "outer description",
                NSUnderlyingErrorKey: first,
                "NSMultipleUnderlyingErrors": [second]
            ]
        )
        
        let error = SEPCommonError(source, file: "File.swift", function: "run()", line: 10)
        
        assertContains(error.reason, "outer description")
        assertContains(error.reason, "Underlying error:")
        assertContains(error.reason, "first underlying")
        assertContains(error.reason, "Underlying error 1:")
        assertContains(error.reason, "second underlying")
    }
    
    func testDecodingErrorCollectsDebugDescriptionAndUnderlyingError() {
        let underlying = NSError(domain: "Extractor.Decoding", code: 21, userInfo: [NSLocalizedDescriptionKey: "raw payload is empty"])
        let context = DecodingError.Context(
            codingPath: [TestCodingKey.payload],
            debugDescription: "cannot decode payload",
            underlyingError: underlying
        )
        
        let error = SEPCommonError(DecodingError.dataCorrupted(context), file: "File.swift", function: "run()", line: 11)
        
        assertContains(error.reason, "cannot decode payload")
        assertContains(error.reason, "raw payload is empty")
        assertContains(error.reason, "domain: NSCocoaErrorDomain, code: 4864")
    }
    
    func testCustomNSErrorUsesNSErrorBridgeAndUnderlyingError() {
        let underlying = NSError(domain: "Extractor.Custom.Inner", code: 31, userInfo: [NSLocalizedDescriptionKey: "custom inner"])
        let error = SEPCommonError(CustomNSErrorVariant(underlying: underlying), file: "File.swift", function: "run()", line: 12)
        
        assertContains(error.reason, "custom ns description")
        assertContains(error.reason, "custom failure reason")
        assertContains(error.reason, "domain: Extractor.CustomNSError, code: 30")
        assertContains(error.reason, "CustomRequestID: custom-request")
        assertContains(error.reason, "custom inner")
    }
    
    func testWrappedErrorCommonDoesNotDuplicateSameLocalizedFields() {
        let source = SEPCommonError("already wrapped", file: "Inner.swift", function: "inner()", line: 13)
        let error = SEPCommonError(source, errorLevel: .release, file: "Outer.swift", function: "outer()", line: 14)
        
        XCTAssertEqual(occurrences(of: "already wrapped", in: error.reason), 1)
        assertContains(error.reason, "Inner.swift, inner(), line 13: already wrapped")
    }
    
    private enum PlainTestError: Error {
        case broken
    }
    
    private enum TestCodingKey: String, CodingKey {
        case payload
    }
    
    private struct LocalizedVariantError: Error, LocalizedError {
        let errorDescription: String?
        let failureReason: String?
        let recoverySuggestion: String?
        let helpAnchor: String?
    }
    
    private struct TextualVariantError: Error, CustomStringConvertible, CustomDebugStringConvertible {
        var description: String { "release description text" }
        var debugDescription: String { "debug description text" }
    }
    
    private struct CustomNSErrorVariant: Error, CustomNSError {
        static var errorDomain: String { "Extractor.CustomNSError" }
        var errorCode: Int { 30 }
        let underlying: NSError
        
        var errorUserInfo: [String: Any] {
            [
                NSLocalizedDescriptionKey: "custom ns description",
                NSLocalizedFailureReasonErrorKey: "custom failure reason",
                NSUnderlyingErrorKey: underlying,
                "CustomRequestID": "custom-request"
            ]
        }
    }
    
    private func assertContains(_ value: String, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(value.contains(expected), "Expected <\(value)> to contain <\(expected)>", file: file, line: line)
    }
    
    private func assertDoesNotContain(_ value: String, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(value.contains(expected), "Expected <\(value)> not to contain <\(expected)>", file: file, line: line)
    }
    
    private func occurrences(of expected: String, in value: String) -> Int {
        guard !expected.isEmpty else { return 0 }
        return value.components(separatedBy: expected).count - 1
    }
}
