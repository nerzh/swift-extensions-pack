//
//  String+JSON.swift
//  
//
//  Created by Oleh Hudeichuk on 05.04.2020.
//

import Foundation


// MARK: CODABLE DECODE JSON
extension String {

    public func decode<T>(to model: T.Type) -> T? where T : Decodable {
        guard let data = self.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(model, from: data)
    }
    
    public func toDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    public func toArray() -> [Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    public func toJsonObject() throws -> Any {
        guard let data = self.data(using: .utf8) else { throw SEPCommonError("Failed to convert data") }
        return try JSONSerialization.jsonObject(with: data, options: [])
    }
}
