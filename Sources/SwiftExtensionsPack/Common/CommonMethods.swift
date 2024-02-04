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
    #if os(macOS) && arch(x86_64)
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

public struct SystemCommandExitError: ErrorCommon {
    public var title: String = "\(Self.self)"
    public var reason: String = ""
    public init() {}
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
    if process.terminationStatus > 0 {
        throw SystemCommandExitError.mess(result)
    }

    return result
}

public func getEnvironmentVar(_ name: String) throws -> String? {
    let content: String = try systemCommand("echo $\(name)")
    if content.isEmpty { return nil }
    return content
}
#endif

func anyToJSON(_ any: Any) -> String {
    var result: String = .init()

    if let value = any as? Int {
        result = String(value)
    } else if let value = any as? String {
        result = "\"\(value)\""
    } else if let value = any as? Double {
        result = String(value)
    } else if let value = any as? Bool {
        result = String(value)
    } else if let value = any as? [String: Any] {
        result.append("{")
        var first: Bool = true
        for (key, val) in value {
            if first {
                result.append("\"\(key)\": \(anyToJSON(val))")
            } else {
                result.append(", \"\(key)\": \(anyToJSON(val))")
            }
            first = false
        }
        result.append("}")
    } else if let value = any as? [Any] {
        result.append("[")
        var first: Bool = true
        for val in value {
            if first {
                result.append("\(anyToJSON(val))")
            } else {
                result.append(", \(anyToJSON(val))")
            }
            first = false
        }
        result.append("]")
    }

    return result
}

/// asdf print
public func pe(_ line: Any...) {
    #if DEBUG
    let content: [Any] = ["ASDF:"] + line
    print(content.map{"\($0)"}.join(" "))
    #endif
}

public func pp(_ line: Any...) {
    #if DEBUG
    let content: [Any] = line
    print(content.map{"\($0)"}.join(" "))
    #endif
}

/// POW
precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ** : PowerPrecedence
public func ** (radix: Int, power: Int) -> Int {
    return Int(pow(Double(radix), Double(power)))
}

public func ** (radix: Double, power: Double) -> Double {
    return pow(radix, power)
}




