public struct Box<T: Copyable>: ~Copyable {
    public var value: T 

    public init(_ value: consuming T) {
        self.value = value
    }

    public borrowing func copy() -> Box<T> {
        return Self.init(self.value)
    }
}

extension Box: Sendable where T: Sendable {}
