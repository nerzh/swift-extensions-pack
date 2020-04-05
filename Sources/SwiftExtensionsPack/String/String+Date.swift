//
//  String+Date.swift
//  
//
//  Created by Oleh Hudeichuk on 05.04.2020.
//

import Foundation

extension String {

    public func toDate(_ dateFormatter: DateFormatter, secondsFromGMT: Int?=nil) -> Date? {
        if let secondsFromGMT = secondsFromGMT {
            dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        } else {
            dateFormatter.timeZone = TimeZone.current
        }

        return dateFormatter.date(from: self)
    }

    public func toDate(dateFormat: String="dd-MM-yyyy HH:mm:ss", secondsFromGMT: Int?=nil) -> Date? {
        let dateFormatter        = DateFormatter()
        dateFormatter.dateFormat = dateFormat

        return toDate(dateFormatter, secondsFromGMT: secondsFromGMT)
    }
}
