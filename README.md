# SwiftExtensionsPack

SwiftExtensionsPack is a collection of practical Swift extensions and small utilities for everyday application code: JSON and Codable helpers, date and string conversions, collection helpers, synchronized containers, HTTP utilities, hex/base64 conversion, AES-GCM, HMAC, SHA, Ed25519, and runtime/system helpers.

The package is designed for places where you want short, readable helpers without building extra infrastructure around common tasks.

## Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [JSON and Codable](#json-and-codable)
- [String](#string)
- [Date](#date)
- [Numbers](#numbers)
- [Collections](#collections)
- [Synchronized Values](#synchronized-values)
- [Crypto](#crypto)
- [HTTP and Multipart](#http-and-multipart)
- [Errors and Common Utilities](#errors-and-common-utilities)
- [Runtime and Object Identity](#runtime-and-object-identity)
- [iOS-only APIs](#ios-only-apis)
- [Platforms](#platforms)
- [License](#license)

## Features

- JSON conversion helpers: `String -> Dictionary/Array/Model`, `Dictionary -> JSON/Model`, `Encodable -> JSON`.
- `AnyValue`, a `Codable` and `Equatable` JSON-like value container.
- String helpers for byte count, chunking, date parsing, UTF-8 pointers, hex, base64, and Unicode scalars.
- Date helpers for formatting, parsing, time zones, date components, and timestamps.
- `Float` and `Double` helpers for non-scientific string output, decimal accuracy, and rounding.
- Synchronized containers: `SafeArray`, `SafeDictionary`, `SafeValue`, `SendableValue`, `@Atomic`, `@AtomicOptional`.
- `LimiterAsync` for limiting async operations per time interval.
- Crypto helpers: random bytes/data, SHA-256/384/512, HMAC, AES-256-GCM, Ed25519, hex, bytes, bits, and endian conversion.
- Basic HTTP requests, flat and Rails-style query params, and multipart form-data.
- Common helpers: `SEPCommonError`, shell commands on macOS/Linux, `autoReleasePool`, `isNumeric`, debug printing, `**`, and runtime reflection.

## Installation

### Swift Package Manager

Add the package to `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/nerzh/swift-extensions-pack.git",
        from: "0.4.6"
    )
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(
                name: "SwiftExtensionsPack",
                package: "swift-extensions-pack"
            )
        ]
    )
]
```

In Xcode, use `File -> Add Package Dependencies...` and enter the repository URL.

### CocoaPods

```ruby
pod 'SwiftExtensionsPack', '~> 0.4.6'
```

### Import

```swift
import SwiftExtensionsPack
```

## Quick Start

```swift
import Foundation
import SwiftExtensionsPack

struct User: Codable {
    let id: Int
    let name: String
}

let json = #"{"id":1,"name":"Alice"}"#
let user = json.toModel(User.self)

let now = Date()
let textDate = now.toString(dateFormat: "yyyy-MM-dd HH:mm:ss", secondsFromGMT: 0)
let parsedDate = textDate.toDate(dateFormat: "yyyy-MM-dd HH:mm:ss", secondsFromGMT: 0)

let chunks = "HelloWorld".chunks(5) // ["Hello", "World"]
let hex = "Hello".toHexadecimal // "48656c6c6f"
let original = hex.fromHexadecimal() // "Hello"

let array = SafeArray([1, 2, 3])
array.append(4)
let even = array.filter { $0.isMultiple(of: 2) }

let digest = SEPCrypto.HMAC.sha512.digest(
    string: "password_string",
    key: "mnemonic_string"
)
```

## JSON and Codable

### String to JSON or model

```swift
struct Profile: Decodable {
    let id: Int
    let name: String
}

let objectJson = #"{"id":7,"name":"Oleh"}"#

let profile1 = objectJson.decode(to: Profile.self)
let profile2 = objectJson.toModel(Profile.self)
let profile3: Profile = try objectJson.toModel(Profile.self)

let dict = objectJson.toDictionary()
let anyObject = try objectJson.toJsonObject()

let arrayJson = #"[1,2,3]"#
let array = arrayJson.toArray()
```

| API | Description |
| --- | --- |
| `String.decode(to:)` | Decodes a UTF-8 JSON string with `JSONDecoder` and returns an optional model. |
| `String.toModel(_:) -> T?` | Decodes a UTF-8 JSON string and returns an optional model. |
| `String.toModel(_:) throws -> T` | Throwing model decoding helper. |
| `String.toDictionary()` | Parses a JSON object into `[String: Any]?`. |
| `String.toArray()` | Parses a JSON array into `[Any]?`. |
| `String.toJsonObject()` | Parses JSON and returns `Any`, throwing on failure. |

### Encodable to JSON

```swift
struct Token: Encodable {
    let value: String
}

let token = Token(value: "abc")

let optionalJson = token.toJson
let unsafeJson = token.toJsonUnsafe
let throwingJson = try token.toJsonThrowable()
```

| API | Description |
| --- | --- |
| `Encodable.toJson` | Encodes a value into `String?`. |
| `Encodable.toJsonUnsafe` | Encodes with `try!` and force unwrap. Use only when failure is impossible in your context. |
| `Encodable.toJsonThrowable()` | Encodes and throws if encoding or UTF-8 conversion fails. |

### Dictionary to JSON or model

```swift
struct Settings: Decodable {
    let retries: Int
    let debug: Bool
}

let raw: [String: Any] = [
    "retries": 3,
    "debug": true
]

let json = try raw.toJSON(options: [.prettyPrinted])
let data = try raw.toJSONData()
let settings = try raw.toModel(Settings.self)
```

| API | Description |
| --- | --- |
| `Dictionary.toJSON(options:)` | Serializes a dictionary into a JSON string. |
| `Dictionary.toJSONData(options:)` | Serializes a dictionary into JSON `Data`. |
| `Dictionary.toModel(_:)` | Serializes a dictionary to JSON and decodes a model. |
| `mergeOptionalDictionary(_:_:)` | Merges two optional dictionaries. Values from the right dictionary win. |

### AnyValue

`AnyValue` is a `Codable` and `Equatable` enum for JSON-like values.

```swift
let rawValue: [String: Any] = [
    "id": 1,
    "name": "Alice",
    "isActive": true,
    "tags": ["ios", "swift"]
]

let value = rawValue.toAnyValue()

let json = value.toJSON()
let dict = value.toDictionary()
let any = value.toAny()
```

Supported cases: `string`, `int`, `int8`, `int16`, `int32`, `int64`, `uint`, `uint8`, `uint16`, `uint32`, `uint64`, `float`, `float32`, `float64`, `double`, `decimal`, `bool`, `object`, `array`, and `nil`.

```swift
let fromArray = ([1, "two", true] as [Any]).toAnyValue()
let fromDict = (["id": 1, "name": "Bob"] as [String: Any]).toAnyValue()
let fromJsonObject = #"{"id":1}"#.toAnyValue()

struct User: Decodable {
    let id: Int
}

let user = try (["id": 1] as [String: Any]).toAnyValue().toModel(User.self)
```

`Dictionary.toAnyValue()` has overloads for common value types: `Any`, `Any?`, `String`, `String?`, `Int`, `Int?`, `Float`, `Float?`, `[Any]`, and `[Any]?`.

## String

### General helpers

```swift
let bytes = "Hello".bytes()
let parts = "abcdef".chunks(2) // ["ab", "cd", "ef"]

"hello".getPointer { (pointer: UnsafePointer<UInt8>, length: Int) in
    print(length)
}
```

| API | Description |
| --- | --- |
| `bytes(_:)` | Returns the number of bytes in the selected encoding. UTF-8 is used by default. |
| `chunks(_:)` | Splits a string into fixed-size chunks. |
| `getPointer(_:)` | Gives access to the UTF-8 buffer rebound to the requested pointer type. |

### Date parsing

```swift
let date = "2026-05-02 12:30:00".toDate(
    dateFormat: "yyyy-MM-dd HH:mm:ss",
    secondsFromGMT: 0
)

let formatter = DateFormatter()
formatter.dateFormat = "dd.MM.yyyy"
let anotherDate = "02.05.2026".toDate(formatter)
```

| API | Description |
| --- | --- |
| `toDate(_:secondsFromGMT:)` | Parses a date with an existing `DateFormatter`. |
| `toDate(dateFormat:secondsFromGMT:)` | Creates a `DateFormatter` from a format string and parses a date. |

### Hex, base64, and Unicode

```swift
let hex = "Hello".toHexadecimal
let text = hex.fromHexadecimal()

let data = "48656c6c6f".dataFromHex
let strictData = try "48656c6c6f".dataFromHexThrowing()

let withPrefix = "ff".add0x // "0xff"
let noPrefix = "0xff".remove0x // "ff"
let normalized = "0x000abc".hexClear // "0xabc"

let encoded = "hello".base64Encoded()
let decoded = encoded?.base64Decoded()

let symbol = "2705".hexToCharacter()
let number = try "ff".hexToUInt
```

| API | Description |
| --- | --- |
| `String(hexadecimal:encoding:)` | Creates a string from a hex representation. |
| `hexadecimalToData` / `dataFromHex` | Converts a hex string into `Data?`. |
| `dataFromHexThrowing()` | Throwing hex-to-`Data` conversion. |
| `toHexadecimal` | Encodes a UTF-8 string into hex. |
| `fromHexadecimal(encoding:)` | Decodes hex back into a string. |
| `Data(hexString:)` | Creates `Data` from a hex string. |
| `Data.toHexadecimal` | Encodes bytes into a hex string. |
| `isHexNumber` | Checks that all characters are hexadecimal digits. |
| `hexToUInt` | Throwing property backed by `UInt(self, radix: 16)`. |
| `hexToCharacter()` | Converts a hex Unicode scalar into `Character`. |
| `addHexZeroX` / `add0x` | Adds `0x` if the string does not already have it. |
| `removeHexZeroX` / `remove0x` / `delete0x` | Removes the `0x` prefix. |
| `addFirstZeroToHexIfNeeded` | Adds a leading zero for odd-length hex strings without `0x`. |
| `hexClear` | Collapses leading zeroes after `0x`. |
| `dataFromHexOrBase64()` | Reads the string as either hex or base64. |
| `base64Encoded()` | Encodes a string as base64. |
| `base64Decoded()` | Decodes base64 into a string. |
| `isBase64()` | Checks the string with a base64 regular expression. |

## Date

```swift
let now = Date()

let string = now.toString(dateFormat: "yyyy-MM-dd HH:mm:ss", secondsFromGMT: 0)
let localString = now.toString(dateFormat: "dd-MM-yyyy HH:mm:ss")

let day = now.getDay()
let month = now.getMonth()
let year = now.getYear()
let hours = now.getHours(secondsFromGMT: 0)

let ms = now.toMillis()
let seconds = now.toSeconds()
```

| API | Description |
| --- | --- |
| `toString(_:secondsFromGMT:)` | Formats a date with an existing `DateFormatter`. |
| `toString(dateFormat:secondsFromGMT:)` | Formats a date with a format string. |
| `stringWithTimeZone(_:secondsFromGMT:)` | Formats a date with a required time zone offset. |
| `stringWithTimeZone(dateFormat:secondsFromGMT:)` | Same as above, but creates the formatter from a format string. |
| `dateWithTimeZone(_:secondsFromGMT:)` | Rebuilds a date using a formatter and time zone offset. |
| `dateWithTimeZone(dateFormat:secondsFromGMT:)` | Same as above, but creates the formatter from a format string. |
| `getDay(secondsFromGMT:)` | Returns the day of month as `UInt?`. |
| `getMonth(secondsFromGMT:)` | Returns the month as `UInt?`. |
| `getYear(secondsFromGMT:)` | Returns the year as `UInt?`. |
| `getHours(secondsFromGMT:)` | Returns the hour as `UInt?`. |
| `getMinutes(secondsFromGMT:)` | Returns minutes as `UInt?`. |
| `getSeconds(secondsFromGMT:)` | Returns seconds as `UInt?`. |
| `toMillis()` | Returns a Unix timestamp in milliseconds. |
| `toSeconds()` | Returns a Unix timestamp in seconds. |

## Numbers

```swift
let d = 1.23e-5
d.toString() // "0.0000123"
d.accurancy()
d.round(toDecimalPlaces: 4)

let f: Float = 12.3400
f.toString()
f.round(toDecimalPlaces: 2, rule: .down)
```

| API | Types | Description |
| --- | --- | --- |
| `toString()` | `Double`, `Float` | Returns a string without unnecessary `.0` and with scientific notation expanded when supported. |
| `accurancy()` | `Double`, `Float` | Returns the number of digits after `0.` for small values. The API name is intentionally `accurancy()`. |
| `round(toDecimalPlaces:rule:)` | `Double`, `Float` | Rounds to a selected number of decimal places with a `FloatingPointRoundingRule`. |

Power operator:

```swift
let intPower = 2 ** 10 // 1024
let doublePower = 2.0 ** 0.5
```

## Collections

### Sequence

```swift
let joined = [1, 2, 3].join(", ") // "1, 2, 3"
let unique = [1, 1, 2, 3].uniq()

struct Row {
    let id: Int
    let name: String
}

let rows = [
    Row(id: 1, name: "A"),
    Row(id: 1, name: "B"),
    Row(id: 2, name: "C")
]

let uniqueById = rows.uniq { $0.id }
```

| API | Available on | Description |
| --- | --- | --- |
| `join(_:)` | `Sequence where Element: LosslessStringConvertible` | Joins elements using a separator. |
| `uniq()` | `Sequence where Element: Hashable` | Returns unique elements using `Set`. |
| `uniq(_:)` | `Sequence` | Returns unique elements using a hashable key. |

### SafeArray

`SafeArray<Element>` is a class wrapper around `Array<Element>` with `NSLock` around operations. It is useful for simple shared-state scenarios where individual reads and writes must be synchronized.

```swift
let values = SafeArray<Int>()
values.append(1)
values.append(contentsOf: [2, 3])

let count = values.count
let doubled = values.map { $0 * 2 }
let filtered = values.filter { $0 > 1 }

values.removeAll { $0.isMultiple(of: 2) }
```

Main API groups:

| Group | APIs |
| --- | --- |
| Initialization | `init()`, `init(_:)`, `init(repeating:count:)`, `init(unsafeUninitializedCapacity:initializingWith:)` |
| Size and state | `count`, `isEmpty`, `capacity`, `underestimatedCount`, `first`, `last`, `lazy`, `description`, `debugDescription`, `customMirror` |
| Operators and iteration | `+`, `+=`, `makeIterator()`, `formIndex(_:offsetBy:)`, `formIndex(_:offsetBy:limitedBy:)` |
| Append and insert | `append(_:)`, `append(contentsOf:)`, `insert(_:at:)`, `insert(contentsOf:at:)`, `reserveCapacity(_:)` |
| Removal | `remove(at:)`, `removeFirst()`, `removeFirst(_:)`, `removeLast()`, `removeLast(_:)`, `removeSubrange(_:)`, `removeAll(keepingCapacity:)`, `removeAll(where:)`, `popLast()` |
| Replacement and ordering | `replaceSubrange`, `swapAt`, `partition(by:)`, `reverse()`, `reversed()`, `shuffle()`, `shuffle(using:)`, `shuffled()`, `shuffled(using:)`, `sort()`, `sort(by:)`, `sorted()`, `sorted(by:)` |
| Slices | Range subscript, `prefix`, `suffix`, `dropFirst`, `dropLast`, `drop(while:)`, `split` |
| Search and checks | `first(where:)`, `firstIndex(where:)`, `last(where:)`, `lastIndex(where:)`, `contains(where:)`, `allSatisfy`, `starts(with:by:)`, `elementsEqual`, `lexicographicallyPrecedes`, `randomElement()`, `randomElement(using:)`, `min`, `max` |
| Transformations | `map`, `filter`, `compactMap`, `flatMap`, `reduce`, `reduce(into:)`, `forEach`, `enumerated`, `joined` |
| Storage | `withUnsafeBufferPointer`, `withUnsafeMutableBufferPointer`, `withUnsafeBytes`, `withUnsafeMutableBytes`, `withContiguousStorageIfAvailable`, `withContiguousMutableStorageIfAvailable` |
| Diff and newer APIs | `applying(_:)`, `difference(from:by:)`, `firstRange(of:)`, `trimPrefix(while:)`, `trimmingPrefix(while:)` |
| Protocol conformances | `Sequence`, `Encodable`, `Decodable`, `Equatable`, `Hashable`, `CustomReflectable` when `Element` satisfies the required constraints. |

`SafeArray` synchronizes each individual call. If you receive an `ArraySlice`, iterator, or reference-type element and mutate it outside the wrapper, that mutation is no longer synchronized by `SafeArray`.

`SafeArrayPrtcl` is a public protocol with `associatedtype Element`, `lock: NSLock`, and `array: Array<Element>`. It is used as a shared contract for array-like wrappers in operator overloads.

### SafeDictionary

`SafeDictionary<Key, Value>` is a class wrapper around `Dictionary<Key, Value>` with `NSLock` around operations.

```swift
let cache = SafeDictionary<String, Int>()
cache["hits"] = 1
cache.updateValue(2, forKey: "hits")

let hits = cache["hits"]
let keys = Array(cache.keys)
let filtered = cache.filter { $0.value > 1 }
```

Main API groups:

| Group | APIs |
| --- | --- |
| Initialization | `init()`, `init(minimumCapacity:)`, `init(uniqueKeysWithValues:)`, `init(_:uniquingKeysWith:)`, `init(grouping:by:)` |
| Subscripts | `subscript(key:)`, `subscript(key:default:)`, range subscript |
| Size and state | `count`, `isEmpty`, `capacity`, `first`, `keys`, `values`, `indices`, `lazy`, `underestimatedCount`, `description`, `debugDescription` |
| Mutation | `updateValue`, `merge`, `merging`, `remove(at:)`, `removeValue(forKey:)`, `removeAll(keepingCapacity:)`, `popFirst()`, `reserveCapacity(_:)` |
| Slices | `prefix`, `suffix`, `dropFirst`, `dropLast`, `drop(while:)`, `split` |
| Search and checks | `first(where:)`, `firstIndex(where:)`, `contains(where:)`, `allSatisfy`, `starts(with:by:)`, `elementsEqual`, `lexicographicallyPrecedes`, `min(by:)`, `max(by:)` |
| Transformations | `map`, `mapValues`, `compactMap`, `compactMapValues`, `filter`, `flatMap`, `reduce`, `reduce(into:)`, `forEach`, `enumerated`, `sorted(by:)`, `reversed`, `shuffled` |
| Storage and newer APIs | `withContiguousStorageIfAvailable`, `trimmingPrefix(while:)` |
| Protocol conformances | `Encodable`, `Decodable`, `Equatable`, `Hashable` when `Key` and `Value` satisfy the required constraints. |

## Synchronized Values

### SafeValue

`SafeValue<Value>` stores a value behind `NSLock`. Read with `value` and mutate with `change`.

```swift
let counter = SafeValue(0)

counter.change { value in
    value += 1
}

let current = counter.value
```

### SendableValue

`SendableValue<Value>` uses a concurrent `DispatchQueue`: reads may run in parallel, while mutations are executed through barrier blocks.

```swift
let state = SendableValue([String: Int]())

await state.change { dict in
    dict["count"] = 1
}

let snapshot = await state.read()

try await state.change { dict in
    if dict.isEmpty {
        throw SEPCommonError("Empty state")
    }
}
```

### Atomic and AtomicOptional

Property wrappers for object references (`Value: AnyObject`):

```swift
final class Store {
    @Atomic var items = NSMutableArray()
    @AtomicOptional var current: NSObject?
}
```

These wrappers synchronize reading and writing the reference itself. Mutating the referenced object still needs to be thread-safe or externally synchronized.

### LimiterAsync

`LimiterAsync` limits the number of async operations per time interval.

```swift
let limiter = LimiterAsync(maxRequests: 5, per: 1.0)

try await limiter.run {
    let (data, _) = try await Net.sendRequest(
        url: "https://example.com/api",
        method: "GET"
    )
    print(data.count)
}

let acquired = await limiter.acquire()
if acquired {
    // Run the operation.
}

await limiter.stop()
```

| API | Description |
| --- | --- |
| `init(maxRequests:per:)` | Creates a limiter for `maxRequests` operations per `TimeInterval`. |
| `acquire()` | Waits for an available slot and returns `Bool`. |
| `run(_ operation: () async throws -> T)` | Waits for a slot and runs an async closure. |
| `run(_ operation: (Bool) async throws -> T)` | Passes a cancellation flag into the closure. |
| `stop()` | Cancels the internal timer task. |

## Crypto

### Random

```swift
let bytes = randomBytes(count: 32)
let data = randomData(count: 32)
let index = randomInt(min: 0, max: 10)
let unsigned = randomUInt(min: 1, max: 100)
```

### Data, bytes, bits, and endian conversion

```swift
let data = Data([0x01, 0x02])
let bytes = data.bytes

let number: UInt32 = 0x01020304
let little = number.toBytes(endian: .littleEndian)
let big = number.toBytes(endian: .bigEndian)

let restored = UInt32(little)
let bits = number.toBits(endian: .bigEndian)
```

| API | Description |
| --- | --- |
| `Data.bytes` / `Data.getBytes` | Returns `[UInt8]`. |
| `ToBytesConvertable.toBytes(endian:)` | Converts an integer into bytes. |
| `ToBytesConvertable.toBytes(endian:count:)` | Converts an integer into a selected number of bytes. |
| `ToBytesConvertable.init(_ bytes:)` | Creates an integer from little-endian bytes. |
| `ToBytesConvertable.init(_:endian:)` | Creates an integer from bytes in the selected endian order. |
| `ToBitsConvertable.toBits(endian:)` | Returns a binary string. |
| `Endianness.bigEndian` / `.littleEndian` | Byte order. |

`ToBytesConvertable` is implemented for `UInt16`, `UInt32`, `UInt64`, `UInt`, `Int16`, `Int32`, `Int64`, and `Int`. `ToBitsConvertable` is also implemented for `UInt8` and `Int8`.

### SHA

```swift
let digest = SEPCrypto.SHA.sha256.digest(data: Data("hello".utf8))
let bytes = digest.withUnsafeBytes { Array($0) }
let hex = Data(bytes).toHexadecimal
```

Available algorithms: `SEPCrypto.SHA.sha256`, `.sha384`, and `.sha512`.

### HMAC

```swift
let dataDigest = SEPCrypto.HMAC.sha256.digest(
    data: Data("message".utf8),
    key: Data("secret".utf8)
)

let hexDigest = SEPCrypto.HMAC.sha512.digest(
    string: "message",
    key: "secret"
)
```

Available algorithms: `SEPCrypto.HMAC.sha256`, `.sha384`, and `.sha512`.

### AES-256-GCM

```swift
let key = try "my password".toAESKey()

let encryptedHex: String = try "secret text".encryptAES256(key: key)
let decryptedText: String = try encryptedHex.decryptAES256(key: key)

let encryptedWithStringKey: String = try "secret text".encryptAES256(key: "password")
let decryptedWithStringKey: String = try encryptedWithStringKey.decryptAES256(key: "password")
```

For `Data`:

```swift
let encrypted = try SEPCrypto.encryptAES256GCM(
    data: Data("secret".utf8),
    key: key
)

let decrypted = try SEPCrypto.decryptAES256GCM(
    data: encrypted,
    key: key
)
```

| API | Description |
| --- | --- |
| `SEPCrypto.encryptAES256GCM(data:key:nonce:)` | Encrypts `Data` with AES-GCM and returns the combined sealed box. |
| `SEPCrypto.decryptAES256GCM(data:key:)` | Decrypts a combined sealed box. |
| `String.encryptAES256(key: Data, nonce:) -> Data` | Encrypts a string and returns `Data`. |
| `String.encryptAES256(key: Data, nonce:) -> String` | Encrypts a string and returns a hex string. |
| `String.decryptAES256(key: Data) -> Data` | Reads an encrypted hex string and returns `Data`. |
| `String.decryptAES256(key: Data) -> String` | Reads an encrypted hex string and returns a UTF-8 string. |
| `String.encryptAES256(key: String, nonce:)` | Hashes a string key with SHA-256 and encrypts. |
| `String.decryptAES256(key: String)` | Hashes a string key with SHA-256 and decrypts. |
| `convertToAESKey()` / `toAESKey()` | SHA-256 of a UTF-8 string, suitable as a 256-bit key. |

### Ed25519

```swift
let seed = randomData(count: 32)
let pair = SEPCrypto.Ed25519.createKeyPair(seed32Byte: seed)

let message = Data("hello".utf8)
let signature = SEPCrypto.Ed25519.sign(
    message: message,
    publicKey32byte: pair.public,
    secretKey64byte: pair.secret
)

let verified = SEPCrypto.Ed25519.verify(
    signature: signature,
    message: message,
    len: message.count,
    publicKey: pair.public
)
```

| API | Description |
| --- | --- |
| `createKeyPair(seed32Byte:)` | Creates a 32-byte public key and a 64-byte secret key. |
| `createKeyPairHex(seed32Byte:)` | Same as above, but returns hex strings. |
| `createPublicKey(secretKey:)` | Rebuilds the public key from a secret key. |
| `sign(message:publicKey32byte:secretKey64byte:)` | Creates a 64-byte signature. |
| `verify(signature:message:len:publicKey:)` | Verifies a signature. |
| `edwardsToMontgomery(bytesData:)` | Converts Edwards bytes into a Montgomery-style representation. |
| `convertEd25519ToX25519(ed25519PrivateKey:)` | Converts an Ed25519 private key into an X25519 private key. |
| `getKeyExchange(privateKey:publicKey:)` | Performs key exchange and returns a shared secret. |

## HTTP and Multipart

### Query params

```swift
let simpleParams: [String: Any] = [
    "q": "swift extensions",
    "page": 1
]
let simple = Net.toQueryParams(simpleParams)

let railsParams: [String: Any] = [
    "user": [
        "name": "Alice",
        "roles": ["admin", "editor"]
    ]
]
let rails = Net.toRailsQueryParams(railsParams)

let full = Net.makeQueryParamsString(["page": 1])
let encoded = Net.urlEncode("hello world")
```

| API | Description |
| --- | --- |
| `Net.makeQueryParamsString(_:)` | Returns a query string prefixed with `?`. |
| `Net.paramsString(_:)` | Uses Rails-style query params. |
| `Net.toQueryParams(_:)` | Builds a flat query string. |
| `Net.toRailsQueryParams(_:)` | Builds recursive params like `user[name]=...` and `tags[]=...`. |
| `Net.urlEncode(_:)` | Percent-encodes with `alphanumerics + .-_` allowed. |

### Request

Callback API:

```swift
try Net.sendRequest(
    url: "https://example.com/api",
    method: "POST",
    headers: ["Content-Type": "application/x-www-form-urlencoded"],
    params: ["name": "Alice"]
) { data, response, error in
    if let error {
        throw error
    }
    print(data?.count ?? 0)
}
```

Async API:

```swift
let result = try await Net.sendRequest(
    url: "https://example.com/api",
    method: "GET",
    params: ["page": 1]
)

print(result.data.count)
```

For `GET`, params are appended to the URL. For other methods, the body is filled from `body`, `params`, or multipart form-data.

### Multipart

```swift
let file = NetSessionFile(
    data: Data("content".utf8),
    fileName: "file.txt",
    mimeType: "text/plain"
)

let multipart = NetMultipartData()
multipart.append("title", "Document")
multipart.appendFile("file", file.data, file.fileName, mimeType: file.mimeType)
let body = multipart.finalizeBodyAndGetData()
let boundary = multipart.boundary
```

Rails-style multipart from a nested object:

```swift
let multipartObject: [String: Any] = [
    "user": [
        "name": "Alice",
        "avatar": file
    ]
]
let body = NetMultipartData().toRailsMultipartData(multipartObject)
```

| API | Description |
| --- | --- |
| `NetSessionFilePrtcl` | File protocol with `data`, `fileName`, and `mimeType`. |
| `NetSessionFile` | Ready-to-use multipart file value. |
| `NetMultipartData.body` | Accumulated `NSMutableData`. |
| `NetMultipartData.boundary` | Multipart body boundary. |
| `append(_:_:)` | Adds a regular form field. |
| `appendFile(_:_:_:mimeType:)` | Adds a file field. |
| `finalizeBodyAndGetData()` | Adds the closing boundary and returns the body. |
| `toRailsMultipartData(_:)` | Recursively builds Rails-style multipart body. |
| `Net.sharedSession` | Shared `URLSession` with URL cache disabled. |
| `Net.NetErrors` | `NotValidParams`, `SomeError`, and `BadData`. |

## Errors and Common Utilities

### SEPCommonError and ErrorCommon

```swift
func load() throws {
    throw SEPCommonError("Something went wrong")
}

do {
    try load()
} catch {
    let wrapped = SEPCommonError(error)
    print(wrapped.localizedDescription)
}
```

`ErrorCommon` combines `Error`, `LocalizedError`, `CustomStringConvertible`, `CustomDebugStringConvertible`, and `Decodable`, and adds a mutable `reason`.

Initializer helpers:

```swift
let sourceError = NSError(
    domain: "SwiftExtensionsPackExample",
    code: 1
)

let e1 = SEPCommonError("Reason")
let e2 = SEPCommonError(sourceError, errorLevel: .debug)
let e3 = SEPCommonError(sourceError, exReason: "Additional context")
let e4 = SEPCommonError.error(sourceError)
```

`ErrorCommonLevel`: `.release`, `.debug`.

### Common methods

```swift
let result = autoReleasePool {
    Data(count: 1024)
}

isNumeric(123) // true
isNumeric("123") // false

let timestamp = getTimestampMs()
let char = hexToCharacter("2705")

pe("debug only with ASDF prefix")
pp("debug only")
```

Shell helpers are available on macOS/Linux:

```swift
let branch = try systemCommand("git branch --show-current")
let home = try getEnvironmentVar("HOME")
```

| API | Description |
| --- | --- |
| `autoReleasePool(_:)` | Uses `autoreleasepool` where Objective-C is available, otherwise just runs the closure. |
| `isNumeric(_:)` | Checks Swift numeric types: `Int*`, `UInt*`, `Float*`, `Double`, and `Decimal`. |
| `forceKillProcess(_:)` | Attempts to terminate, interrupt, and then kill a `Process`. macOS/Linux only. |
| `systemCommand(_:_:timeOutNanoseconds:)` | Runs a shell command through `/usr/bin/env bash -lc`. macOS/Linux only. |
| `SystemCommandExitError` | Error thrown by `systemCommand` when the process exits with a non-zero status. |
| `getEnvironmentVar(_:)` | Reads an environment variable through shell. macOS/Linux only. |
| `pe(_:)` | Debug print with the `ASDF:` prefix, compiled only in `DEBUG`. |
| `pp(_:)` | Debug print, compiled only in `DEBUG`. |
| `**` | Power operator for `Int` and `Double`. |
| `getTimestampMs()` | Current Unix timestamp in milliseconds. |
| `hexToCharacter(_:)` | Converts a hex Unicode scalar into `Character`. |

## Runtime and Object Identity

### Optional helpers

```swift
let optional: Int? = nil

isOptionalType(optional as Any) // true
isOptionalValue(optional) // true
optional.isNil // true
```

| API | Description |
| --- | --- |
| `isOptionalType(_:)` | Checks whether the runtime type is optional. |
| `isOptionalValue(_:)` | Checks whether an optional value is `nil`. |
| `AnyOptional.isNil` | Common protocol-based optional nil check. |

### Reflection

```swift
struct Person {
    let name: String
    let age: Int?
    let tags: [String]
}

let info = getPropertiesInfo(Person(name: "Alice", age: nil, tags: ["dev"]))

for property in info {
    print(property.name, property.type, property.isOptional, property.wrappedType as Any)
}
```

`getPropertiesInfo(_:)` returns an array of tuples:

```swift
(
    name: String,
    value: Any?,
    type: Any.Type,
    isOptional: Bool,
    wrappedType: Any.Type?
)
```

### Cases

```swift
enum Mode: Cases {
    case debug
}

Mode.debug.caseName // "debug"
```

### ObjectIdentifiable

For classes:

```swift
final class Service: ObjectIdentifiable {}

let service = Service()
let id = service.objectId()
```

For structs:

```swift
struct Job: ObjectIdentifiableStruct {
    let _objectId = ObjectId()
    let name: String
}

let id = Job(name: "sync").objectId()
```

## iOS-only APIs

### Text size

Available only on iOS with `UIKit`:

```swift
let font = UIFont.systemFont(ofSize: 16)
let h = "Hello".height(200, font)
let w = "Hello".width(200, font)
```

| API | Description |
| --- | --- |
| `String.height(_:_: )` | Calculates bounding height for a width and `UIFont`. |
| `String.width(_:_: )` | Calculates size through `boundingRect`. |
| `String.height(constrainedToWidth:)` | Calculates height through a CoreText framesetter. |

### CommonCrypto HMAC

When `CommonCrypto` is available, an additional HMAC API is compiled:

```swift
let hmac = "message".hmac(algorithm: .SHA256, key: "secret")
```

`CryptoAlgorithm`: `.MD5`, `.SHA1`, `.SHA224`, `.SHA256`, `.SHA384`, `.SHA512`.

| API | Description |
| --- | --- |
| `CryptoAlgorithm.HMACAlgorithm` | Returns `CCHmacAlgorithm`. |
| `CryptoAlgorithm.digestLength` | Returns the digest length. |
| `String.hmac(algorithm:key:)` | Returns a hex digest. |

## Platforms

The Swift package declares:

- iOS 13+
- macOS 10.15+
- Swift tools version 6.0

Platform notes:

- `CryptoKit` is used on Apple platforms, while `swift-crypto` is used on Linux/Android.
- AES-GCM APIs are marked `@available(iOS 13.0, macOS 10.15, *)`.
- Async `Net.sendRequest` is available on iOS 13+ and macOS 12+.
- `systemCommand`, `forceKillProcess`, and `getEnvironmentVar` are available on Linux/macOS.
- UIKit helpers are available only on iOS.
- CommonCrypto HMAC helpers are compiled only when `CommonCrypto` is available.

## License

See [LICENSE](LICENSE).
