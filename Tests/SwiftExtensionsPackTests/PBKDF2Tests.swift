import Foundation
import XCTest
import SwiftExtensionsPack

final class PBKDF2Tests: XCTestCase {
    // Fixed independent oracles generated with Python 3.13 hashlib.pbkdf2_hmac
    // using OpenSSL 3.5.4, not CryptoExtras or CommonCrypto.
    func testKnownAnswers() throws {
        let vectors: [(iterations: Int, expected: String)] = [
            (1, """
                867f70cf1ade02cff3752599a3a53dc4af34c7a669815ae5d513554e1c8cf252c0\
                2d470a285a0501bad999bfe943c08f050235d7d68b1da55e63f73b60a57fce
                """),
            (2, """
                e1d9c16aa681708a45f5c7c4e215ceb66e011a2e9f0040713f18aefdb866d53cf\
                76cab2868a39b9f7840edce4fef5a82be67335c77a6068e04112754f27ccf4e
                """),
            (4096, """
                d197b1b33db0143e018b12f3d1d1479e6cdebdcc97c5c0f87f6902e072f457b514\
                3f30602641b3d55cd335988cb36b84376060ecd532e039b742a239434af2d5
                """)
        ]
        for vector in vectors {
            let key = try SEPCrypto.pbkdf2SHA512(
                password: Data("password".utf8), salt: Data("salt".utf8),
                iterations: vector.iterations, keyLength: 64
            )
            XCTAssertEqual(key.count, 64)
            XCTAssertEqual(key.toHexadecimal, vector.expected, "Iterations: \(vector.iterations)")
        }
    }

    func testTONParameters() throws {
        let vectors: [(salt: String, iterations: Int, expected: String)] = [
            ("TON fast seed", 1, """
                8b1fff4f172e2b9b00e9dba4f7b11f32af5690c799bc6f2684377c613b6de8e2\
                d6d700e1f977fce8dbbc94fb94725f75800bc28a29c46f0ce127e7537e15e480
                """),
            ("TON seed version", 390, """
                71476a91fb99d2d2a16630f048c10a7cc1c4a1d319c21f5034cec0a8e4d382ed4\
                ee1edd4ca86ad005c014f55fc99acd4896f7dc997b6d2f09ec3192b179ef445
                """),
            ("TON default seed", 100_000, """
                8b3eaefe15981d2eca6825d3363b1c2ddad4982806fc9cedfdce355e63bbd3ce9\
                bef04f9c7ca2f4c80b8f03ae82a558e0676efd7261012c9fa249efcd0a49460
                """)
        ]
        for vector in vectors {
            let key = try SEPCrypto.pbkdf2SHA512(
                password: Data(0..<64), salt: Data(vector.salt.utf8),
                iterations: vector.iterations, keyLength: 64
            )
            XCTAssertEqual(key.count, 64)
            XCTAssertEqual(key.toHexadecimal, vector.expected, vector.salt)
        }
    }

    func testBinaryAndEmptyInputsIncludingSlices() throws {
        let vectors: [(password: Data, salt: Data, iterations: Int, expected: String)] = [
            (Data("pass\0word".utf8), Data("sa\0lt".utf8), 4096, """
                9d9e9c4cd21fe4be24d5b8244c759665f39d98fc12a9ca759bb021db3cfadf345\
                844aebe70dd8b2f6966f25f3613e1187bbd24ed2ca43ed13b246e4675be7ab9
                """),
            (Data([0, 255, 128, 1, 0, 254]), Data([255, 0, 128, 0, 127]), 390, """
                cadf7e2655958ba9f96d223f247d11802a18c95e7d3935fc19a15bf49160f2e5\
                6efc47f051cf79b855fee400470de71dd458dfa3eecc725f84e896a7f5dcc5fc
                """),
            (Data(), Data(), 1, """
                6d2ecbbbfb2e6dcd7056faf9af6aa06eae594391db983279a6bf27e0eb2286143\
                ab0c996f33ca4b667e945829ea693340f2831797324e5f31df18ed171d18c97
                """),
            (Data(), Data("salt".utf8), 2, """
                cc5eacbb057f2a5982fce67bf70f79fccf4adf285f5cbae1a5a1c5df012a630a\
                5cd035da88803f2a8b7ad7d3118025e9d848280b733c39c57a76d3fa895f244c
                """),
            (Data("password".utf8), Data(), 2, """
                52b05e3b51893d18488808ece2a6b8bd4efcd00e48db982b03e5224d872aa523\
                1f3e7784e08601c80f90ce44099f5be47cfac9a140b778b989ff5746b09d97ab
                """),
            (Data(UInt8.min...UInt8.max), Data((UInt8.min...UInt8.max).reversed()), 2, """
                317e788fce737f4512535bc93fbbc3f70bb9b70c9772a41835a9fd6e34d333048\
                70721f23b4fb0406a4c9516aaddda3221d107a1635af29ee11f430bbf518fa0
                """)
        ]
        for (index, vector) in vectors.enumerated() {
            let passwordStorage = Data(repeating: 0xaa, count: 40) + vector.password
            let saltStorage = Data(repeating: 0xbb, count: 40) + vector.salt
            for password in [vector.password, passwordStorage.dropFirst(40)] {
                for salt in [vector.salt, saltStorage.dropFirst(40)] {
                    let key = try SEPCrypto.pbkdf2SHA512(
                        password: password, salt: salt, iterations: vector.iterations, keyLength: 64
                    )
                    XCTAssertEqual(key.count, 64)
                    XCTAssertEqual(key.toHexadecimal, vector.expected, "Vector: \(index)")
                }
            }
        }
    }

    func testResultLengthsInBytesAcrossSHA512Blocks() throws {
        let expected = try """
            e1d9c16aa681708a45f5c7c4e215ceb66e011a2e9f0040713f18aefdb866d53cf\
            76cab2868a39b9f7840edce4fef5a82be67335c77a6068e04112754f27ccf4e\
            473e311ad827b68945f4e2dddb204c78e40e2495141e411cd272d020640d673c\
            d34aa29f1e03c579d247bf63f041156031e0bf2e841c553c530933b48c40c865\
            a4
            """.dataFromHexThrowing()
        for length in [1, 16, 32, 63, 64, 65, 127, 128, 129] {
            let key = try SEPCrypto.pbkdf2SHA512(
                password: Data("password".utf8), salt: Data("salt".utf8),
                iterations: 2, keyLength: length
            )
            XCTAssertEqual(key.count, length)
            XCTAssertEqual(key, expected.prefix(length), "Length: \(length)")
        }
    }

    func testInvalidIterationsThrow() {
        let invalid = [Int.min, -1, 0]
            + [Int64(UInt32.max) + 1, Int64.max].compactMap { Int(exactly: $0) }
        for iterations in invalid {
            XCTAssertThrowsError(try SEPCrypto.pbkdf2SHA512(
                password: Data(), salt: Data(), iterations: iterations, keyLength: 64
            )) {
                XCTAssertEqual($0 as? SEPCrypto.PBKDF2Error, .invalidIterations(actual: iterations))
            }
        }
    }

    func testInvalidKeyLengthsThrowBeforeAllocating() {
        let invalid = [Int.min, -1, 0, Int.max / 8 + 1, Int.max]
            + [Int64(UInt32.max) + 1, Int64(UInt32.max) * 64 + 1].compactMap { Int(exactly: $0) }
        for keyLength in invalid {
            XCTAssertThrowsError(try SEPCrypto.pbkdf2SHA512(
                password: Data(), salt: Data(), iterations: 1, keyLength: keyLength
            )) {
                XCTAssertEqual($0 as? SEPCrypto.PBKDF2Error, .invalidKeyLength(actual: keyLength))
            }
        }
    }

    func testSHADigestsConvertToDataUsingPublicImports() {
        let input = Data("abc".utf8)
        let sha256 = Data(SEPCrypto.SHA.sha256.digest(data: input))
        let sha512 = Data(SEPCrypto.SHA.sha512.digest(data: input))
        XCTAssertEqual(sha256.count, 32)
        XCTAssertEqual(sha256.toHexadecimal, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        XCTAssertEqual(sha512.count, 64)
        XCTAssertEqual(sha512.toHexadecimal, """
            ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a\
            2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f
            """)
    }
}
