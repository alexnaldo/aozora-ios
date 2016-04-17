//
//  TTTAttributedLabel+Convenience.swift
//  Maroup
//
//  Created by Paul Chavarria Podoliako on 2/8/16.
//  Copyright © 2016 PropellerLabs. All rights reserved.
//

import UIKit
import CoreText

extension NSMutableAttributedString {

    func setFont(font: CTFont, inRange range: NSRange) {
        addAttribute(kCTFontAttributeName as String, value: font, range: range)
    }

    func setColor(color: CGColor, inRange range: NSRange) {
        addAttribute(kCTForegroundColorAttributeName as String, value: color, range: range)
    }

    func nsRangeOfString(text: String) -> NSRange {
        return (string as NSString).rangeOfString(text)
    }
}