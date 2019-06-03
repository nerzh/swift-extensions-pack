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
            var result : String = ""
            do {
                let regexp = try NSRegularExpression(pattern: pattern)
                let matches = regexp.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
                for match in matches {
                    let tempResult = eachRegexpMatchAtNumber(match) { (resultRange) -> (String?) in String(self[resultRange]) }
                    guard let string = tempResult, let resultString = string else { continue }
                    result = resultString
                }
            } catch {}
            
            return result
        }
    }
    
    // regexp: "string"["^\\w+$"]
    public subscript(pattern: String) -> Bool {
        get { return self[pattern] != "" }
    }
    
    // regexp: "match".regexp("(ma)([\\s\\S]+)")
    // => [0: "match", 1: "ma", 2:"tch"]
    public func regexp(_ pattern: String) -> [Int:String] {
        var result = [Int:String]()
        
        do {
            let regexp = try NSRegularExpression(pattern: pattern)
            let matches = regexp.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
            if matches.count > 0 { result = [Int:String]() }
            for match in matches {
                for number in 0..<match.numberOfRanges {
                    if let string = eachRegexpMatchAtNumber(match, number, { (resultRange)->(String?) in String(self[resultRange])})
                    {
                        result[number] = string
                    }
                }
            }
        } catch { }
        
        return result
    }
    
    // "111 Hello 111".replaceAll(#"\d+"#, "!!!") => "!!! Hello !!!"
    public func replaceAll(_ pattern: String, _ value: String) -> String {
        return self.replacingOccurrences(of: self[pattern], with: value)
    }
    
    public func replaceAll(_ pattern: String, _ handler: (([Int:String]) -> String)) -> String {
        let value = handler(self.regexp(pattern))
        return self.replaceAll(pattern, value)
    }
    
    public mutating func replaceAllSelf(_ pattern: String, _ value: String) {
        self = self.replacingOccurrences(of: self[pattern], with: value)
    }
    
    public mutating func replaceAllSelf(_ pattern: String, _ handler: (([Int:String]) -> String)) {
        let value = handler(self.regexp(pattern))
        self.replaceAllSelf(pattern, value)
    }
    
    // "111 Hello 111".replace(#"\d+"#, "!!!") => "!!! Hello 111"
    public func replace(_ pattern: String, _ value: String) -> String {
        var result = self
        
        do {
            let regexp = try NSRegularExpression(pattern: pattern)
            let matches = regexp.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
            
            for match in matches {
                if (eachRegexpMatchAtNumber(match) { (resultRange)->() in result.replaceSubrange(resultRange, with: value) }) != nil {
                    break
                }
            }
        } catch {}
        
        return result
    }
    
    public func replace(_ pattern: String, _ handler: (([Int:String]) -> String)) -> String {
        let value = handler(self.regexp(pattern))
        return self.replace(pattern, value)
    }
    
    public mutating func replaceSelf(_ pattern: String, _ value: String) {
        self = self.replace(pattern, value)
    }
    
    public mutating func replaceSelf(_ pattern: String, _ handler: (([Int:String]) -> String)) {
        let value = handler(self.regexp(pattern))
        self.replaceSelf(pattern, value)
    }
}






// PRIVATE HELPERS
extension String {
    
    // Helper for iterate REGEXP matches
    private func eachRegexpMatchAtNumber<T>(
        _ match:       NSTextCheckingResult,
        _ number:      Int=0,
        _ handler:    (Range<String.Index>) throws -> (T)
        ) rethrows -> T?
    {
        // beru range v stroke po nomeru iz sovpadeniy => {2, 5}
        let rangeOfMatch = match.range(at: number)
        // ZAGLUSHKA - BRED!!! Esli vlozhennost ((\d)|(\d)) gluk rangeOfMatch mozhet bit tipa {3123123, 0}
        // [BUG] If ((\d)|(\d)) then we can have the rangeOfMatch for example as this {3123123, 0}
        if rangeOfMatch.length <= 0 { return nil }
        
        let resultRange = self.index(self.startIndex, offsetBy: rangeOfMatch.location) ..<
            self.index(self.startIndex, offsetBy: rangeOfMatch.location+rangeOfMatch.length)
        
        return try handler(resultRange)
    }
}

