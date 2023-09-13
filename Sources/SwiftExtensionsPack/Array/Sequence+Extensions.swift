import Foundation

// MARK: [1,2,3].join(", ") => "1, 2, 3"
public extension Sequence where Element: LosslessStringConvertible {
    func join(_ separator: String) -> String {
        var n = ""
        self.forEach { (number) in
            n.append(String(number))
            n.append(separator)
        }

        return String(n.dropLast(separator.count))
    }
}

public extension Sequence where Element: Hashable {
    func uniq() -> Self {
        return Array(Set(self)) as! Self
    }
}

public extension Sequence {
    func uniq<T: Hashable>(_ by: (Element) -> T) -> Self {
        var uniqueValues: [T: Element] = .init()
        forEach { uniqueValues[by($0)] = $0 }
        return uniqueValues.values.map { $0 } as! Self
    }
}
