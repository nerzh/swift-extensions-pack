import Foundation

extension Dictionary {

    func toJSON(options: JSONSerialization.WritingOptions = []) throws -> String? {
        let data = try JSONSerialization.data(withJSONObject: self, options: options)
        return String(data: data, encoding: .utf8)
    }

    func toJSONData(options: JSONSerialization.WritingOptions = []) throws -> Data {
        try JSONSerialization.data(withJSONObject: self, options: options)
    }
}
