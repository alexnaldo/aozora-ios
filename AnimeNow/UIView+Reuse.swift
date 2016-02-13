//
//  UIView+Reuse.swift
//  Maroup
//
//  Created by Paul Chavarria Podoliako on 1/22/16.
//  Copyright © 2016 PropellerLabs. All rights reserved.
//

import UIKit

extension UIView {
    /// Reusing nib files read more: http://cocoanuts.mobi/2014/03/26/reusable/
    func reuseViewWithClass(classNamed: UIView.Type) {
        let nibName = String(classNamed)
        guard let nibViews = NSBundle.mainBundle().loadNibNamed(nibName, owner: self, options: [:]) as? [UIView],
            let loadedView = nibViews.first else {
                return
        }

        addSubview(loadedView)
        loadedView.translatesAutoresizingMaskIntoConstraints = false

        addConstraint(pinItem(loadedView, attribute: .Top))
        addConstraint(pinItem(loadedView, attribute: .Left))
        addConstraint(pinItem(loadedView, attribute: .Bottom))
        addConstraint(pinItem(loadedView, attribute: .Right))
    }
}

private extension UIView {
    func pinItem(item: NSObject, attribute: NSLayoutAttribute) -> NSLayoutConstraint {
        return NSLayoutConstraint(
            item: self,
            attribute: attribute,
            relatedBy: .Equal,
            toItem: item,
            attribute: attribute,
            multiplier: 1.0,
            constant: 0.0
        )
    }
}