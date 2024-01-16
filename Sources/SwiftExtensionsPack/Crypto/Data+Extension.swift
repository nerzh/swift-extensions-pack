//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 21.03.2023.
//

import Foundation

public extension Data {
    var getBytes: [UInt8] { [UInt8](self) }
    var bytes: [UInt8] { getBytes }
}
