import Foundation
import XCTest
import SwiftExtensionsPack

final class SHA256HasherTests: XCTestCase {
    private let emptyDigest = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    private let abcDigest = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"

    func testFinalizeWithoutUpdates() {
        let digest: Data = SEPCrypto.SHA256Hasher().finalize()
        XCTAssertEqual(digest.count, 32)
        XCTAssertEqual(digest.toHexadecimal, emptyDigest)
        XCTAssertEqual(digest, Data(SEPCrypto.SHA.sha256.digest(data: Data())))
    }

    func testEmptyUpdates() {
        var hasher = SEPCrypto.SHA256Hasher()
        let storage = Data([0xff])
        let emptySlice: Data.SubSequence = storage[1..<1]
        XCTAssertEqual(emptySlice.startIndex, 1)

        hasher.update(data: Data())
        hasher.update(data: [UInt8]())
        hasher.update(data: emptySlice)

        let digest = hasher.finalize()
        XCTAssertEqual(digest.count, 32)
        XCTAssertEqual(digest.toHexadecimal, emptyDigest)
    }

    func testKnownABCWithDataAndByteArray() {
        let input = Data("abc".utf8)
        var dataHasher = SEPCrypto.SHA256Hasher()
        dataHasher.update(data: input)
        var arrayHasher = SEPCrypto.SHA256Hasher()
        arrayHasher.update(data: Array(input))

        let expected = Data(SEPCrypto.SHA.sha256.digest(data: input))
        for digest in [dataHasher.finalize(), arrayHasher.finalize()] {
            XCTAssertEqual(digest.count, 32)
            XCTAssertEqual(digest.toHexadecimal, abcDigest)
            XCTAssertEqual(digest, expected)
        }
    }

    func testChunkSizesMatchOneShotDigest() {
        let bytes = Array(UInt8.min...UInt8.max)
        let data = Data(bytes)
        let expected = Data(SEPCrypto.SHA.sha256.digest(data: data))

        for size in [1, 7, 63, 64, 65, 128, 256] {
            var dataHasher = SEPCrypto.SHA256Hasher()
            var arrayHasher = SEPCrypto.SHA256Hasher()
            dataHasher.update(data: Data())
            arrayHasher.update(data: [UInt8]())

            for start in stride(from: 0, to: bytes.count, by: size) {
                let end = min(start + size, bytes.count)
                dataHasher.update(data: data[start..<end])
                arrayHasher.update(data: Array(bytes[start..<end]))
                dataHasher.update(data: Data())
                arrayHasher.update(data: [UInt8]())
            }

            for digest in [dataHasher.finalize(), arrayHasher.finalize()] {
                XCTAssertEqual(digest.count, 32, "Chunk size: \(size)")
                XCTAssertEqual(digest, expected, "Chunk size: \(size)")
            }
        }
    }

    func testDataSliceWithNonzeroStartIndex() {
        let storage = Data(repeating: 0xff, count: 40) + Data("abc".utf8) + Data([0xff])
        let slice: Data.SubSequence = storage[40..<43]
        XCTAssertEqual(slice.startIndex, 40)

        var hasher = SEPCrypto.SHA256Hasher()
        hasher.update(data: slice)
        XCTAssertEqual(hasher.finalize().toHexadecimal, abcDigest)
    }

    func testIndependentCopiesAfterCommonPrefix() {
        var first = SEPCrypto.SHA256Hasher()
        first.update(data: Data("a".utf8))
        var second = first
        let prefix = first

        XCTAssertEqual(prefix.finalize(), Data(SEPCrypto.SHA.sha256.digest(data: Data("a".utf8))))
        first.update(data: Array("bc".utf8))
        let firstDigest = first.finalize()
        second.update(data: Data("bcd".utf8))
        let secondDigest = second.finalize()

        XCTAssertEqual(firstDigest.toHexadecimal, abcDigest)
        XCTAssertEqual(firstDigest, Data(SEPCrypto.SHA.sha256.digest(data: Data("abc".utf8))))
        XCTAssertEqual(secondDigest.toHexadecimal, "88d4266fd4e6338d13b845fcf289579d209c897823b9217da3e161936f031589")
        XCTAssertEqual(secondDigest, Data(SEPCrypto.SHA.sha256.digest(data: Data("abcd".utf8))))
    }

    func testEverBlockSeedDigestVector() {
        let blockSeed = [UInt8](repeating: 0x42, count: 32)
        let account = Array(UInt8(0)..<32)
        var hasher = SEPCrypto.SHA256Hasher()
        hasher.update(data: blockSeed)
        hasher.update(data: account)

        let digest = hasher.finalize()
        XCTAssertEqual(digest.count, 32)
        XCTAssertEqual(digest.toHexadecimal, "7725306294e8338620ee3c11d848e50109216574c28ff140f603df24afd82366")
        XCTAssertEqual(digest, Data(SEPCrypto.SHA.sha256.digest(data: Data(blockSeed + account))))
    }
}
