//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 02.09.2023.
//

import Foundation

public protocol SafeArrayPrtcl {
    associatedtype Element
    var lock: NSLock { get }
    var array: Array<Element> { get set }
}

final public class SafeArray<Element>: CustomStringConvertible, CustomDebugStringConvertible, @unchecked Sendable {
    private let lock: NSLock = .init()
    private var array: Array<Element>
    public var description: String { array.description }
    public var debugDescription: String { array.debugDescription }
    
    public init() {
        array = .init()
    }
    
    public var capacity: Int {
        lock.lock()
        defer { lock.unlock() }
        return array.capacity
    }
    
    public static func + (lhs: SafeArray<Element>, rhs: SafeArray<Element>) -> Array<Element> {
        lhs.lock.lock()
        rhs.lock.lock()
        defer {
            lhs.lock.unlock()
            rhs.lock.unlock()
        }
        return lhs.array + rhs.array
    }
    
    public static func += (lhs: inout SafeArray<Element>, rhs: SafeArray<Element>) {
        lhs.lock.lock()
        rhs.lock.lock()
        defer {
            lhs.lock.unlock()
            rhs.lock.unlock()
        }
        lhs.array += rhs.array
    }
    
    public init(
        unsafeUninitializedCapacity: Int,
        initializingWith initializer: (
            _ buffer: inout UnsafeMutableBufferPointer<Element>,
            _ initializedCount: inout Int
        ) throws -> Void
    ) rethrows {
        array = try Array<Element>(unsafeUninitializedCapacity: unsafeUninitializedCapacity, initializingWith: initializer)
    }
    
    public func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try array.withUnsafeBufferPointer(body)
    }
    
    public func withUnsafeMutableBufferPointer<R>(
        _ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R
    ) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try array.withUnsafeMutableBufferPointer(body)
    }
    
    public func replaceSubrange<C>(
        _ subrange: Range<Int>, with newElements: C
    ) where Element == C.Element, C : Collection {
        lock.lock()
        defer { lock.unlock() }
        array.replaceSubrange(subrange, with: newElements)
    }
    
    public func withUnsafeMutableBytes<R>(_ body: (UnsafeMutableRawBufferPointer) throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try array.withUnsafeMutableBytes(body)
    }
    
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try array.withUnsafeBytes(body)
    }
    
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> SafeArray<Element> {
        lock.lock()
        defer { lock.unlock() }
        return try SafeArray<Element>(array.filter(isIncluded))
    }
    
    public func dropLast(_ k: Int) -> ArraySlice<Element> {
        lock.lock()
        defer { lock.unlock() }
        return array.dropLast(k)
    }
    
    public func suffix(_ maxLength: Int) -> ArraySlice<Element> {
        lock.lock()
        defer { lock.unlock() }
        return array.suffix(maxLength)
    }
    
    public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
        lock.lock()
        defer { lock.unlock() }
        return try array.map(transform)
    }
    
    public func dropFirst(_ k: Int = 1) -> ArraySlice<Element> {
        lock.lock()
        defer { lock.unlock() }
        return array.dropFirst(k)
    }
    
    public func drop(while predicate: (Element) throws -> Bool) rethrows -> ArraySlice<Element> {
        lock.lock()
        defer { lock.unlock() }
        return try array.drop(while: predicate)
    }
    
    public func prefix(_ maxLength: Int) -> ArraySlice<Element> {
        lock.lock()
        defer { lock.unlock() }
        return array.prefix(maxLength)
    }
    
    public func prefix(while predicate: (Element) throws -> Bool) rethrows -> ArraySlice<Element> {
        lock.lock()
        defer { lock.unlock() }
        return try array.prefix(while: predicate)
    }
    
    public func prefix(upTo end: Int) -> ArraySlice<Element> {
        lock.lock()
        defer { lock.unlock() }
        return array.prefix(upTo: end)
    }
    
    public func suffix(from start: Int) -> ArraySlice<Element> {
        lock.lock()
        defer { lock.unlock() }
        return array.suffix(from: start)
    }
    
    public func prefix(through position: Int) -> ArraySlice<Element> {
        lock.lock()
        defer { lock.unlock() }
        return array.prefix(through: position)
    }
    
    public func split(
        maxSplits: Int = Int.max,
        omittingEmptySubsequences: Bool = true,
        whereSeparator isSeparator: (Element) throws -> Bool
    ) rethrows -> [ArraySlice<Element>] {
        lock.lock()
        defer { lock.unlock() }
        return try array.split(maxSplits: maxSplits,
                               omittingEmptySubsequences: omittingEmptySubsequences,
                               whereSeparator: isSeparator)
    }
    
    public var last: Element? {
        lock.lock()
        defer { lock.unlock() }
        return array.last
    }
    
    public func firstIndex(where predicate: (Element) throws -> Bool) rethrows -> Int? {
        lock.lock()
        defer { lock.unlock() }
        return try array.firstIndex(where: predicate)
    }
    
    public func last(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        lock.lock()
        defer { lock.unlock() }
        return try array.last(where: predicate)
    }
    
    public func lastIndex(where predicate: (Element) throws -> Bool) rethrows -> Int? {
        lock.lock()
        defer { lock.unlock() }
        return try array.lastIndex(where: predicate)
    }
    
    public func partition(by belongsInSecondPartition: (Element) throws -> Bool) rethrows -> Int {
        lock.lock()
        defer { lock.unlock() }
        return try array.partition(by: belongsInSecondPartition)
    }
    
    public func shuffled<T>(using generator: inout T) -> SafeArray<Element> where T : RandomNumberGenerator {
        lock.lock()
        defer { lock.unlock() }
        return SafeArray<Element>(array.shuffled(using: &generator))
    }
    
    public func shuffled() -> SafeArray<Element> {
        lock.lock()
        defer { lock.unlock() }
        return SafeArray<Element>(array.shuffled())
    }
    
    public func shuffle<T>(using generator: inout T) where T : RandomNumberGenerator {
        lock.lock()
        defer { lock.unlock() }
        return array.shuffle(using: &generator)
    }
    
    public func shuffle() {
        lock.lock()
        defer { lock.unlock() }
        array.shuffle()
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func applying(_ difference: CollectionDifference<Element>) -> Array<Element>? {
        lock.lock()
        defer { lock.unlock() }
        return array.applying(difference)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func difference<C>(
        from other: C, by areEquivalent: (C.Element, Element) -> Bool
    ) -> CollectionDifference<Element> where C : BidirectionalCollection, Element == C.Element {
        lock.lock()
        defer { lock.unlock() }
        return array.difference(from: other, by: areEquivalent)
    }
    
    public var lazy: LazySequence<Array<Element>> {
        lock.lock()
        defer { lock.unlock() }
        return array.lazy
    }
    
    @available(swift, deprecated: 4.1, renamed: "compactMap(_:)", message: "Please use compactMap(_:) for the case where closure returns an optional value")
    public func flatMap<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        lock.lock()
        defer { lock.unlock() }
        return try array.flatMap(transform)
    }
    
    public func withContiguousMutableStorageIfAvailable<R>(
        _ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R
    ) rethrows -> R? {
        lock.lock()
        defer { lock.unlock() }
        return try array.withContiguousMutableStorageIfAvailable(body)
    }
    
    public func swapAt(_ i: Int, _ j: Int) {
        lock.lock()
        defer { lock.unlock() }
        array.swapAt(i, j)
    }
    
    public subscript<R>(r: R) -> ArraySlice<Element> where R : RangeExpression, Int == R.Bound {
        lock.lock()
        defer { lock.unlock() }
        return array[r]
    }
    
    public subscript(x: (UnboundedRange_) -> ()) -> ArraySlice<Element> {
        lock.lock()
        defer { lock.unlock() }
        return array[x]
    }
    
    public init(repeating repeatedValue: Element, count: Int) {
        array = Array(repeating: repeatedValue, count: count)
    }
    
    public init<S>(_ elements: S) where S : Sequence, Element == S.Element {
        array = Array(elements)
    }
    
    public func append(_ newElement: Element) {
        lock.lock()
        defer { lock.unlock() }
        array.append(newElement)
    }
    
    public func append<S>(contentsOf newElements: S) where S : Sequence, Element == S.Element {
        lock.lock()
        defer { lock.unlock() }
        array.append(contentsOf: newElements)
    }
    
    public func insert(_ newElement: Element, at i: Int) {
        lock.lock()
        defer { lock.unlock() }
        array.insert(newElement, at: i)
    }
    
    public func insert<C>(contentsOf newElements: C, at i: Int) where C : Collection, Element == C.Element {
        lock.lock()
        defer { lock.unlock() }
        array.insert(contentsOf: newElements, at: i)
    }
    
    @discardableResult
    public func remove(at position: Int) -> Element {
        lock.lock()
        defer { lock.unlock() }
        return array.remove(at: position)
    }
    
    public func removeSubrange(_ bounds: Range<Int>) {
        lock.lock()
        defer { lock.unlock() }
        array.removeSubrange(bounds)
    }
    
    public func removeFirst(_ k: Int) {
        lock.lock()
        defer { lock.unlock() }
        array.removeFirst(k)
    }
    
    @discardableResult
    public func removeFirst() -> Element {
        lock.lock()
        defer { lock.unlock() }
        return array.removeFirst()
    }
    
    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        lock.lock()
        defer { lock.unlock() }
        array.removeAll(keepingCapacity: keepCapacity)
    }
    
    public func reserveCapacity(_ n: Int) {
        lock.lock()
        defer { lock.unlock() }
        array.reserveCapacity(n)
    }
    
    public func replaceSubrange<C, R>(
        _ subrange: R, with newElements: C
    ) where C : Collection, R : RangeExpression, Element == C.Element, Int == R.Bound {
        lock.lock()
        defer { lock.unlock() }
        array.replaceSubrange(subrange, with: newElements)
    }
    
    public func removeSubrange<R>(_ bounds: R) where R : RangeExpression, Int == R.Bound {
        lock.lock()
        defer { lock.unlock() }
        array.removeSubrange(bounds)
    }
    
    public func popLast() -> Element? {
        lock.lock()
        defer { lock.unlock() }
        return array.popLast()
    }
    
    @discardableResult
    public func removeLast() -> Element {
        lock.lock()
        defer { lock.unlock() }
        return array.removeLast()
    }
    
    public func removeLast(_ k: Int) {
        lock.lock()
        defer { lock.unlock() }
        return array.removeLast(k)
    }
    
    public static func + <Other>(
        lhs: SafeArray<Element>, rhs: Other
    ) -> Array<Element> where Other : Sequence & SafeArrayPrtcl, Element == Other.Element {
        lhs.lock.lock()
        rhs.lock.lock()
        defer {
            lhs.lock.unlock()
            rhs.lock.unlock()
        }
        return lhs.array + rhs.array
    }
    
    public static func += <Other>(
        lhs: inout SafeArray<Element>, rhs: Other
    ) where Other : Sequence & SafeArrayPrtcl, Element == Other.Element {
        lhs.lock.lock()
        rhs.lock.lock()
        defer {
            lhs.lock.unlock()
            rhs.lock.unlock()
        }
        lhs.array += rhs.array
    }
    
    public static func + <Other>(
        lhs: SafeArray<Element>, rhs: Other
    ) -> Array<Element> where Other : RangeReplaceableCollection & SafeArrayPrtcl, Element == Other.Element {
        lhs.lock.lock()
        rhs.lock.lock()
        defer {
            lhs.lock.unlock()
            rhs.lock.unlock()
        }
        return lhs.array + rhs.array
    }
    
    public func removeAll(where shouldBeRemoved: (Element) throws -> Bool) rethrows {
        lock.lock()
        defer { lock.unlock() }
        try array.removeAll(where: shouldBeRemoved)
    }
    
    public func reverse() {
        lock.lock()
        defer { lock.unlock() }
        array.reverse()
    }
    
    public func reversed() -> ReversedCollection<Array<Element>> {
        lock.lock()
        defer { lock.unlock() }
        return array.reversed()
    }
    
    public var underestimatedCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return array.underestimatedCount
    }
    
    public func forEach(_ body: (Element) throws -> Void) rethrows {
        lock.lock()
        defer { lock.unlock() }
        return try array.forEach(body)
    }
    
    public func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        lock.lock()
        defer { lock.unlock() }
        return try array.first(where: predicate)
    }
    
    public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R? {
        lock.lock()
        defer { lock.unlock() }
        return try array.withContiguousStorageIfAvailable(body)
    }
    
    public func enumerated() -> EnumeratedSequence<Array<Element>> {
        lock.lock()
        defer { lock.unlock() }
        return array.enumerated()
    }
    
    public func elementsEqual<OtherSequence>(
        _ other: OtherSequence,
        by areEquivalent: (Element, OtherSequence.Element) throws -> Bool
    ) rethrows -> Bool where OtherSequence : Sequence {
        lock.lock()
        defer { lock.unlock() }
        return try array.elementsEqual(other, by: areEquivalent)
    }
    
    public func lexicographicallyPrecedes<OtherSequence>(
        _ other: OtherSequence,
        by areInIncreasingOrder: (Element, Element) throws -> Bool
    ) rethrows -> Bool where OtherSequence : Sequence, Element == OtherSequence.Element {
        lock.lock()
        defer { lock.unlock() }
        return try array.lexicographicallyPrecedes(other, by: areInIncreasingOrder)
    }
    
    public func contains(where predicate: (Element) throws -> Bool) rethrows -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return try array.contains(where: predicate)
    }
    
    public func allSatisfy(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return try array.allSatisfy(predicate)
    }
    
    public func reduce<Result>(
        _ initialResult: Result,
        _ nextPartialResult: (Result, Element) throws -> Result
    ) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try array.reduce(initialResult, nextPartialResult)
    }
    
    public func reduce<Result>(
        into initialResult: Result,
        _ updateAccumulatingResult: (inout Result, Element) throws -> ()
    ) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try array.reduce(into: initialResult, updateAccumulatingResult)
    }
    
    public func flatMap<SegmentOfResult>(
        _ transform: (Element) throws -> SegmentOfResult
    ) rethrows -> [SegmentOfResult.Element] where SegmentOfResult : Sequence {
        lock.lock()
        defer { lock.unlock() }
        return try array.flatMap(transform)
    }
    
    public func compactMap<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        lock.lock()
        defer { lock.unlock() }
        return try array.compactMap(transform)
    }
    
    public func sorted(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> SafeArray<Element> {
        lock.lock()
        defer { lock.unlock() }
        return try SafeArray<Element>(array.sorted(by: areInIncreasingOrder))
    }
    
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    public func trimPrefix(while predicate: (Element) throws -> Bool) rethrows {
        lock.lock()
        defer { lock.unlock() }
        return try array.trimPrefix(while: predicate)
    }
    
    @warn_unqualified_access
    public func min(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> Element? {
        lock.lock()
        defer { lock.unlock() }
        return try array.min(by: areInIncreasingOrder)
    }
    
    @warn_unqualified_access
    public func max(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> Element? {
        lock.lock()
        defer { lock.unlock() }
        return try array.max(by: areInIncreasingOrder)
    }
    
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    public func trimmingPrefix(while predicate: (Element) throws -> Bool) rethrows -> ArraySlice<Element> {
        lock.lock()
        defer { lock.unlock() }
        return try array.trimmingPrefix(while: predicate)
    }
    
    public func starts<PossiblePrefix>(
        with possiblePrefix: PossiblePrefix,
        by areEquivalent: (Element, PossiblePrefix.Element) throws -> Bool
    ) rethrows -> Bool where PossiblePrefix : Sequence {
        lock.lock()
        defer { lock.unlock() }
        return try array.starts(with: possiblePrefix, by: areEquivalent)
    }
    
    public func sort(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows {
        lock.lock()
        defer { lock.unlock() }
        return try array.sort(by: areInIncreasingOrder)
    }
    
    public var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return array.isEmpty
    }
    
    public var first: Element? {
        lock.lock()
        defer { lock.unlock() }
        return array.first
    }
    
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return array.count
    }
    
    public func makeIterator() -> IndexingIterator<Array<Element>> {
        lock.lock()
        defer { lock.unlock() }
        return array.makeIterator()
    }
    
    public func formIndex(_ i: inout Int, offsetBy distance: Int) {
        lock.lock()
        defer { lock.unlock() }
        return array.formIndex(&i, offsetBy: distance)
    }
    
    public func formIndex(_ i: inout Int, offsetBy distance: Int, limitedBy limit: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return array.formIndex(&i, offsetBy: distance, limitedBy: limit)
    }
    
    public func randomElement<T>(using generator: inout T) -> Element? where T : RandomNumberGenerator {
        lock.lock()
        defer { lock.unlock() }
        return array.randomElement(using: &generator)
    }
    
    public func randomElement() -> Element? {
        lock.lock()
        defer { lock.unlock() }
        return array.randomElement()
    }
}

extension SafeArray : CustomReflectable {

    public var customMirror: Mirror {
        lock.lock()
        defer { lock.unlock() }
        return array.customMirror
    }
}

extension SafeArray where Element : StringProtocol {

    public func joined(separator: String = "") -> String {
        lock.lock()
        defer { lock.unlock() }
        return array.joined(separator: separator)
    }
}

extension SafeArray where Element : Sequence {
    
    public func joined() -> FlattenSequence<Array<Element>> {
        lock.lock()
        defer { lock.unlock() }
        return array.joined()
    }
    
    public func joined<Separator>(
        separator: Separator
    ) -> JoinedSequence<Array<Element>> where Separator : Sequence, Separator.Element == Element.Element {
        lock.lock()
        defer { lock.unlock() }
        return array.joined(separator: separator)
    }
}

extension SafeArray where Element == String {

    public func joined(separator: String = "") -> String {
        lock.lock()
        defer { lock.unlock() }
        return array.joined(separator: separator)
    }
}

extension SafeArray: Sequence {}

extension SafeArray : Encodable where Element : Encodable {

    public func encode(to encoder: Encoder) throws {
        lock.lock()
        defer { lock.unlock() }
        try array.encode(to: encoder)
    }
}

extension SafeArray : Decodable where Element : Decodable {

    public convenience init(from decoder: Decoder) throws {
        self.init(try Array<Element>(from: decoder))
    }
}

extension SafeArray: Equatable where Element: Equatable {
    public static func == (lhs: SafeArray<Element>, rhs: SafeArray<Element>) -> Bool {
        lhs.lock.lock()
        rhs.lock.lock()
        defer {
            lhs.lock.unlock()
            rhs.lock.unlock()
        }
        return lhs.array == rhs.array
    }
}

extension SafeArray : Hashable where Element : Hashable {

    public func hash(into hasher: inout Hasher) {
        lock.lock()
        defer { lock.unlock() }
        array.hash(into: &hasher)
    }

    public var hashValue: Int {
        lock.lock()
        defer { lock.unlock() }
        return array.hashValue
    }
}

extension SafeArray where Element : Comparable {

    public func sort() {
        lock.lock()
        defer { lock.unlock() }
        array.sort()
    }

    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    public func firstRange<C>(of other: C) -> Range<Int>? where C : Collection, Element == C.Element {
        lock.lock()
        defer { lock.unlock() }
        return array.firstRange(of: other)
    }

    @warn_unqualified_access
    public func min() -> Element? {
        lock.lock()
        defer { lock.unlock() }
        return array.min()
    }

    @warn_unqualified_access
    public func max() -> Element? {
        lock.lock()
        defer { lock.unlock() }
        return array.max()
    }

    public func lexicographicallyPrecedes<OtherSequence>(
        _ other: OtherSequence
    ) -> Bool where OtherSequence : Sequence, Element == OtherSequence.Element {
        lock.lock()
        defer { lock.unlock() }
        return array.lexicographicallyPrecedes(other)
    }

    public func sorted() -> SafeArray<Element> {
        lock.lock()
        defer { lock.unlock() }
        return SafeArray<Element>(array.sorted())
    }
}
