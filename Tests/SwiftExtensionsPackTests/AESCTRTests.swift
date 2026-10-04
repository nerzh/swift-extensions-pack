import Foundation
import XCTest
import SwiftExtensionsPack

final class AESCTRTests: XCTestCase {
    private typealias AESCTR = SEPCrypto.AESCTR

    // NIST SP 800-38A, sections F.5.1-F.5.6 (AES-128, AES-192, AES-256).
    // https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-38a.pdf
    private let plaintext = """
        6bc1bee22e409f96e93d7e117393172a\
        ae2d8a571e03ac9c9eb76fac45af8e51\
        30c81c46a35ce411e5fbc1191a0a52ef\
        f69f2445df4f9b17ad2b417be66c3710
        """
    private let iv = "f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff"
    private let vectors: [(key: String, ciphertext: String)] = [
        (
            "2b7e151628aed2a6abf7158809cf4f3c",
            """
            874d6191b620e3261bef6864990db6ce\
            9806f66b7970fdff8617187bb9fffdff\
            5ae4df3edbd5d35e5b4f09020db03eab\
            1e031dda2fbe03d1792170a0f3009cee
            """
        ),
        (
            "8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b",
            """
            1abc932417521ca24f2b0459fe7e6e0b\
            090339ec0aa6faefd5ccc2c6f4ce8e94\
            1e36b26bd1ebc670d1bd1d665620abf7\
            4f78a7f6d29809585a97daec58c6b050
            """
        ),
        (
            "603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4",
            """
            601ec313775789a5b7a7f504bbf3d228\
            f443e3ca4d62b59aca84e990cacaf5c5\
            2b0930daa23de94ce87017ba2d84988d\
            dfc9c58db67aada613c2dd08457941a6
            """
        )
    ]

    // Independent LibreSSL 3.3.6 AES-256-ECB encryption of explicit counter blocks.
    // Each vector starts at the given IV and contains four successive counters.
    private let carryVectors: [(iv: String, keystream: String)] = [
        (
            "0102030405060708090a0b0cfffffffe",
            """
            1ccb7441ad8a90067a4eddcb4788b39e\
            f249081410eaa514f6d1ce092d7e384d\
            b4f9683268a489adc6e5642bfdc47d6c\
            e9d3ec405b1e68ff188802dbc493fa74
            """
        ),
        (
            "0102030405060708fffffffffffffffe",
            """
            27130fc91d62ec45c3f23b716912c933\
            cc832ea242a984d3c4c4d8089c0c4cc3\
            16fa19273ace87f3b83601e02245f14d\
            4b673a388d251b6c4231672a591c3de0
            """
        )
    ]
    // The same independent ECB oracle for counters 2^128 - 2 and 2^128 - 1.
    private let finalKeystream = "4f9db742155ac502c2ae28023b3336e43b3c2921c85a24de9ac606ce6d1d60cc"

    func testNISTEncryptionAndDecryption() throws {
        let plaintext = try plaintext.dataFromHexThrowing()
        let iv = try iv.dataFromHexThrowing()
        for vector in vectors {
            let key = try vector.key.dataFromHexThrowing()
            let ciphertext = try vector.ciphertext.dataFromHexThrowing()
            let encryptor = try AESCTR(key: key, iv: iv)
            let decryptor = try AESCTR(key: key, iv: iv)
            XCTAssertEqual(try encryptor.update(data: plaintext), ciphertext)
            XCTAssertEqual(try decryptor.update(data: ciphertext), plaintext)
        }
    }

    func testEverySplitPositionAndEmptyParts() throws {
        let plaintext = try plaintext.dataFromHexThrowing()
        let iv = try iv.dataFromHexThrowing()
        for vector in vectors {
            let key = try vector.key.dataFromHexThrowing()
            let ciphertext = try vector.ciphertext.dataFromHexThrowing()
            for split in 0...plaintext.count {
                let chunks = [0, split, 0, plaintext.count - split, 0]
                try assertChunks(plaintext, expected: ciphertext, key: key, iv: iv, sizes: chunks)
                try assertChunks(ciphertext, expected: plaintext, key: key, iv: iv, sizes: chunks)
            }
        }
    }

    func testBytewiseProcessingAndBlockBoundaries() throws {
        let plaintext = try plaintext.dataFromHexThrowing()
        let iv = try iv.dataFromHexThrowing()
        let partitions = [
            Array(repeating: [0, 1], count: 64).flatMap { $0 },
            [16, 16, 16, 16],
            [15, 1, 0, 1, 15, 17, 15],
            [1, 14, 2, 14, 2, 14, 2, 15]
        ]
        for vector in vectors {
            let key = try vector.key.dataFromHexThrowing()
            let ciphertext = try vector.ciphertext.dataFromHexThrowing()
            for chunks in partitions {
                try assertChunks(plaintext, expected: ciphertext, key: key, iv: iv, sizes: chunks)
                try assertChunks(ciphertext, expected: plaintext, key: key, iv: iv, sizes: chunks)
            }
        }
    }

    func testEveryPrefixLengthWithoutPadding() throws {
        let plaintext = try plaintext.dataFromHexThrowing()
        let iv = try iv.dataFromHexThrowing()
        for vector in vectors {
            let key = try vector.key.dataFromHexThrowing()
            let ciphertext = try vector.ciphertext.dataFromHexThrowing()
            for count in 0...plaintext.count {
                try assertChunks(plaintext.prefix(count), expected: ciphertext.prefix(count), key: key, iv: iv, sizes: [count])
                try assertChunks(ciphertext.prefix(count), expected: plaintext.prefix(count), key: key, iv: iv, sizes: [count])
            }
        }
    }

    func testDataSlicesForKeyIVAndMessage() throws {
        for vector in vectors {
            let keyStorage = Data(repeating: 0xaa, count: 40) + (try vector.key.dataFromHexThrowing())
            let ivStorage = Data(repeating: 0xbb, count: 40) + (try iv.dataFromHexThrowing())
            let plaintextStorage = Data(repeating: 0xcc, count: 40) + (try plaintext.dataFromHexThrowing())
            let ciphertextStorage = Data(repeating: 0xdd, count: 40) + (try vector.ciphertext.dataFromHexThrowing())
            let key = keyStorage.dropFirst(40)
            let iv = ivStorage.dropFirst(40)
            let plaintext = plaintextStorage.dropFirst(40)
            let ciphertext = ciphertextStorage.dropFirst(40)
            for slice in [key, iv, plaintext, ciphertext] {
                XCTAssertEqual(slice.startIndex, 40)
            }
            for chunks in [[0, 64], [1, 0, 14, 17, 0, 32], Array(repeating: 1, count: 64)] {
                try assertChunks(plaintext, expected: ciphertext, key: key, iv: iv, sizes: chunks)
                try assertChunks(ciphertext, expected: plaintext, key: key, iv: iv, sizes: chunks)
            }
        }
    }

    func testInvalidKeyLengthsIncludingSlices() throws {
        let iv = try iv.dataFromHexThrowing()
        for count in [0, 1, 12, 15, 17, 23, 25, 31, 33, 64] {
            let storage = Data(repeating: 0, count: 40 + count)
            for key in [Data(repeating: 0, count: count), storage.dropFirst(40)] {
                XCTAssertThrowsError(try AESCTR(key: key, iv: iv)) {
                    XCTAssertEqual($0 as? AESCTR.StreamError, .invalidKeyLength(actual: count))
                    XCTAssertTrue($0.localizedDescription.contains("16, 24, or 32"))
                    XCTAssertTrue($0.localizedDescription.contains("received \(count)"))
                }
            }
        }
    }

    func testInvalidIVLengthsIncludingSlices() throws {
        let key = try vectors[2].key.dataFromHexThrowing()
        for count in [0, 1, 12, 15, 17, 24, 32] {
            let storage = Data(repeating: 0, count: 40 + count)
            for iv in [Data(repeating: 0, count: count), storage.dropFirst(40)] {
                XCTAssertThrowsError(try AESCTR(key: key, iv: iv)) {
                    XCTAssertEqual($0 as? AESCTR.StreamError, .invalidIVLength(actual: count))
                    XCTAssertTrue($0.localizedDescription.contains("exactly 16"))
                    XCTAssertTrue($0.localizedDescription.contains("received \(count)"))
                }
            }
        }
    }

    func testCounterCarryAcross32And64Bits() throws {
        let key = try vectors[2].key.dataFromHexThrowing()
        for vector in carryVectors {
            let iv = try vector.iv.dataFromHexThrowing()
            let expected = try vector.keystream.dataFromHexThrowing()
            let input = Data(repeating: 0, count: expected.count)
            for split in 0...input.count {
                let chunks = [split, 0, input.count - split]
                try assertChunks(input, expected: expected, key: key, iv: iv, sizes: chunks)
                try assertChunks(expected, expected: input, key: key, iv: iv, sizes: chunks)
            }
            for chunks in [[16, 16, 16, 16], Array(repeating: 1, count: 64)] {
                try assertChunks(input, expected: expected, key: key, iv: iv, sizes: chunks)
                try assertChunks(expected, expected: input, key: key, iv: iv, sizes: chunks)
            }
        }
    }

    func testLargeUpdatesAndCounterAddition() throws {
        let key = try vectors[2].key.dataFromHexThrowing()
        let iv = try carryVectors[0].iv.dataFromHexThrowing()
        let input = Data(repeating: 0, count: 16417)
        let stream = try AESCTR(key: key, iv: iv)
        let ciphertext = try stream.update(data: input)
        // SHA-256 of LibreSSL 3.3.6 enc -aes-256-ctr output for this key, IV and input.
        XCTAssertEqual(
            Data(SEPCrypto.SHA.sha256.digest(data: ciphertext)).toHexadecimal,
            "a51466de7bdc75859eab0ef1f21c4e7937913023e30afb2d8f7c71fc3e47b93f"
        )
        for chunks in [[4096, 4096, 4096, 4096, 33], [1, 4095, 17, 4097, 8207], Array(repeating: 1, count: input.count)] {
            try assertChunks(input, expected: ciphertext, key: key, iv: iv, sizes: chunks)
            try assertChunks(ciphertext, expected: input, key: key, iv: iv, sizes: chunks)
        }
    }

    func testFinalCounterCanBeConsumedAtEverySplit() throws {
        let key = try vectors[2].key.dataFromHexThrowing()
        let expected = try finalKeystream.dataFromHexThrowing()
        for availableBytes in [16, 32] {
            var iv = Data(repeating: 0xff, count: 16)
            if availableBytes == 32 { iv[15] = 0xfe }
            let input = Data(repeating: 0, count: availableBytes)
            let ciphertext = expected.suffix(availableBytes)
            for (message, result) in [(input, ciphertext), (ciphertext, input)] {
                for split in 0...availableBytes {
                    let stream = try AESCTR(key: key, iv: iv)
                    let first = try stream.update(data: message.prefix(split))
                    XCTAssertEqual(try stream.update(data: Data()), Data())
                    let second = try stream.update(data: message.dropFirst(split))
                    XCTAssertEqual(first + second, result)
                    XCTAssertEqual(try stream.update(data: Data()), Data())
                    for _ in 0..<2 {
                        XCTAssertThrowsError(try stream.update(data: Data([0]))) {
                            XCTAssertEqual($0 as? AESCTR.StreamError, .counterExhausted)
                            XCTAssertEqual($0.localizedDescription, "The AES-CTR 128-bit counter is exhausted.")
                        }
                    }
                }
            }
        }
    }

    func testExhaustionDoesNotConsumeStateOrBufferedKeystream() throws {
        let key = try vectors[2].key.dataFromHexThrowing()
        let expected = try finalKeystream.dataFromHexThrowing()
        for availableBytes in [16, 32] {
            var iv = Data(repeating: 0xff, count: 16)
            if availableBytes == 32 { iv[15] = 0xfe }
            for consumed in 0..<availableBytes {
                let stream = try AESCTR(key: key, iv: iv)
                let first = try stream.update(data: Data(repeating: 0, count: consumed))
                XCTAssertThrowsError(try stream.update(data: Data(repeating: 0, count: availableBytes - consumed + 1))) {
                    XCTAssertEqual($0 as? AESCTR.StreamError, .counterExhausted)
                }
                XCTAssertEqual(try stream.update(data: Data()), Data())
                let remaining = try stream.update(data: Data(repeating: 0, count: availableBytes - consumed))
                XCTAssertEqual(first + remaining, expected.suffix(availableBytes))
            }
        }
    }

    func testExistingGCMAndStringMethodsRemainCompatible() throws {
        let key = try vectors[2].key.dataFromHexThrowing()
        let plaintext = try plaintext.dataFromHexThrowing()
        let encrypted = try SEPCrypto.encryptAES256GCM(data: plaintext, key: key)
        XCTAssertEqual(try SEPCrypto.decryptAES256GCM(data: encrypted, key: key), plaintext)
        let encryptedString: String = try "AES compatibility".encryptAES256(key: key)
        let decryptedString: String = try encryptedString.decryptAES256(key: key)
        XCTAssertEqual(decryptedString, "AES compatibility")
    }

    private func assertChunks(
        _ input: Data,
        expected: Data,
        key: Data,
        iv: Data,
        sizes: [Int],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        XCTAssertEqual(sizes.reduce(0, +), input.count, file: file, line: line)
        let stream = try AESCTR(key: key, iv: iv)
        var output = Data()
        var index = input.startIndex
        for size in sizes {
            let part = try stream.update(data: input[index..<(index + size)])
            XCTAssertEqual(part.count, size, file: file, line: line)
            output.append(part)
            index += size
        }
        XCTAssertEqual(output, expected, file: file, line: line)
    }
}
