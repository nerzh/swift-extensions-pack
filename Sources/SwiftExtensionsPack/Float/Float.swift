//
//  Float.swift
//  swift-extensions-pack
//
//  Created by Oleh Hudeichuk on 2/6/19.
//

import Foundation
import SwiftRegularExpression

extension Float {
    
    public func toString() -> String {
        var str = "\(self)"
        if str["e"] {
            let rgx = str.regexp("^(\\d)\\.(\\d+)e-(\\d+)")
            if !rgx.isEmpty {
                
                str = "0."
                for _ in 1..<Int(rgx[3]!)! {
                    str.append("0")
                }
                str.append(rgx[1]!)
                str.append(rgx[2]!)
            }
        } else {
            if str["\\.0$"] {
                let rgx = str.regexp("^(\\d+)\\.0$")
                if !rgx.isEmpty {
                    str = "\(rgx[1]!)"
                }
            }
        }
        
        return str
    }
    
    public func accurancy() -> Int {
        return toString().replacingOccurrences(of: "0.", with: "").count
    }
    
    public func round(toDecimalPlaces places: Int,
                      rule: FloatingPointRoundingRule=FloatingPointRoundingRule.up) -> Float
    {
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded(rule) / divisor
    }
}
