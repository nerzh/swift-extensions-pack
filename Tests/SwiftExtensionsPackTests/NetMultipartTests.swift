import Foundation
import XCTest
@testable import SwiftExtensionsPack

final class NetMultipartTests: XCTestCase {
    func testMultipartEscapesHeaderMetadataWithoutChangingPayload() throws {
        let data = Data([0, 255, 13, 10, 34, 92])
        let encoded = try NetBody.multipart([
            .field(name: "field\"\r\nInjected: yes", value: "unchanged\r\nvalue"),
            .file(name: "upload\\", file: NetSessionFile(
                data: data, fileName: "фото\"\r\nX-Injected: yes\u{0}.jpg", mimeType: .jpeg
            ))
        ]).encoded()
        let text = String(decoding: encoded.data, as: UTF8.self)

        XCTAssertTrue(text.contains("name=\"field%22%0D%0AInjected: yes\"\r\n\r\nunchanged\r\nvalue\r\n"))
        XCTAssertTrue(text.contains("name=\"upload\\\\\"; filename=\"фото%22%0D%0AX-Injected: yes%00.jpg\"\r\n"))
        XCTAssertFalse(text.contains("\r\nInjected:"))
        XCTAssertFalse(text.contains("\r\nX-Injected:"))
        XCTAssertNotNil(encoded.data.range(of: data))
    }

    func testMultipartRejectsInjectedCustomMIMEType() {
        let mime = "image/png\r\nX-Injected: yes"
        let file = NetSessionFile(data: Data([42]), fileName: "photo.png", mimeType: .custom(mime))
        XCTAssertThrowsError(try NetBody.multipart([.file(name: "photo", file: file)]).encoded())
    }

    func testInvalidFileMIMETypeDoesNotPartiallyAppendToBuilder() throws {
        let multipart = NetMultipartData(boundary: "fixed")
        multipart.append("existing", "value")
        let before = multipart.body as Data

        XCTAssertThrowsError(try multipart.appendFile(
            "file", Data([42]), "file.bin", mimeType: .custom("application/octet-stream\nInjected: yes")
        ))
        XCTAssertEqual(multipart.body as Data, before)
    }

    func testAllASCIIControlsAreEscapedInDispositionParameters() {
        let controls = (0...31).map { String(UnicodeScalar($0)!) }.joined() + "\u{7f}"
        let multipart = NetMultipartData(boundary: "fixed")
        multipart.append(controls, "value")
        let text = String(decoding: multipart.finalizeBodyAndGetData() as Data, as: UTF8.self)
        let expected = (0...31).map { String(format: "%%%02X", $0) }.joined() + "%7F"
        XCTAssertEqual(text, "--fixed\r\nContent-Disposition: form-data; name=\"\(expected)\"\r\n\r\nvalue\r\n--fixed--")
    }

    func testOrdinaryUnicodeNamesAndQuotedFileMIMEParametersArePreserved() throws {
        let multipart = NetMultipartData(boundary: "fixed")
        let mime = #"application/example; profile="a;b\"c""#
        try multipart.appendFile("фото[]", Data([42]), "лето 😀.bin", mimeType: .custom(mime))
        let text = String(decoding: multipart.finalizeBodyAndGetData() as Data, as: UTF8.self)
        XCTAssertTrue(text.contains("name=\"фото[]\"; filename=\"лето 😀.bin\"\r\n"))
        XCTAssertTrue(text.contains("Content-Type: \(mime)\r\n\r\n*\r\n"))
    }

    func testRailsMultipartEscapesNestedNamesAndPropagatesFileErrors() throws {
        let multipart = NetMultipartData(boundary: "fixed")
        let file = NetSessionFile(data: Data([42]), fileName: "photo\".png", mimeType: .png)
        let object: [String: Any] = ["user": ["photo\r\n": file]]
        let data = try multipart.toRailsMultipartData(object) as Data
        let text = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(text.contains("name=\"user[photo%0D%0A]\"; filename=\"photo%22.png\""))
        XCTAssertEqual(multipart.finalizeBodyAndGetData() as Data, data)

        let invalid = NetSessionFile(data: Data(), fileName: "file", mimeType: .custom("bad\nMIME"))
        XCTAssertThrowsError(try NetMultipartData().toRailsMultipartData(["files": [invalid]]))
        XCTAssertThrowsError(try ["file": invalid].toRailsMultipartData())
    }

    func testRepeatedFinalizationReturnsIdenticalBodies() {
        let multipart = NetMultipartData(boundary: "fixed")
        multipart.append("name", "value")
        let first = multipart.finalizeBodyAndGetData() as Data
        let second = multipart.finalizeBodyAndGetData() as Data

        XCTAssertEqual(first, second)
        XCTAssertEqual(String(decoding: second, as: UTF8.self),
                       "--fixed\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nvalue\r\n--fixed--")
    }

    func testAppendingAfterFinalizationKeepsBothPartsBeforeClosingBoundary() throws {
        let multipart = NetMultipartData(boundary: "fixed")
        multipart.append("first", "one")
        let first = multipart.finalizeBodyAndGetData()
        let firstBytes = first as Data
        try multipart.appendFile("second", Data([42]), "two.bin")
        let second = multipart.finalizeBodyAndGetData() as Data

        XCTAssertEqual(first as Data, firstBytes)
        let expected = "--fixed\r\nContent-Disposition: form-data; name=\"first\"\r\n\r\none\r\n"
            + "--fixed\r\nContent-Disposition: form-data; name=\"second\"; filename=\"two.bin\"\r\n"
            + "Content-Type: application/octet-stream\r\n\r\n*\r\n--fixed--"
        XCTAssertEqual(second, Data(expected.utf8))
    }

    func testMutatingFinalizedResultDoesNotChangeBuilder() {
        let multipart = NetMultipartData(boundary: "fixed")
        multipart.append("name", "value")
        let result = multipart.finalizeBodyAndGetData()
        let original = result as Data
        result.append(Data("changed".utf8))

        XCTAssertEqual(multipart.finalizeBodyAndGetData() as Data, original)
    }

    func testEmptyMultipartCanBeFinalizedRepeatedlyThenAppended() {
        let multipart = NetMultipartData(boundary: "fixed")
        XCTAssertEqual(multipart.finalizeBodyAndGetData() as Data, Data("--fixed--".utf8))
        XCTAssertEqual(multipart.finalizeBodyAndGetData() as Data, Data("--fixed--".utf8))
        multipart.append("field", "value")
        XCTAssertEqual(multipart.finalizeBodyAndGetData() as Data,
                       Data("--fixed\r\nContent-Disposition: form-data; name=\"field\"\r\n\r\nvalue\r\n--fixed--".utf8))
    }
}
