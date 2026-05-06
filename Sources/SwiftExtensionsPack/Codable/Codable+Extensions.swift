//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 05.06.2023.
//

import Foundation

extension Encodable {
    public var toJson: String? {
        let jsonData = try? JSONEncoder().encode(self)
        guard let jsonData = jsonData else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }
    
    public var toJsonUnsafe: String {
        let jsonData = try! JSONEncoder().encode(self)
        return String(data: jsonData, encoding: .utf8)!
    }
    
    public func toJsonThrowable() throws -> String {
        let jsonData = try JSONEncoder().encode(self)
        guard let json: String = String(data: jsonData, encoding: .utf8) else {
            throw SEPCommonError("Failed to convert string to utf8")
        }
        return json
    }
}
