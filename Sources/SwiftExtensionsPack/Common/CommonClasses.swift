//
//  CommonClasses.swift
//
//
//  Created by Oleh Hudeichuk on 05.04.2020.
//

import Foundation

public actor SEPCommon {
    static let shared = SEPCommon()
    
    /// threadSafe common DateFormatter
    let defaultDateFormatter: DateFormatter = {
        let dateFormatter: DateFormatter = .init()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        return dateFormatter
    }()
}
