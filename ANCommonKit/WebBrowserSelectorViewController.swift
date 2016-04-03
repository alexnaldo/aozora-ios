//
//  WebBrowserSelectorViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/6/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import WebKit
import ANCommonKit

public protocol WebBrowserSelectorViewControllerDelegate: class {
    func WebBrowserSelectorViewControllerSelectedSite(siteURL: String)
}

public class WebBrowserSelectorViewController: WebBrowserViewController {
    
    public weak var delegate: WebBrowserSelectorViewControllerDelegate?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Insert UIBarButtonAction
        let selectBBI = UIBarButtonItem(title: "Select", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(WebBrowserSelectorViewController.selectedWebSite(_:)))
        navigationItem.rightBarButtonItem = selectBBI
    }
    
    func selectedWebSite(sender: AnyObject) {
        if let urlString = webView.URL?.absoluteString {
            delegate?.WebBrowserSelectorViewControllerSelectedSite(urlString)
        }
        dismissViewControllerAnimated(true, completion: nil)
    }

}
