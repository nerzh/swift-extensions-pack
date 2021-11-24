//
//  Double.swift
//  swift-extensions-pack
//
//  Created by Oleh Hudeichuk on 2/6/19.
//

import Foundation
import SwiftRegularExpression

extension Double {
    
    public func toString() -> String {
        func mantissaSignPow(double: Double) -> (mantissa: String, countAfterComma: Int, sign: String, pow: Int) {
            var mantissa        = ""
            var countAfterComma = 0
            var sign            = ""
            var pow             = 0
            
            let rgx = "\(double)".regexp("^((\\d)\\.(\\d+)|(\\d+))e(\\+|-)(\\d+)")
            if !rgx.isEmpty {
                sign = rgx[5]!
                if rgx[1]?["\\."] ?? false {
                    mantissa.append(rgx[2]!)
                    mantissa.append(rgx[3]!)
                    countAfterComma = rgx[3]!.count
                } else {
                    mantissa.append(rgx[1]!)
                }
                pow = Int(rgx[6]!)!
            }
            
            return (mantissa: mantissa, countAfterComma: countAfterComma, sign: sign, pow: pow)
        }
        
        let double = "\(self)"
        var result = ""
        
        if double["e"] {
            let msp = mantissaSignPow(double: self)
            
            if msp.sign == "+" {
                var lengthAfterComma = msp.pow - msp.countAfterComma
                if lengthAfterComma < 0 { lengthAfterComma = lengthAfterComma * -1 }
                result.append(msp.mantissa)
                for _ in 1...lengthAfterComma {
                    result.append("0")
                }
            } else {
                result = "0."
                
                for _ in 1..<msp.pow {
                    result.append("0")
                }
                result.append(msp.mantissa)
            }
        } else if double["\\.0$"] {
            let rgx = double.regexp("^(\\d+)\\.0$")
            if !rgx.isEmpty {
                result = "\(rgx[1]!)"
            }
        } else {
            result = double
        }
        
        return result
    }
    
    public func accurancy() -> Int {
        return self < 1 ? toString().replacingOccurrences(of: "0.", with: "").count : 0
    }
    
    public func round(toDecimalPlaces places: Int,
                      rule: FloatingPointRoundingRule=FloatingPointRoundingRule.up) -> Double
    {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded(rule) / divisor
    }
}
