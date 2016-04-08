//
//  AnimeBaseViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/12/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit

public class AnimeBaseViewController: UIViewController {

    var anime: Anime {
        return customTabBar.anime
    }

    var customTabBar: CustomTabBarController {
        return tabBarController as! CustomTabBarController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _ = tabBarController as? CustomTabBarController {
            
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Stop, target: self, action: #selector(AnimeBaseViewController.dismissViewControllerPressed))
            
            navigationController?.navigationBar.tintColor = UIColor.peterRiver()
            navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
            navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.blackColor()]
        }
    }
    
    func dismissViewControllerPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
