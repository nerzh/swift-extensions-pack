import Foundation
import XCTest
@testable import SwiftExtensionsPack

final class NetBodyTests: XCTestCase {
    func testRawBinaryPreservesBytesAndDefaultsToOctetStream() throws {
        let bytes = Data([0, 255, 128, 13, 10, 42])
        let encoded = try NetBody.raw(data: bytes).encoded()

        XCTAssertEqual(encoded.data, bytes)
        XCTAssertEqual(encoded.contentType, "application/octet-stream")
    }

    func testEmptyRawBodyKeepsItsContentType() throws {
        let encoded = try NetBody.raw(data: Data()).encoded()

        XCTAssertTrue(encoded.data.isEmpty)
        XCTAssertEqual(encoded.contentType, "application/octet-stream")
    }

    func testRawStringUsesUTF8WithoutChangingContent() throws {
        let text = "Привет 😀\r\n"
        let encoded = try NetBody.raw(text, contentType: .plainText).encoded()
        let defaultEncoded = try NetBody.raw(text).encoded()

        XCTAssertEqual(encoded.data, Data(text.utf8))
        XCTAssertEqual(encoded.contentType, "text/plain")
        XCTAssertEqual(defaultEncoded.data, encoded.data)
        XCTAssertEqual(defaultEncoded.contentType, "application/octet-stream")
    }

    func testCustomMIMETypePreservesParameters() throws {
        let contentType = "application/vnd.net-test+binary; version=2"
        let encoded = try NetBody.raw(data: Data([42]), contentType: .custom(contentType)).encoded()

        XCTAssertEqual(encoded.contentType, contentType)
        XCTAssertEqual(encoded.data, Data([42]))
    }

    func testJSONEncodesModelWithUnicodeAndScalarTypes() throws {
        let payload = NetTestPayload(title: "Summer + Привет", count: 2, enabled: true)
        let encoded = try NetBody.json(payload).encoded()
        let decoded = try JSONDecoder().decode(NetTestPayload.self, from: encoded.data)

        XCTAssertEqual(encoded.contentType, "application/json")
        XCTAssertEqual(decoded, payload)
    }

    func testRawJSONTextIsNotEncodedAsAJSONString() throws {
        let text = "{ \"name\": \"Alex\" }\n"
        let raw = try NetBody.raw(text, contentType: .json).encoded()
        let json = try NetBody.json(text).encoded()

        XCTAssertEqual(raw.data, Data(text.utf8))
        XCTAssertEqual(raw.contentType, "application/json")
        XCTAssertEqual(try JSONDecoder().decode(String.self, from: json.data), text)
        XCTAssertNotEqual(raw.data, json.data)
    }

    func testJSONEncodingFailureIsPropagated() {
        XCTAssertThrowsError(try NetBody.json(FailingNetPayload()).encoded()) {
            XCTAssertEqual($0 as? NetTestError, .encodingFailed)
        }
    }

    func testFormEscapesNamesValuesAndLiteralPlusSigns() throws {
        let encoded = try NetBody.form([
            "name&admin": "a +&=é",
            "empty": ""
        ]).encoded()

        XCTAssertEqual(encoded.contentType, "application/x-www-form-urlencoded")
        let fields = String(decoding: encoded.data, as: UTF8.self).split(separator: "&").map(String.init)
        XCTAssertEqual(fields.count, 2)
        XCTAssertEqual(Set(fields), ["empty=", "name%26admin=a+%2B%26%3D%C3%A9"])
    }

    func testFormEscapesUnicodeAndControlCharacters() throws {
        let encoded = try NetBody.form(["é": "😀\r\n"]).encoded()

        XCTAssertEqual(String(decoding: encoded.data, as: UTF8.self), "%C3%A9=%F0%9F%98%80%0D%0A")
    }

    func testEmptyFormProducesEmptyDataWithFormContentType() throws {
        let encoded = try NetBody.form([:]).encoded()

        XCTAssertTrue(encoded.data.isEmpty)
        XCTAssertEqual(encoded.contentType, "application/x-www-form-urlencoded")
    }

    func testMultipartPreservesPartOrderDuplicateNamesAndBinaryData() throws {
        let firstBytes = Data([0xff, 0xd8, 0, 0xff, 0xd9])
        let secondBytes = Data([0x89, 0x50, 0x4e, 0x47])
        let firstFile = NetSessionFile(data: firstBytes, fileName: "first.jpg", mimeType: .jpeg)
        let secondFile = CustomNetTestFile(data: secondBytes, fileName: "second.png", mimeType: .png)
        let encoded = try NetBody.multipart([
            .field(name: "caption", value: "Summer"),
            .file(name: "photo", file: firstFile),
            .file(name: "photo", file: secondFile)
        ]).encoded()

        let prefix = "multipart/form-data; boundary="
        XCTAssertTrue(encoded.contentType.hasPrefix(prefix))
        let boundary = String(encoded.contentType.dropFirst(prefix.count))
        XCTAssertFalse(boundary.isEmpty)

        var expected = Data((
            "--\(boundary)\r\nContent-Disposition: form-data; name=\"caption\"\r\n\r\nSummer\r\n"
            + "--\(boundary)\r\nContent-Disposition: form-data; name=\"photo\"; filename=\"first.jpg\"\r\n"
            + "Content-Type: image/jpeg\r\n\r\n"
        ).utf8)
        expected.append(firstBytes)
        expected.append(Data((
            "\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"photo\"; filename=\"second.png\"\r\n"
            + "Content-Type: image/png\r\n\r\n"
        ).utf8))
        expected.append(secondBytes)
        expected.append(Data("\r\n--\(boundary)--".utf8))

        XCTAssertEqual(encoded.data, expected)
    }

    func testMultipartSupportsDefaultAndCustomFileMIMETypes() throws {
        let defaultFile = NetSessionFile(data: Data([42]), fileName: "data.bin")
        let customFile = NetSessionFile(
            data: Data([43]), fileName: "data.custom", mimeType: .custom("application/vnd.net-test")
        )
        let encoded = try NetBody.multipart([
            .file(name: "binary", file: defaultFile),
            .file(name: "custom", file: customFile)
        ]).encoded()
        let body = String(decoding: encoded.data, as: UTF8.self)

        XCTAssertEqual(defaultFile.mimeType, .octetStream)
        XCTAssertTrue(body.contains("Content-Type: application/octet-stream\r\n\r\n*\r\n"))
        XCTAssertTrue(body.contains("Content-Type: application/vnd.net-test\r\n\r\n+\r\n"))
    }

    func testMultipartBuilderUsesProvidedBoundaryAndDefaultFileType() throws {
        let multipart = NetMultipartData(boundary: "fixed-boundary")
        try multipart.appendFile("file", Data([42]), "data.bin")
        let expected = Data((
            "--fixed-boundary\r\nContent-Disposition: form-data; name=\"file\"; filename=\"data.bin\"\r\n"
            + "Content-Type: application/octet-stream\r\n\r\n*\r\n--fixed-boundary--"
        ).utf8)

        XCTAssertEqual(multipart.finalizeBodyAndGetData() as Data, expected)
    }
}
