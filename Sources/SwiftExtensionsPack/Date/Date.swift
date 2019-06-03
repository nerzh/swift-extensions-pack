//
//  Date.swift
//  swift-extensions-pack
//
//  Created by Oleh Hudeichuk on 2/6/19.
//

import Foundation

extension Date {
    
    public init(_ string: String, dateFormat: String="dd-MM-yyyy HH:mm:ss", secondsFromGMT: Int?=nil) {
        let dateFormatter        = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        if let secondsFromGMT = secondsFromGMT {
            dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        } else {
            dateFormatter.timeZone = TimeZone.current
        }
        
        
        self = dateFormatter.date(from: string)!
    }
    
    public func toMillis() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
    
    public func toSeconds() -> Int64 {
        return Int64(self.timeIntervalSince1970)
    }
    
    public func toString(dateFormat: String="dd-MM-yyyy HH:mm:ss", secondsFromGMT: Int?=nil) -> String {
        let dateFormatter        = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        if let secondsFromGMT = secondsFromGMT {
            dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        } else {
            dateFormatter.timeZone = TimeZone.current
        }
        
        return dateFormatter.string(from: self)
    }
    
    public func dateWithTimeZone(secondsFromGMT: Int, dateFormat: String="dd-MM-yyyy HH:mm:ss") -> Date {
        let dateFormatter        = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.timeZone   = TimeZone.init(abbreviation: "UTC")
        let currentDate          = dateFormatter.string(from: self)
        dateFormatter.timeZone   = TimeZone(secondsFromGMT: secondsFromGMT * -1)
        
        return dateFormatter.date(from: currentDate)!
    }
    
    public func stringWithTimeZone(secondsFromGMT: Int, dateFormat: String="dd-MM-yyyy HH:mm:ss") -> String {
        let dateFormatter        = DateFormatter()
        dateFormatter.timeZone   = TimeZone(secondsFromGMT: secondsFromGMT)
        dateFormatter.dateFormat = dateFormat
        
        return dateFormatter.string(from: self)
    }
    
    public func day(secondsFromGMT: Int?=nil) -> Int16 {
        return Int16(self.toString(dateFormat: "dd", secondsFromGMT: secondsFromGMT))!
    }
    
    public func month(secondsFromGMT: Int?=nil) -> Int16 {
        return Int16(self.toString(dateFormat: "MM", secondsFromGMT: secondsFromGMT))!
    }
    
    public func year(secondsFromGMT: Int?=nil) -> Int16 {
        return Int16(self.toString(dateFormat: "yyyy", secondsFromGMT: secondsFromGMT))!
    }
    
    public func hours(secondsFromGMT: Int?=nil) -> Int16 {
        return Int16(self.toString(dateFormat: "HH", secondsFromGMT: secondsFromGMT))!
    }
    
    public func minutes(secondsFromGMT: Int?=nil) -> Int16 {
        return Int16(self.toString(dateFormat: "mm", secondsFromGMT: secondsFromGMT))!
    }
    
    public func seconds(secondsFromGMT: Int?=nil) -> Int16 {
        return Int16(self.toString(dateFormat: "ss", secondsFromGMT: secondsFromGMT))!
    }
}
