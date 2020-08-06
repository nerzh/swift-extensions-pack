//
//  CommonMethods.swift
//  swift-extensions-pack
//
//  Created by Oleh Hudeichuk on 2/6/19.
//

import Foundation

/// Execute the given closure and ensure we release all auto pools if needed.
public func autoReleasePool<T>(_ execute: () throws -> T) rethrows -> T {
    #if os(Linux)
    return try execute()
    #else
    return try autoreleasepool { try execute() }
    #endif
}

public func isNumeric(_ anyObject: Any) -> Bool {
    var result: Bool = false

    if anyObject is Int {
        result = true
    } else if anyObject is Int8 {
        result = true
    } else if anyObject is Int16 {
        result = true
    } else if anyObject is Int32 {
        result = true
    } else if anyObject is Int64 {
        result = true
    } else if anyObject is Float {
        result = true
    } else if anyObject is Float32 {
        result = true
    } else if anyObject is Float64 {
        result = true
    } else if anyObject is Float80 {
        result = true
    } else if anyObject is Double {
        result = true
    } else if anyObject is Decimal {
        result = true
    }

    return result
}

#if os(Linux) || os(macOS)
@available(swift, introduced: 5)
@available(OSX 10.13, *)
public func systemCommand(_ command: String, _ user: String? = nil) throws -> String {
    var result: String = .init()
    let process: Process = .init()

    let pipe: Pipe = .init()
    if user != nil {
        process.arguments = ["sudo", "-H", "-u", user!, "bash", "-lc", "\(command)"]
    } else {
        process.arguments = ["bash", "-lc", "\(command)"]
    }
    process.executableURL = .init(fileURLWithPath: "/usr/bin/env")
    process.standardOutput = pipe
    process.standardError = pipe
    try process.run()
    process.waitUntilExit()
    let data: Data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        result = output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if process.isRunning { process.terminate() }

    return result
}
#endif

