//
//  String.swift
//  swift-extensions-pack
//
//  Created by Oleh Hudeichuk on 2/6/19.
//

import Foundation

extension String {
    
    public func toModel<T>(model: T.Type) -> T? where T : Decodable {
        let data = self.data(using: .utf8)!
        return try? JSONDecoder().decode(model, from: data)
    }
    
    // regexp: "string"["^\\w+$"]
    public subscript(pattern: String) -> String {
        get {
            do {
                let regexp = try NSRegularExpression(pattern: pattern)
                let matches = regexp.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
                
                for match in matches {
                    // beru range v stroke po nomeru iz sovpadeniy => {2, 5}
                    let rangeOfMatch = match.range(at: 0)
                    // ZAGLUSHKA - BRED!!! Esli vlozhennost ((\d)|(\d)) gluk rangeOfMatch mozhet bit tipa {3123123, 0}
                    // [BUG] If ((\d)|(\d)) then we can have the rangeOfMatch for example as this {3123123, 0}
                    if rangeOfMatch.length <= 0 { continue }
                    
                    let resultRange = self.index(self.startIndex, offsetBy: rangeOfMatch.location) ..<
                        self.index(self.startIndex, offsetBy: rangeOfMatch.location+rangeOfMatch.length)
                    
                    return String(self[resultRange])
                }
            } catch {}
            
            return ""
        }
    }
    
    // regexp: "string"["^\\w+$"]
    public subscript(pattern: String) -> Bool {
        get { return self[pattern] != "" }
    }
    
    public func regexp(_ pattern: String) -> [Int:String]? {
        var result : [Int:String]?
        
        do {
            let regexp = try NSRegularExpression(pattern: pattern)
            let matches = regexp.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
            if matches.count > 0 { result = [Int:String]() }
            for match in matches {
                for number in 0..<match.numberOfRanges {
                    let rangeOfMatch = match.range(at: number)
                    if rangeOfMatch.length <= 0 { continue }
                    
                    let resultRange = self.index(self.startIndex, offsetBy: rangeOfMatch.location)..<self.index(self.startIndex, offsetBy: rangeOfMatch.location+rangeOfMatch.length)
                    result?[number] = String(self[resultRange])
                }
            }
            
        } catch { result = nil }
        
        return result
    }
}
