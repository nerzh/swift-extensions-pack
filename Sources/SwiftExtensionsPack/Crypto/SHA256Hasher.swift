import Foundation
import Crypto

extension SEPCrypto {
    public struct SHA256Hasher {
        private var hasher = Crypto.SHA256()

        public init() {}

        public mutating func update<Bytes: DataProtocol>(data: Bytes) {
            hasher.update(data: data)
        }

        public mutating func update(data: [UInt8]) {
            data.withUnsafeBytes { hasher.update(bufferPointer: $0) }
        }

        public consuming func finalize() -> Data {
            Data(hasher.finalize())
        }
    }
}
