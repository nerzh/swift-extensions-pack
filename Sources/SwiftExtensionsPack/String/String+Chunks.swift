//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 14.03.2024.
//

import Foundation

public extension String {
    
    func chunks(_ size: Int) -> [String] {
        guard size > 0 else { return [self] }
        var result = [String]()
        var startIndex = self.startIndex
        
        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: min(size, self.distance(from: startIndex, to: self.endIndex)))
            result.append(String(self[startIndex..<endIndex]))
            startIndex = endIndex
        }
        
        return result
    }
}
