//
//  StringFormatter.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 2/9/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

class StringFormatter {
    class func shortenAnimeTitleIfNeeded(title: String) -> String {

        var formattedTitle = title

        if title.characters.count > 20 {
            let index: String.Index = title.startIndex.advancedBy(20)
            formattedTitle = title.substringToIndex(index)
        }
        return formattedTitle
    }
}