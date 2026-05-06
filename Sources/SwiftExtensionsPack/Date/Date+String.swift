//
//  Date+String.swift
//  
//
//  Created by Oleh Hudeichuk on 05.04.2020.
//

import Foundation

extension Date {

    public func toString(_ dateFormatter: DateFormatter, secondsFromGMT: Int?=nil) -> String {
        if let secondsFromGMT = secondsFromGMT {
            dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        } else {
            dateFormatter.timeZone = TimeZone.current
        }

        return dateFormatter.string(from: self)
    }

    public func toString(dateFormat: String="dd-MM-yyyy HH:mm:ss", secondsFromGMT: Int?=nil) -> String {
        let dateFormatter        = DateFormatter()
        dateFormatter.dateFormat = dateFormat

        return toString(dateFormatter, secondsFromGMT: secondsFromGMT)
    }

    public func stringWithTimeZone(_ dateFormatter: DateFormatter, secondsFromGMT: Int) -> String {
        dateFormatter.timeZone   = TimeZone(secondsFromGMT: secondsFromGMT)

        return dateFormatter.string(from: self)
    }

    public func stringWithTimeZone(dateFormat: String="dd-MM-yyyy HH:mm:ss", secondsFromGMT: Int) -> String {
        let dateFormatter        = DateFormatter()
        dateFormatter.dateFormat = dateFormat

        return stringWithTimeZone(dateFormatter, secondsFromGMT: secondsFromGMT)
    }
}
