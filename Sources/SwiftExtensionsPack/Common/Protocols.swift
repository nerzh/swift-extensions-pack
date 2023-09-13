//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 14.09.2023.
//

import Foundation

public protocol Cases {
    var `case`: String { get }
}

public extension Cases {
    var `case`: String { "\(self)" }
}
