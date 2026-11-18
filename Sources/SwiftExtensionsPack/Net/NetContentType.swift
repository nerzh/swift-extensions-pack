import Foundation

// Parse HTTP media types without losing case-sensitive parameter values (RFC 9110, 8.3.1).
struct NetContentType: Equatable {
    private let type: String
    private let subtype: String
    private let parameters: [String: [UInt8]]

    init(_ value: String) throws {
        var parser = Parser(bytes: Array(value.utf8))
        guard parser.bytes.allSatisfy({ $0 == 9 || ($0 >= 32 && $0 != 127) }) else {
            throw Net.NetErrors.InvalidContentType(value)
        }
        parser.skipWhitespace()
        guard let type = parser.token(), parser.consume(47), let subtype = parser.token(),
              type != [42], subtype != [42] else {
            throw Net.NetErrors.InvalidContentType(value)
        }
        var parameters: [String: [UInt8]] = [:]
        while true {
            parser.skipWhitespace()
            if parser.current == nil { break }
            guard parser.consume(59) else { throw Net.NetErrors.InvalidContentType(value) }
            parser.skipWhitespace()
            // RFC 9110 permits empty parameters, including a trailing semicolon.
            if parser.current == nil || parser.current == 59 { continue }
            guard let name = parser.token(), parser.consume(61), let parameter = parser.parameterValue() else {
                throw Net.NetErrors.InvalidContentType(value)
            }
            let key = String(decoding: name, as: UTF8.self).lowercased()
            guard parameters[key] == nil else { throw Net.NetErrors.InvalidContentType(value) }
            parameters[key] = key == "charset"
                ? parameter.map { (65...90).contains($0) ? $0 + 32 : $0 }
                : parameter
        }
        self.type = String(decoding: type, as: UTF8.self).lowercased()
        self.subtype = String(decoding: subtype, as: UTF8.self).lowercased()
        self.parameters = parameters
    }

    private struct Parser {
        let bytes: [UInt8]
        var index = 0
        var current: UInt8? { index < bytes.count ? bytes[index] : nil }

        mutating func consume(_ byte: UInt8) -> Bool {
            guard current == byte else { return false }
            index += 1
            return true
        }

        mutating func skipWhitespace() {
            while current == 32 || current == 9 { index += 1 }
        }

        mutating func token() -> [UInt8]? {
            let start = index
            while let byte = current {
                switch byte {
                case 48...57, 65...90, 97...122, 33, 35...39, 42, 43, 45, 46, 94...96, 124, 126:
                    index += 1
                default:
                    return index > start ? Array(bytes[start..<index]) : nil
                }
            }
            return index > start ? Array(bytes[start..<index]) : nil
        }

        mutating func parameterValue() -> [UInt8]? {
            guard consume(34) else { return token() }
            var value: [UInt8] = []
            while let byte = current {
                index += 1
                if byte == 34 { return value }
                if byte == 92 {
                    guard let escaped = current else { return nil }
                    value.append(escaped)
                    index += 1
                } else {
                    value.append(byte)
                }
            }
            return nil
        }
    }
}
