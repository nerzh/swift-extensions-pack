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
    if anyObject is Int { return true }
    if anyObject is Int8 { return true }
    if anyObject is Int16 { return true }
    if anyObject is Int32 { return true }
    if anyObject is Int64 { return true }
    if anyObject is Float { return true }
    if anyObject is Float32 { return true }
    if anyObject is Float64 { return true }
    #if os(macOS)
    if anyObject is Float80 { return true }
    #endif
    if anyObject is Double { return true }
    if anyObject is Decimal { return true }

    return false
}

#if os(Linux) || os(macOS)
@available(swift, introduced: 5)
@available(OSX 10.13, *)
public func forceKillProcess(_ process: Process) throws {
    process.terminate()
    usleep(1000)
    if process.isRunning { process.interrupt() }
    usleep(1000)
    if process.isRunning { try systemCommand("kill -9 \(process.processIdentifier)") }
//    while process.isRunning {
//        try systemCommand("kill -9 \(process.processIdentifier)")
//        usleep(1000)
//    }
}

@available(swift, introduced: 5)
@available(OSX 10.13, *)
@discardableResult
public func systemCommand(_ command: String, _ user: String? = nil, timeOutNanoseconds: UInt32 = 0) throws -> String {
    var result: String = .init()
    let process: Process = .init()
    let pipe: Pipe = .init()
    var timeOutThread: Thread?
    process.executableURL = .init(fileURLWithPath: "/usr/bin/env")
    process.standardOutput = pipe
    process.standardError = pipe
    if user != nil {
        process.arguments = ["sudo", "-H", "-u", user!, "bash", "-lc", "\(command)"]
    } else {
        process.arguments = ["bash", "-lc", "\(command)"]
    }
    if timeOutNanoseconds > 0 {
        timeOutThread = Thread {
            usleep(timeOutNanoseconds)
            try? forceKillProcess(process)
        }
    }
    try process.run()
    timeOutThread?.start()
    process.waitUntilExit()
    let data: Data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        result = output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if process.isRunning { try forceKillProcess(process) }

    return result
}
#endif

