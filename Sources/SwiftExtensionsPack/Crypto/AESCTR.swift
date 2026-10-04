import Foundation
import Crypto
import CryptoExtras

extension SEPCrypto {
    public final class AESCTR {
        public enum StreamError: Error, LocalizedError, Equatable {
            case invalidKeyLength(actual: Int)
            case invalidIVLength(actual: Int)
            case counterExhausted

            public var errorDescription: String? {
                switch self {
                case .invalidKeyLength(let actual):
                    return "An AES key must contain 16, 24, or 32 bytes; received \(actual)."
                case .invalidIVLength(let actual):
                    return "An AES-CTR initial counter must contain exactly 16 bytes; received \(actual)."
                case .counterExhausted:
                    return "The AES-CTR 128-bit counter is exhausted."
                }
            }
        }

        private let key: SymmetricKey
        // The next unused counter, unless counterExhausted is true.
        private var counter: [UInt8]
        private var counterExhausted = false
        private var keystream = Data()
        private var keystreamOffset = 0

        public init(key: Data, iv: Data) throws {
            guard [16, 24, 32].contains(key.count) else {
                throw StreamError.invalidKeyLength(actual: key.count)
            }
            guard iv.count == 16 else {
                throw StreamError.invalidIVLength(actual: iv.count)
            }
            self.key = SymmetricKey(data: key)
            self.counter = iv.bytes
        }

        // Encryption and decryption use the same operation, on separate instances.
        // Calls on each instance must be sequential.
        public func update(data: Data) throws -> Data {
            guard !data.isEmpty else { return Data() }

            let bufferedCount = min(data.count, keystream.count - keystreamOffset)
            let newByteCount = data.count - bufferedCount
            let newBlockCount = newByteCount / 16 + (newByteCount % 16 == 0 ? 0 : 1)
            if newBlockCount > 0 {
                var lastCounter = counter
                guard !counterExhausted,
                      !Self.advanceCounter(&lastCounter, by: newBlockCount - 1) else {
                    throw StreamError.counterExhausted
                }
            }

            // Commit state only after the whole update succeeds.
            var counter = self.counter
            var counterExhausted = self.counterExhausted
            var keystream = self.keystream
            var keystreamOffset = self.keystreamOffset
            var output = Data()
            output.reserveCapacity(data.count)
            var index = data.startIndex

            for offset in 0..<bufferedCount {
                output.append(data[index + offset] ^ keystream[keystreamOffset + offset])
            }
            index += bufferedCount
            keystreamOffset += bufferedCount

            // Process aligned data in bulk without retaining any previous input.
            let fullByteCount = (data.endIndex - index) / 16 * 16
            if fullByteCount > 0 {
                output.append(try Self.crypt(data[index..<(index + fullByteCount)], key: key, counter: counter))
                counterExhausted = Self.advanceCounter(&counter, by: fullByteCount / 16)
                index += fullByteCount
            }

            if index < data.endIndex {
                keystream = try Self.crypt(Data(repeating: 0, count: 16), key: key, counter: counter)
                counterExhausted = Self.advanceCounter(&counter, by: 1)
                keystreamOffset = data.endIndex - index
                for offset in 0..<keystreamOffset {
                    output.append(data[index + offset] ^ keystream[offset])
                }
            }

            self.counter = counter
            self.counterExhausted = counterExhausted
            self.keystream = keystream
            self.keystreamOffset = keystreamOffset
            return output
        }

        private static func crypt(_ data: Data, key: SymmetricKey, counter: [UInt8]) throws -> Data {
            try AES._CTR.encrypt(data, using: key, nonce: AES._CTR.Nonce(nonceBytes: counter))
        }

        // Add a block count to the full big-endian counter, reporting overflow.
        private static func advanceCounter(_ counter: inout [UInt8], by blockCount: Int) -> Bool {
            var carry = blockCount
            for index in counter.indices.reversed() {
                let sum = Int(counter[index]) + (carry & 0xff)
                counter[index] = UInt8(truncatingIfNeeded: sum)
                carry = (carry >> 8) + (sum >> 8)
            }
            return carry != 0
        }
    }
}
