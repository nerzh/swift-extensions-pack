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
    }
    
    func testRandom() async throws {
        for _ in 0...100000 {
            let num1 = randomNumber(min: 3, max: 4)
            XCTAssertTrue(num1 >= 3)
            XCTAssertTrue(num1 <= 4)
            
            let num2 = randomNumber(min: 0, max: UInt.max)
            XCTAssertTrue(num2 >= 0)
            XCTAssertTrue(num2 <= UInt.max - 1)
        }
    }
}
