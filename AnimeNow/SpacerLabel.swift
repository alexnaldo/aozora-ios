//
//  SpacerLabel.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 4/7/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

class SpacerLabel: UILabel {

    override func intrinsicContentSize() -> CGSize {

        let intrinsicContentSize = super.intrinsicContentSize()

        let adjustedWidth = intrinsicContentSize.width + 10
        let adjustedHeight = intrinsicContentSize.height

        return CGSize(width: adjustedWidth, height: adjustedHeight)
    }

}