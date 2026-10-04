import Foundation
import XCTest
import SwiftExtensionsPack

final class Ed25519ConversionTests: XCTestCase {
    private typealias Ed25519 = SEPCrypto.Ed25519

    // Fixed outputs from libsodium 1.0.20; never computed by the implementation under test.
    // Seeds 1 and 2 are from RFC 8032 section 7.1. Seed 3 is from libsodium's
    // test/default/ed25519_convert.c; its scalar and u match ed25519_convert.exp.
    // https://www.rfc-editor.org/rfc/rfc8032#section-7.1
    // https://github.com/jedisct1/libsodium/blob/1.0.20/test/default/ed25519_convert.c
    // https://github.com/jedisct1/libsodium/blob/1.0.20/test/default/ed25519_convert.exp
    // Scalars and coordinates were generated with crypto_sign_ed25519_sk_to_curve25519
    // and crypto_sign_ed25519_pk_to_curve25519; the shared secret uses crypto_scalarmult_curve25519.
    // The last two seeds are LE16(412) / LE16(687) followed by 30 zero bytes, selected
    // independently with libsodium for trailing / leading zero output bytes.
    private let vectors: [(seed: String, edwards: String, scalar: String, montgomery: String)] = [
        (
            "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60",
            "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
            "307c83864f2833cb427a2ef1c00a013cfdff2768d980c0a3a520f006904de94f",
            "d85e07ec22b0ad881537c2f44d662d1a143cf830c57aca4305d85c7a90f6b62e"
        ),
        (
            "4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb",
            "3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c",
            "68bd9ed75882d52815a97585caf4790a7f6c6b3b7f821c5e259a24b02e502e51",
            "25c704c594b88afc00a76b69d1ed2b984d7e22550f3ed0802d04fbcd07d38d47"
        ),
        (
            "421151a459faeade3d247115f94aedae42318124095afabe4d1451a559faedee",
            "b5076a8474a832daee4dd5b4040983b6623b5f344aca57d4d6ee4baf3f259e6e",
            "8052030376d47112be7f73ed7a019293dd12ad910b654455798b4667d73de166",
            "f1814f0e8ff1043d8a44d25babff3cedcae6c22c3edaa48f857ae70de2baae50"
        ),
        (
            "9c01000000000000000000000000000000000000000000000000000000000000",
            "3d6667ad6563d16322f78151c2297aa14ef9f14f71474b8b5bac26e10e5a1f0e",
            "c0f6058d193dd8d6f73a05d7be7341d0a74de1b28c10215a5be7d410e8f46774",
            "16d2641b053ed2c03780bbd486d574a14e4eb91093d0bcec0f31e29614a8c400"
        ),
        (
            "af02000000000000000000000000000000000000000000000000000000000000",
            "5c7d6f92272e35e71f770451cfef08fc540b68dfe0e1fdb6f2fd63bb5476682e",
            "a882409877c53c19a708063db684943c0f7a7e0f7e53bc756987d44271edbd59",
            "00681400f4ff422c9e7caaa3456ff8ce1b9a4cea2234a896efd04e3c4c884c5e"
        )
    ]

    // crypto_scalarmult_curve25519(aliceScalar, bobU), also verified in reverse.
    private let sharedSecret = "5166f24a6918368e2af831a4affadd97af0ac326bdf143596c045967cc00230e"

    func testConversionMatchesLibsodiumForBothSignBits() throws {
        for vector in vectors {
            let original = try vector.edwards.dataFromHexThrowing()
            let expected = try vector.montgomery.dataFromHexThrowing()
            for sign: UInt8 in [0, 0x80] {
                var encoded = original
                encoded[31] = (encoded[31] & 0x7f) | sign
                let result = try Ed25519.edwardsToMontgomery(bytesData: encoded)
                XCTAssertEqual(result.count, 32)
                XCTAssertEqual(result, expected)
            }
        }
    }

    func testSerializationPreservesZeroBytesAtBothEnds() throws {
        let trailingZero = try Ed25519.edwardsToMontgomery(bytesData: vectors[3].edwards.dataFromHexThrowing())
        let leadingZero = try Ed25519.edwardsToMontgomery(bytesData: vectors[4].edwards.dataFromHexThrowing())
        XCTAssertEqual(trailingZero.count, 32)
        XCTAssertEqual(trailingZero.last, 0)
        XCTAssertEqual(trailingZero.toHexadecimal, vectors[3].montgomery)
        XCTAssertEqual(leadingZero.count, 32)
        XCTAssertEqual(leadingZero.first, 0)
        XCTAssertEqual(leadingZero[3], 0)
        XCTAssertEqual(leadingZero.toHexadecimal, vectors[4].montgomery)
    }

    func testEdwardsBasePointMapsToNineWithFixedWidth() throws {
        // Standard Ed25519 base point y = 4/5 gives Montgomery u = 9.
        let basePoint = try "5866666666666666666666666666666666666666666666666666666666666666".dataFromHexThrowing()
        XCTAssertEqual(
            try Ed25519.edwardsToMontgomery(bytesData: basePoint),
            Data([9] + [UInt8](repeating: 0, count: 31))
        )
    }

    func testCoordinateConversionDoesNotClaimPointOrSubgroupValidation() throws {
        // Algebraic coordinate vectors, intentionally outside libsodium's stricter
        // point/subgroup acceptance policy: y = 0 -> 1, y = 2 -> p - 3, y = p - 1 -> 0.
        let coordinates: [(String, String)] = [
            ("0000000000000000000000000000000000000000000000000000000000000000",
             "0100000000000000000000000000000000000000000000000000000000000000"),
            ("0200000000000000000000000000000000000000000000000000000000000000",
             "eaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f"),
            ("ecffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f",
             "0000000000000000000000000000000000000000000000000000000000000000")
        ]
        for (edwards, montgomery) in coordinates {
            let result = try Ed25519.edwardsToMontgomery(bytesData: edwards.dataFromHexThrowing())
            XCTAssertEqual(result.count, 32)
            XCTAssertEqual(result.toHexadecimal, montgomery)
        }
    }

    func testRejectsShortAndOversizedInputs() throws {
        let publicKey = try vectors[0].edwards.dataFromHexThrowing()
        let scalar = try vectors[0].scalar.dataFromHexThrowing()
        for count in Array(0..<32) + [33, 64, 1024] {
            let invalid = Data(repeating: 0, count: count)
            XCTAssertThrowsError(try Ed25519.edwardsToMontgomery(bytesData: invalid)) {
                XCTAssertEqual($0 as? Ed25519.KeyError, .invalidPublicKeyLength(actual: count))
            }
            XCTAssertThrowsError(try Ed25519.getKeyExchange(privateKey: scalar, publicKey: invalid)) {
                XCTAssertEqual($0 as? Ed25519.KeyError, .invalidPublicKeyLength(actual: count))
            }
            XCTAssertThrowsError(try Ed25519.getKeyExchange(privateKey: invalid, publicKey: publicKey)) {
                XCTAssertEqual($0 as? Ed25519.KeyError, .invalidPrivateKeyLength(actual: count))
            }
        }
    }

    func testConversionAndExchangeAcceptDataSlices() throws {
        for offset in [1, 40, 128] {
            let publicStorage = Data(repeating: 0xaa, count: offset)
                + (try vectors[1].edwards.dataFromHexThrowing()) + Data([0xbb])
            let scalarStorage = Data(repeating: 0xcc, count: offset)
                + (try vectors[0].scalar.dataFromHexThrowing()) + Data([0xdd])
            let publicSlice = publicStorage[offset..<(offset + 32)]
            let scalarSlice = scalarStorage[offset..<(offset + 32)]
            XCTAssertEqual(publicSlice.startIndex, offset)
            XCTAssertEqual(scalarSlice.startIndex, offset)
            XCTAssertEqual(
                try Ed25519.edwardsToMontgomery(bytesData: publicSlice).toHexadecimal,
                vectors[1].montgomery
            )
            XCTAssertEqual(
                try Ed25519.getKeyExchange(privateKey: scalarSlice, publicKey: publicSlice).toHexadecimal,
                sharedSecret
            )
        }
    }

    func testRejectsInvalidLengthDataSlices() throws {
        let storage = Data(repeating: 0, count: 100)
        let scalar = try vectors[0].scalar.dataFromHexThrowing()
        let publicKey = try vectors[0].edwards.dataFromHexThrowing()
        for count in [0, 31, 33] {
            let slice = storage[40..<(40 + count)]
            XCTAssertEqual(slice.startIndex, 40)
            XCTAssertThrowsError(try Ed25519.edwardsToMontgomery(bytesData: slice)) {
                XCTAssertEqual($0 as? Ed25519.KeyError, .invalidPublicKeyLength(actual: count))
            }
            XCTAssertThrowsError(try Ed25519.getKeyExchange(privateKey: scalar, publicKey: slice)) {
                XCTAssertEqual($0 as? Ed25519.KeyError, .invalidPublicKeyLength(actual: count))
            }
            XCTAssertThrowsError(try Ed25519.getKeyExchange(privateKey: slice, publicKey: publicKey)) {
                XCTAssertEqual($0 as? Ed25519.KeyError, .invalidPrivateKeyLength(actual: count))
            }
        }
    }

    func testRejectsAllNoncanonicalYEncodingsWithEitherSign() throws {
        let scalar = try vectors[0].scalar.dataFromHexThrowing()
        // All 19 noncanonical y encodings: p through 2^255 - 1.
        for lowByte in UInt8(0xed)...UInt8(0xff) {
            for sign: UInt8 in [0, 0x80] {
                var encoded = Data(repeating: 0xff, count: 32)
                encoded[0] = lowByte
                encoded[31] = 0x7f | sign
                XCTAssertThrowsError(try Ed25519.edwardsToMontgomery(bytesData: encoded)) {
                    XCTAssertEqual($0 as? Ed25519.KeyError, .nonCanonicalYCoordinate)
                }
                XCTAssertThrowsError(try Ed25519.getKeyExchange(privateKey: scalar, publicKey: encoded)) {
                    XCTAssertEqual($0 as? Ed25519.KeyError, .nonCanonicalYCoordinate)
                }
            }
        }
    }

    func testRejectsUndefinedConversionWithEitherSign() throws {
        let scalar = try vectors[0].scalar.dataFromHexThrowing()
        for sign: UInt8 in [0, 0x80] {
            var identity = Data(repeating: 0, count: 32)
            identity[0] = 1
            identity[31] = sign
            XCTAssertThrowsError(try Ed25519.edwardsToMontgomery(bytesData: identity)) {
                XCTAssertEqual($0 as? Ed25519.KeyError, .undefinedMontgomeryCoordinate)
            }
            XCTAssertThrowsError(try Ed25519.getKeyExchange(privateKey: scalar, publicKey: identity)) {
                XCTAssertEqual($0 as? Ed25519.KeyError, .undefinedMontgomeryCoordinate)
            }
        }
    }

    func testRejectsInvalidCoordinatesInDataSlices() throws {
        let scalar = try vectors[0].scalar.dataFromHexThrowing()
        let invalidCoordinates: [(String, Ed25519.KeyError)] = [
            ("edffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f", .nonCanonicalYCoordinate),
            ("0100000000000000000000000000000000000000000000000000000000000080", .undefinedMontgomeryCoordinate)
        ]
        for (hex, expectedError) in invalidCoordinates {
            let storage = Data(repeating: 0xaa, count: 40) + (try hex.dataFromHexThrowing())
            let slice = storage[40..<72]
            XCTAssertEqual(slice.startIndex, 40)
            XCTAssertThrowsError(try Ed25519.edwardsToMontgomery(bytesData: slice)) {
                XCTAssertEqual($0 as? Ed25519.KeyError, expectedError)
            }
            XCTAssertThrowsError(try Ed25519.getKeyExchange(privateKey: scalar, publicKey: slice)) {
                XCTAssertEqual($0 as? Ed25519.KeyError, expectedError)
            }
        }
    }

    func testPreparedScalarsMatchIndependentVectorsWithoutRehashing() throws {
        for vector in vectors {
            let seed = try vector.seed.dataFromHexThrowing()
            let pair = Ed25519.createKeyPair(seed32Byte: seed)
            XCTAssertEqual(pair.public.toHexadecimal, vector.edwards)
            XCTAssertEqual(pair.secret.count, 64)
            XCTAssertEqual(pair.secret.prefix(32).toHexadecimal, vector.scalar)
            XCTAssertEqual(Ed25519.convertEd25519ToX25519(ed25519PrivateKey: seed).toHexadecimal, vector.scalar)
        }
    }

    func testSharedSecretMatchesLibsodiumInBothDirections() throws {
        let aliceScalar = try vectors[0].scalar.dataFromHexThrowing()
        let bobScalar = try vectors[1].scalar.dataFromHexThrowing()
        for sign: UInt8 in [0, 0x80] {
            var alicePublic = try vectors[0].edwards.dataFromHexThrowing()
            var bobPublic = try vectors[1].edwards.dataFromHexThrowing()
            alicePublic[31] = (alicePublic[31] & 0x7f) | sign
            bobPublic[31] = (bobPublic[31] & 0x7f) | sign
            let ab = try Ed25519.getKeyExchange(privateKey: aliceScalar, publicKey: bobPublic)
            let ba = try Ed25519.getKeyExchange(privateKey: bobScalar, publicKey: alicePublic)
            XCTAssertEqual(ab.count, 32)
            XCTAssertEqual(ba.count, 32)
            XCTAssertEqual(ab.toHexadecimal, sharedSecret)
            XCTAssertEqual(ba.toHexadecimal, sharedSecret)
        }
    }

    func testExchangeWithExpandedSecretPrefixAndSeedDerivedScalar() throws {
        let alice = Ed25519.createKeyPair(seed32Byte: try vectors[0].seed.dataFromHexThrowing())
        let bob = Ed25519.createKeyPair(seed32Byte: try vectors[1].seed.dataFromHexThrowing())
        // Exercise both supported representations from the README against the fixed oracle.
        let ab = try Ed25519.getKeyExchange(privateKey: alice.secret.prefix(32), publicKey: bob.public)
        let bobScalar = Ed25519.convertEd25519ToX25519(ed25519PrivateKey: try vectors[1].seed.dataFromHexThrowing())
        let ba = try Ed25519.getKeyExchange(privateKey: bobScalar, publicKey: alice.public)
        XCTAssertEqual(ab.toHexadecimal, sharedSecret)
        XCTAssertEqual(ba.toHexadecimal, sharedSecret)
        // Expanded secrets must be selected explicitly, never silently truncated.
        XCTAssertThrowsError(try Ed25519.getKeyExchange(privateKey: alice.secret, publicKey: bob.public)) {
            XCTAssertEqual($0 as? Ed25519.KeyError, .invalidPrivateKeyLength(actual: 64))
        }
    }

    func testExchangeRejectsZeroSharedSecret() throws {
        let scalar = try vectors[0].scalar.dataFromHexThrowing()
        for hex in [
            "0000000000000000000000000000000000000000000000000000000000000000",
            "ecffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f"
        ] {
            let publicKey = try hex.dataFromHexThrowing()
            XCTAssertThrowsError(try Ed25519.getKeyExchange(privateKey: scalar, publicKey: publicKey)) {
                XCTAssertEqual($0 as? Ed25519.KeyError, .zeroSharedSecret)
            }
        }
    }
}
