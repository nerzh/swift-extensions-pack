import SwiftExtensionsPack
import XCTest

private func requireSendable<T: Sendable & ~Copyable>(_ value: borrowing T) {}

private struct SendableBoxHolder: ~Copyable, Sendable {
    var box: Box<[UInt8]>
}

private actor BoxReceiver {
    func append(_ box: consuming Box<[UInt8]>, byte: UInt8) -> [UInt8] {
        var owned = consume box
        owned.value.append(byte)
        return owned.value
    }
}

final class MemoryTests: XCTestCase {
    func testBoxWithSendablePayloadSatisfiesSendableConstraint() {
        let box = Box([UInt8(1), 2, 3])
        requireSendable(box)

        let holder = SendableBoxHolder(box: consume box)
        requireSendable(holder)
        XCTAssertEqual(holder.box.value, [1, 2, 3])
    }

    @MainActor
    func testBoxMovesToActorWithoutChangingItsExplicitCopy() async {
        var original = Box([UInt8(1), 2, 3])
        let copy = original.copy()
        original.value[0] = 9

        let receiver = BoxReceiver()
        let result = await receiver.append(consume copy, byte: 4)

        XCTAssertEqual(result, [1, 2, 3, 4])
        XCTAssertEqual(original.value, [9, 2, 3])
    }
}
