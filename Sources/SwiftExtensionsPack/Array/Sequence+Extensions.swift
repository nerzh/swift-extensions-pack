import Foundation

// MARK: [1,2,3].join(", ") => "1, 2, 3"
extension Sequence where Element: LosslessStringConvertible {
    
    public func join(_ separator: String) -> String {
        var n = ""
        self.forEach { (number) in
            n.append(String(number))
            n.append(separator)
        }

        return String(n.dropLast(separator.count))
    }
}
