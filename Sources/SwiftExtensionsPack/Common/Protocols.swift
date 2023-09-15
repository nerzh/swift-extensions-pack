//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 14.09.2023.
//

import Foundation

public protocol Cases {
    var caseName: String { get }
}

public extension Cases {
    var caseName: String { "\(String(describing: self))" }
}

public protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    public var isNil: Bool { self == nil }
}
