//
//  StringCommon.swift
//
//
//  Created by Oleh Hudeichuk on 3/6/19.
//

import Foundation

public extension String {
    func bytes(_ using: Encoding = .utf8) -> Int {
        self.data(using: using)?.count ?? 0
    }
    
    // TO DECODABLE STRUCT
    func toModel<T>(_ model: T.Type) -> T? where T : Decodable {
        guard let data = self.data(using: String.Encoding.utf8) else { return nil }
        return try? JSONDecoder().decode(model, from: data)
    }
    
    func toModel<T>(_ model: T.Type) throws -> T where T : Decodable {
        guard let data = self.data(using: String.Encoding.utf8) else {
            throw SEPCommonError("Encoding data to utf8 failed")
        }
        return try JSONDecoder().decode(model, from: data)
    }
    
    func getPointer<T>(_ handler: (_ pointer: UnsafePointer<T>, _ len: Int) throws -> Void) rethrows {
        var string = self
        try string.withUTF8 { (p: UnsafeBufferPointer<UInt8>) in
            try p.baseAddress?.withMemoryRebound(to: T.self, capacity: p.count) { (p2: UnsafePointer<T>) in
                try handler(p2, p.count)
            }
        }
    }
}
