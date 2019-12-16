//
//  String.swift
//  swift-extensions-pack
//
//  Created by Oleh Hudeichuk on 2/6/19.
//

import Foundation
#if os(iOS)
import UIKit
#endif

// MARK: REGEXP
extension String {
    
    // regexp: "string"["^\\w+$"]
    public subscript(pattern: String) -> String {
        get {
            var result  = ""
            let matches = self.matches(pattern)
            for match in matches {
                let tempResult = eachRegexpMatchAtNumber(match) { (resultRange) -> (String?) in String(self[resultRange]) }
                guard let string = tempResult, let resultString = string else { continue }
                result = resultString
            }
            
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
        var result  = [Int:String]()
        let matches = self.matches(pattern)
        if matches.count > 0 { result = [Int:String]() }
        
        var lastIndex = matches.count - 1
        while(lastIndex >= 0) {
            let match = matches[lastIndex]
            for number in 0..<match.numberOfRanges {
                if let string = eachRegexpMatchAtNumber(match, number, { (resultRange)->(String?) in String(self[resultRange])})
                {
                    result[number] = string
                }
            }
            lastIndex -= 1
        }
        
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
        var result  = self
        let matches = self.matches(pattern)
        for match in matches {
            if (eachRegexpMatchAtNumber(match) { (resultRange)->() in result.replaceSubrange(resultRange, with: value) }) != nil {
                break
            }
        }
        
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
    
    public mutating func replaceEachValueSelf(_ pattern: String, _ handler: (([Int:String]) -> String)) {
        let arrayRanges = self.matchesWithRange(pattern)
        var orderRange  = arrayRanges.count - 1
        while(orderRange >= 0) {
            for (range, text) in arrayRanges[orderRange] {
                let value = handler(text.regexp(pattern))
                self.replaceSubrange(range, with: value)
            }
            orderRange -= 1
        }
    }
    
    // var s = "---|2|---  ---|34|--- ---|45|---"
    // s.replaceEachValueSelf(#"(\d+)"#) { dict in "new \(dict[1] ?? "")" }
    //          ---|2|---  ---|new 34|--- ---|new 45|---
    public func replaceEachValue(_ pattern: String, _ handler: (([Int:String]) -> String)) -> String {
        var selfString  = self
        selfString.replaceEachValueSelf(pattern, handler)
        
        return selfString
    }
    
    // "23 34".matchesWithRange(#"\d+"#)
    // => [Range<String.Index> : "23", Range<String.Index> : "34"]
    public func matchesWithRange(_ regexpPattern: String) -> [Range<String.Index>: String] {
        let matches = self.matches(regexpPattern)
        var result   = [Range<String.Index>: String]()
        for match in matches {
            var tempResultRange : Range<String.Index> = Range(NSRange(location: 0, length: 0), in: "")!
            let tempResult = eachRegexpMatchAtNumber(match) { (resultRange) -> (String?) in
                tempResultRange = resultRange
                return String(self[resultRange])
            }
            guard let string = tempResult, let resultString = string else { continue }
            result[tempResultRange] = resultString
        }
        return result
    }
}




// MARK: DECODE JSON
extension String {
    
    public func toModel<T>(model: T.Type) -> T? where T : Decodable {
        let data = self.data(using: .utf8)!
        return try? JSONDecoder().decode(model, from: data)
    }
}




// MARK: Unicode
extension String {
    
    // "043d".hexToCharacter()
    public func hexToCharacter() -> Character {
        return SwiftExtensionsPack.hexToCharacter(self)
    }
}



#if os(iOS)

// MARK: Calculate height
extension String {
    
    public func selfHeight(_ width: CGFloat, _ font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        return (self as NSString).boundingRect(
            with: constraintRect,
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font],
            context: nil
        ).height
    }
    
    public func selfHeight (constrainedToWidth width: Double) -> CGFloat {
        let attributes  = [NSAttributedString.Key.font: self]
        let attString   = NSAttributedString(string: self, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attString)
        return CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0,length: 0),
            nil,
            CGSize(width: width, height: Double.greatestFiniteMagnitude),
            nil
        ).height
    }
}
#endif



// MARK: PRIVATE HELPERS
extension String {
    
    // Helper for iterate REGEXP matches
    private func eachRegexpMatchAtNumber<T>(
        _ match:             NSTextCheckingResult,
        _ number:            Int=0,
        _ handler:           (Range<String.Index>) throws -> (T)
        ) rethrows -> T?
    {
        // beru range v stroke po nomeru iz sovpadeniy => {2, 5}
        let rangeOfMatch = match.range(at: number)
        // ZAGLUSHKA - BRED!!! Esli vlozhennost ((\d)|(\d)) gluk rangeOfMatch mozhet bit tipa {3123123, 0}
        // [BUG] If ((\d)|(\d)) then we can have the rangeOfMatch for example as this {3123123, 0}
        if rangeOfMatch.length <= 0 { return nil }
        
        let startLocation = rangeOfMatch.location
        let endLocation   = startLocation + rangeOfMatch.length
        let resultRange = self.index(self.startIndex, offsetBy: startLocation) ..<
            self.index(self.startIndex, offsetBy: endLocation)
        
        return try handler(resultRange)
    }
    
    private func matches(
        _ pattern: String,
        options:   NSRegularExpression.MatchingOptions = []
        ) -> [NSTextCheckingResult] {
        do {
            let regexp = try NSRegularExpression(pattern: pattern)
            return regexp.matches(in: self, options: options, range: NSRange(location: 0, length: self.count))
        } catch {
            return []
        }
    }
}

