//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 21.03.2023.
//

import Foundation

public extension String {
    var dataFromHex: Data? { Data(hexString: self) }
    
    func dataFromHexThrowing() throws -> Data {
        guard let data = Data(hexString: self) else {
            throw makeError(SEPCommonError.mess("Try get Data from hexString failed. Please, only hex format !"))
        }
        return data
    }
}
