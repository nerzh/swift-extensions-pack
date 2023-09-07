//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 01.09.2023.
//

import Foundation

final public class SafeDictionary<Key: Hashable, Value>: CustomStringConvertible, CustomDebugStringConvertible, @unchecked Sendable {
    
    private let lock: NSLock = .init()
    private var dictionary: Dictionary<Key, Value>
    public var description: String { dictionary.description }
    public var debugDescription: String { dictionary.debugDescription }
    
    public init() {
        dictionary = .init()
    }
    
    public init(minimumCapacity: Int) {
        dictionary = Dictionary<Key, Value>(minimumCapacity: minimumCapacity)
    }
    
    public init<S>(uniqueKeysWithValues keysAndValues: S) where S : Sequence, S.Element == (Key, Value) {
        dictionary = Dictionary<Key, Value>(uniqueKeysWithValues: keysAndValues)
    }
    
    public init<S>(
        _ keysAndValues: S,
        uniquingKeysWith combine: (Value, Value) throws -> Value
    ) rethrows where S : Sequence, S.Element == (Key, Value) {
        dictionary = try Dictionary<Key, Value>(keysAndValues, uniquingKeysWith: combine)
    }
    
    public init<S>(
        grouping values: S,
        by keyForValue: (S.Element) throws -> Key
    ) rethrows where Value == [S.Element], S : Sequence {
        dictionary = try Dictionary<Key, Value>(grouping: values, by: keyForValue)
    }
    
    public subscript(key: Key) -> Value? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return dictionary[key]
        }
        set(newValue) {
            lock.lock()
            defer { lock.unlock() }
            dictionary[key] = newValue
        }
    }
    
    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        lock.lock()
        defer { lock.unlock() }
        return dictionary[key, default: defaultValue()]
    }
    
    @available(swift 4.0)
    public var keys: Dictionary<Key, Value>.Keys {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.keys
    }
    
    @available(swift 4.0)
    public var values: Dictionary<Key, Value>.Values {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.values
    }
    
    public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> [Key : T] {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.mapValues(transform)
    }
    
    public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> [Key : T] {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.compactMapValues(transform)
    }
    
    @available(swift 4.0)
    public func filter(_ isIncluded: (Dictionary<Key, Value>.Element) throws -> Bool) rethrows -> SafeDictionary<Key, Value> {
        lock.lock()
        defer { lock.unlock() }
        return try SafeDictionary<Key, Value>(uniqueKeysWithValues: dictionary.filter(isIncluded))
    }
    
    @discardableResult
    public func updateValue(_ value: Value, forKey key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.updateValue(value, forKey: key)
    }
    
    public func merge<S>(
        _ other: S,
        uniquingKeysWith combine: (Value, Value) throws -> Value
    ) rethrows where S : Sequence, S.Element == (Key, Value) {
        lock.lock()
        defer { lock.unlock() }
        try dictionary.merge(other, uniquingKeysWith: combine)
    }
    
    public func merge(
        _ other: [Key : Value],
        uniquingKeysWith combine: (Value, Value) throws -> Value
    ) rethrows {
        lock.lock()
        defer { lock.unlock() }
        try dictionary.merge(other, uniquingKeysWith: combine)
    }
    
    public func merging<S>(
        _ other: S,
        uniquingKeysWith combine: (Value, Value) throws -> Value
    ) rethrows -> SafeDictionary<Key, Value> where S : Sequence, S.Element == (Key, Value) {
        lock.lock()
        defer { lock.unlock() }
        let tuples = try dictionary.merging(other, uniquingKeysWith: combine).map { ($0, $1) }
        return SafeDictionary<Key, Value>(uniqueKeysWithValues: tuples)
    }
    
    public func merging(
        _ other: [Key : Value],
        uniquingKeysWith combine: (Value, Value) throws -> Value
    ) rethrows -> SafeDictionary<Key, Value> {
        lock.lock()
        defer { lock.unlock() }
        let tuples = try dictionary.merging(other, uniquingKeysWith: combine).map { ($0, $1) }
        return SafeDictionary<Key, Value>(uniqueKeysWithValues: tuples)
    }
    
    @discardableResult
    public func remove(at index: Dictionary<Key, Value>.Index) -> SafeDictionary<Key, Value>.Element {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.remove(at: index)
    }
    
    @discardableResult
    public func removeValue(forKey key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.removeValue(forKey: key)
    }
    
    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        lock.lock()
        defer { lock.unlock() }
        dictionary.removeAll(keepingCapacity: keepCapacity)
    }
    
    public typealias Element = Dictionary<Key, Value>.Element
    
    public func popFirst() -> SafeDictionary<Key, Value>.Element? {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.popFirst()
    }
    
    public var capacity: Int {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.capacity
    }
    
    public func reserveCapacity(_ minimumCapacity: Int) {
        lock.lock()
        defer { lock.unlock() }
        dictionary.reserveCapacity(minimumCapacity)
    }
    
    public func dropFirst(_ k: Int = 1) -> Slice<Dictionary<Key, Value>> {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.dropFirst(k)
    }
    
    public func dropLast(_ k: Int = 1) -> Slice<Dictionary<Key, Value>> {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.dropLast(k)
    }
    
    public func drop(while predicate: ((key: Key, value: Value)) throws -> Bool) rethrows -> Slice<Dictionary<Key, Value>> {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.drop(while: predicate)
    }
    
    public func prefix(_ maxLength: Int) -> Slice<Dictionary<Key, Value>> {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.prefix(maxLength)
    }
    
    public func prefix(while predicate: ((key: Key, value: Value)) throws -> Bool) rethrows -> Slice<Dictionary<Key, Value>> {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.prefix(while: predicate)
    }
    
    public func suffix(_ maxLength: Int) -> Slice<Dictionary<Key, Value>> {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.suffix(maxLength)
    }
    
    public typealias Index = Dictionary<Key, Value>.Index
    
    public func prefix(upTo end: Index) -> Slice<Dictionary<Key, Value>> {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.prefix(upTo: end)
    }
    
    public func suffix(from start: Index) -> Slice<Dictionary<Key, Value>> {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.suffix(from: start)
    }
    
    public func prefix(through position: Index) -> Slice<Dictionary<Key, Value>> {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.prefix(through: position)
    }
    
    public func split(
        maxSplits: Int = Int.max,
        omittingEmptySubsequences: Bool = true,
        whereSeparator isSeparator: ((key: Key, value: Value)) throws -> Bool
    ) rethrows -> [Slice<Dictionary<Key, Value>>] {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.split(maxSplits: maxSplits,
                                    omittingEmptySubsequences: omittingEmptySubsequences,
                                    whereSeparator: isSeparator)
    }
    
    public func firstIndex(where predicate: ((key: Key, value: Value)) throws -> Bool) rethrows -> Index? {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.firstIndex(where: predicate)
    }
    
    public func shuffled<T>(using generator: inout T) -> [(key: Key, value: Value)] where T : RandomNumberGenerator {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.shuffled(using: &generator)
    }
    
    public func shuffled() -> [(key: Key, value: Value)] {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.shuffled()
    }
    
    public var indices: DefaultIndices<Dictionary<Key, Value>> {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.indices
    }
    
    public var lazy: LazySequence<Dictionary<Key, Value>> {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.lazy
    }
    
    @available(swift, deprecated: 4.1, renamed: "compactMap(_:)", message: "Please use compactMap(_:) for the case where closure returns an optional value")
    func flatMap<ElementOfResult>(
        _ transform: ((key: Key, value: Value)) throws -> ElementOfResult?
    ) rethrows -> [ElementOfResult] {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.flatMap(transform)
    }
    
    public subscript<R>(r: R) -> Slice<Dictionary<Key, Value>> where R : RangeExpression, Index == R.Bound {
        lock.lock()
        defer { lock.unlock() }
        return dictionary[r]
    }
    
    public subscript(x: (UnboundedRange_) -> ()) -> Slice<Dictionary<Key, Value>> {
        lock.lock()
        defer { lock.unlock() }
        return dictionary[x]
    }
    
    public func map<T>(_ transform: ((key: Key, value: Value)) throws -> T) rethrows -> [T] {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.map(transform)
    }
    
    public var underestimatedCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.underestimatedCount
    }
    
    public func forEach(_ body: ((key: Key, value: Value)) throws -> Void) rethrows {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.forEach(body)
    }
    
    public func first(where predicate: ((key: Key, value: Value)) throws -> Bool) rethrows -> (key: Key, value: Value)? {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.first(where: predicate)
    }
    
    public func withContiguousStorageIfAvailable<R>(
        _ body: (UnsafeBufferPointer<(key: Key, value: Value)>) throws -> R
    ) rethrows -> R? {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.withContiguousStorageIfAvailable(body)
    }
    
    public func enumerated() -> EnumeratedSequence<Dictionary<Key, Value>> {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.enumerated()
    }
    
    @warn_unqualified_access
    public func min(
        by areInIncreasingOrder: ((key: Key, value: Value), (key: Key, value: Value)) throws -> Bool
    ) rethrows -> (key: Key, value: Value)? {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.min(by: areInIncreasingOrder)
    }
    
    @warn_unqualified_access
    public func max(
        by areInIncreasingOrder: ((key: Key, value: Value), (key: Key, value: Value)) throws -> Bool
    ) rethrows -> (key: Key, value: Value)? {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.max(by: areInIncreasingOrder)
    }
    
    public func starts<PossiblePrefix>(
        with possiblePrefix: PossiblePrefix,
        by areEquivalent: ((key: Key, value: Value), PossiblePrefix.Element) throws -> Bool
    ) rethrows -> Bool where PossiblePrefix : Sequence {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.starts(with: possiblePrefix, by: areEquivalent)
    }
    
    public func elementsEqual<OtherSequence>(
        _ other: OtherSequence,
        by areEquivalent: ((key: Key, value: Value), OtherSequence.Element) throws -> Bool
    ) rethrows -> Bool where OtherSequence : Sequence {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.elementsEqual(other, by: areEquivalent)
    }
    
    public func lexicographicallyPrecedes<OtherSequence>(
        _ other: OtherSequence,
        by areInIncreasingOrder: ((key: Key, value: Value), (key: Key, value: Value)) throws -> Bool
    ) rethrows -> Bool where OtherSequence : Sequence, (key: Key, value: Value) == OtherSequence.Element {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.lexicographicallyPrecedes(other, by: areInIncreasingOrder)
    }
    
    public func contains(where predicate: ((key: Key, value: Value)) throws -> Bool) rethrows -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.contains(where: predicate)
    }
    
    public func allSatisfy(_ predicate: ((key: Key, value: Value)) throws -> Bool) rethrows -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.allSatisfy(predicate)
    }
    
    public func reduce<Result>(
        _ initialResult: Result,
        _ nextPartialResult: (Result, (key: Key, value: Value)) throws -> Result
    ) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.reduce(initialResult, nextPartialResult)
    }
    
    public func reduce<Result>(
        into initialResult: Result,
        _ updateAccumulatingResult: (inout Result, (key: Key, value: Value)) throws -> ()
    ) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.reduce(into: initialResult, updateAccumulatingResult)
    }
    
    public func reversed() -> [(key: Key, value: Value)] {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.reversed()
    }
    
    public func flatMap<SegmentOfResult>(
        _ transform: ((key: Key, value: Value)) throws -> SegmentOfResult
    ) rethrows -> [SegmentOfResult.Element] where SegmentOfResult : Sequence {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.flatMap(transform)
    }
    
    public func compactMap<ElementOfResult>(
        _ transform: ((key: Key, value: Value)) throws -> ElementOfResult?
    ) rethrows -> [ElementOfResult] {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.compactMap(transform)
    }
    
    public func sorted(
        by areInIncreasingOrder: ((key: Key, value: Value), (key: Key, value: Value)) throws -> Bool
    ) rethrows -> [(key: Key, value: Value)] {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.sorted(by: areInIncreasingOrder)
    }
    
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    public func trimmingPrefix(
        while predicate: ((key: Key, value: Value)) throws -> Bool
    ) rethrows -> Slice<Dictionary<Key, Value>> {
        lock.lock()
        defer { lock.unlock() }
        return try dictionary.trimmingPrefix(while: predicate)
    }
    
    public var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.isEmpty
    }
    
    public var first: (key: Key, value: Value)? {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.first
    }
    
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.count
    }
    
    public subscript(bounds: Range<Index>) -> Slice<Dictionary<Key, Value>> {
        lock.lock()
        defer { lock.unlock() }
        return dictionary[bounds]
    }
}


extension SafeDictionary where Key : Hashable, Value : Equatable {

    public static func != (lhs: SafeDictionary<Key, Value>, rhs: SafeDictionary<Key, Value>) -> Bool {
        lhs.lock.lock()
        rhs.lock.lock()
        defer {
            lhs.lock.unlock()
            rhs.lock.unlock()
        }
        return lhs.dictionary != rhs.dictionary
    }
}


extension SafeDictionary: Equatable where Value: Equatable {
    public static func == (lhs: SafeDictionary<Key, Value>, rhs: SafeDictionary<Key, Value>) -> Bool {
        lhs.lock.lock()
        rhs.lock.lock()
        defer {
            lhs.lock.unlock()
            rhs.lock.unlock()
        }
        return lhs.dictionary == rhs.dictionary
    }
}

extension SafeDictionary : Hashable where Value : Hashable {

    public func hash(into hasher: inout Hasher) {
        lock.lock()
        defer { lock.unlock() }
        dictionary.hash(into: &hasher)
    }

    public var hashValue: Int {
        lock.lock()
        defer { lock.unlock() }
        return dictionary.hashValue
    }
}

extension SafeDictionary : Encodable where Key : Encodable, Value : Encodable {

    public func encode(to encoder: Encoder) throws {
        lock.lock()
        defer { lock.unlock() }
        try dictionary.encode(to: encoder)
    }
}

extension SafeDictionary : Decodable where Key : Decodable, Value : Decodable {
    
    public convenience init(from decoder: Decoder) throws {
        try self.init(uniqueKeysWithValues: Dictionary<Key, Value>(from: decoder).map { ($0, $1) })
    }
}
