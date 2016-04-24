//
//  UIViewController+Alert.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/7/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation

extension UIViewController {
    public func presentAlertWithTitle(title: String, message: String? = nil, style: UIAlertControllerStyle = .Alert) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    public func didOnce(actionID: String) -> Bool {
        if let _ = NSUserDefaults.standardUserDefaults().objectForKey(actionID) {
            // Did before
            return true
        } else {
            NSUserDefaults.standardUserDefaults().setObject(true, forKey: actionID)
            NSUserDefaults.standardUserDefaults().synchronize()
            return false
        }
    }
}