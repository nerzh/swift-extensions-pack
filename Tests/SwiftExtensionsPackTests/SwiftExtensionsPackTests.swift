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
}
