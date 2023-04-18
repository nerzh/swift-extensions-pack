//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 26.03.2023.
//

import Foundation

protocol OptionalProtocol {
    func wrappedType() -> Any.Type
}
extension Optional: OptionalProtocol {
     func wrappedType() -> Any.Type { return Wrapped.self }
}

protocol ArrayProtocol {
    func wrappedType() -> Any.Type
}
extension Array: ArrayProtocol {
     func wrappedType() -> Any.Type { return Element.self }
}

public func isOptional(_ instance: Any) -> Bool {
    let mirror = Mirror(reflecting: instance)
    return mirror.displayStyle == .optional
}

public func getPropertiesInfo(_ instance: Any) -> [(name: String, value: Any, type: Any.Type, isOptional: Bool, wrappedType: Any.Type?)] {
    let mirror = Mirror(reflecting: instance)
    var result: [(name: String, value: Any, type: Any.Type, isOptional: Bool, wrappedType: Any.Type?)] = .init()
    mirror.children.forEach { child in
        if let name = child.label {
            let isOptional: Bool = isOptional(child.value)
            var wrappedType: Any.Type?
            if child.value as? OptionalProtocol != nil {
                wrappedType = (child.value as! OptionalProtocol).wrappedType()
            } else if child.value as? ArrayProtocol != nil {
                wrappedType = (child.value as! ArrayProtocol).wrappedType()
            }
            result.append((name: name,
                           value: child.value,
                           type: type(of: child.value).self,
                           isOptional: isOptional,
                           wrappedType: wrappedType))
        }
    }
    return result
}
