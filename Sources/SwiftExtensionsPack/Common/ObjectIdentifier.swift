//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 15.10.2023.
//

import Foundation

public class ObjectId: @unchecked Sendable { public init() {} }

public protocol ObjectIdentifiable {
    func objectId() -> ObjectIdentifier
}
extension ObjectIdentifiable where Self: AnyObject {
    public func objectId() -> ObjectIdentifier {
        ObjectIdentifier(self)
    }
}
public protocol ObjectIdentifiableStruct: ObjectIdentifiable {
    var _objectId: ObjectId { get }
}
extension ObjectIdentifiableStruct {
    public func objectId() -> ObjectIdentifier {
        ObjectIdentifier(_objectId)
    }
}
