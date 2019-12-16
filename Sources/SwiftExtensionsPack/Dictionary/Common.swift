func mergeOptionalDictionary<Key, Value>(left: [Key: Value]?, right: [Key: Value]?) -> [Key: Value] {
    let left = left ?? [:]
    let right = right ?? [:]

    return left.merging(right) { (_, value) in value }
}
