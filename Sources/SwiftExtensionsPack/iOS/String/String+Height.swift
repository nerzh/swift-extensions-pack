//
//  String+Height.swift
//  
//
//  Created by Oleh Hudeichuk on 05.04.2020.
//

#if os(iOS)
import Foundation
import UIKit

// MARK: Calculate height
extension String {

    public func height(_ width: CGFloat, _ font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        return ceil(self.boundingRect(with: constraintRect,
                                      options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                      attributes: [NSAttributedString.Key.font: font],
                                      context: nil
        ).height)
    }

    public func width(_ width: CGFloat, _ font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        return ceil(self.boundingRect(with: constraintRect,
                                      options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                      attributes: [NSAttributedString.Key.font: font],
                                      context: nil
        ).height)
    }

    public func height (constrainedToWidth width: Double) -> CGFloat {
        let attributes  = [NSAttributedString.Key.font: self]
        let attString   = NSAttributedString(string: self, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attString)
        return ceil(CTFramesetterSuggestFrameSizeWithConstraints(framesetter,
                                                                 CFRange(location: 0,length: 0),
                                                                 nil,
                                                                 CGSize(width: width, height: Double.greatestFiniteMagnitude),
                                                                 nil
        ).height)
    }
}
#endif
