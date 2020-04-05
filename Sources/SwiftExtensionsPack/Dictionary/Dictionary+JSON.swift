
import Foundation

extension Dictionary {

    public func toJSON(options: JSONSerialization.WritingOptions = []) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: self, options: options)
        guard let string = String(data: data, encoding: .utf8) else { fatalError("Can't convert data to string") }

        return string
    }

    public func toJSONData(options: JSONSerialization.WritingOptions = []) throws -> Data {
        try JSONSerialization.data(withJSONObject: self, options: options)
    }
}
