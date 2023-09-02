//
//  CommonClasses.swift
//  
//
//  Created by Oleh Hudeichuk on 05.04.2020.
//

import Foundation

open class SEPCommon {

    /// threadSafe common DateFormatter
    @Atomic static var defaultDateFormatter: DateFormatter = {
        let dateFormatter: DateFormatter = .init()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        return dateFormatter
    }()
}
