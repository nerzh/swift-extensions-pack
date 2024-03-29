//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 05.06.2023.
//

import Foundation

public extension Encodable {
    var toJson: String? {
        let jsonData = try? JSONEncoder().encode(self)
        guard let jsonData = jsonData else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }
    
    var toJsonUnsafe: String {
        let jsonData = try! JSONEncoder().encode(self)
        return String(data: jsonData, encoding: .utf8)!
    }
    
    func toJsonThrowable() throws -> String {
        let jsonData = try JSONEncoder().encode(self)
        guard let json: String = String(data: jsonData, encoding: .utf8) else {
            throw SEPCommonError("Failed to convert string to utf8")
        }
        return json
    }
}
