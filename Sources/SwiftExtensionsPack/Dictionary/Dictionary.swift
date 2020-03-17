import Foundation

extension Dictionary {

    public func toJSON(options: JSONSerialization.WritingOptions = []) throws -> String? {
        let data = try JSONSerialization.data(withJSONObject: self, options: options)
        return String(data: data, encoding: .utf8)
    }

    public func toJSONData(options: JSONSerialization.WritingOptions = []) throws -> Data {
        try JSONSerialization.data(withJSONObject: self, options: options)
    }
}
