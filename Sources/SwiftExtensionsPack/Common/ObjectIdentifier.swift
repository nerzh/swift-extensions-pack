//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 15.10.2023.
//

import Foundation

public class ObjectId: @unchecked Sendable {}

public protocol ObjectIdentifiable {
    func objectId() -> ObjectIdentifier
}
public extension ObjectIdentifiable where Self: AnyObject {
    func objectId() -> ObjectIdentifier {
        ObjectIdentifier(self)
    }
}
public protocol ObjectIdentifiableStruct: ObjectIdentifiable {
    var _objectId: ObjectId { get }
}
public extension ObjectIdentifiableStruct {
    func objectId() -> ObjectIdentifier {
        ObjectIdentifier(_objectId)
    }
}
