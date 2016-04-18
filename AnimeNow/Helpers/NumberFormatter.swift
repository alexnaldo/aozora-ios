//
//  NumberFormatter.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 4/17/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

struct NumberFormatter {

    static func number(number: Int) -> String {
        let formatter = NumberFormatter.numberStyleFormatter()
        return formatter.stringFromNumber(number) ?? "Unknown"
    }

    private static func numberStyleFormatter() -> NSNumberFormatter {
        let formatter = NSNumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        return formatter
    }
}