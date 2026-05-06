//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 21.03.2023.
//

import Foundation

extension Data {
    public var getBytes: [UInt8] { [UInt8](self) }
    public var bytes: [UInt8] { getBytes }
}
