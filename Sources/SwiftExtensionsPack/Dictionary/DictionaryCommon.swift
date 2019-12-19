public func mergeOptionalDictionary<Key, Value>(_ left: [Key: Value]?, _ right: [Key: Value]?) -> [Key: Value] {
    let left = left ?? [:]
    let right = right ?? [:]

    return left.merging(right) { (_, value) in value }
}
