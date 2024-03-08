import Foundation
import XCTest
@testable import SwiftExtensionsPack

final class swift_extensions_packTests: XCTestCase {
    
    func testHMAC() async throws {
        let digest = SEPCrypto.HMAC.sha512.digest(string: "password_string", key: "mnemonic_string")
        XCTAssertEqual(digest, "8c47a8d170288876da8e897eb0c4d4bbb299b1d3c23b96c70e41efb7597f3644438935b93e230ae203785f16ea327d7851180e036487aeac0124a8d51f10879a")
    }
}
