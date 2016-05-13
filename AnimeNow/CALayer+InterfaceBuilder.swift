//
//  CALayer+InterfaceBuilder.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 5/8/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

extension CALayer {
    var borderUIColor: UIColor {
        get {
            return borderColor == nil ? UIColor.clearColor() : UIColor(CGColor: borderColor!)
        }

        set {
            borderColor = newValue.CGColor
        }
    }
}