//
//  AnimeLibraryViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/21/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit
import XLPagerTabStrip

class BaseNotificationViewController: ButtonBarPagerTabStripViewController {

    let notifications = UIStoryboard(name: "Notifications", bundle: nil).instantiateViewControllerWithIdentifier("NotificationsViewController") as! NotificationsViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        buttonBarView.selectedBar.backgroundColor = UIColor.completed()
        settings.style.buttonBarItemBackgroundColor = .clearColor()
        settings.style.buttonBarItemFont = .boldSystemFontOfSize(14)
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarItemTitleColor = .whiteColor()
        settings.style.buttonBarItemsShouldFillAvailiableWidth = true
        settings.style.buttonBarLeftContentInset = 0
        settings.style.buttonBarRightContentInset = 0
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        canDisplayBannerAds = InAppController.canDisplayAds()
    }

    func fetchNotifications() {
        notifications.fetchNotifications()
    }
    
    // MARK: - XLPagerTabStripViewControllerDataSource

    override func viewControllersForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {

        // Initialize controllers
        let announcements = UIStoryboard(name: "Notifications", bundle: nil).instantiateViewControllerWithIdentifier("AnnouncementsViewController") as! AnnouncementsViewController
        return [notifications, announcements]
    }

    // MARK: - IBActions
    
    @IBAction func readAllPressed(sender: AnyObject) {
        notifications.clearAllPressed(sender)
    }

    @IBAction func presentSearchPressed(sender: AnyObject) {
        
        guard let tabBar = tabBarController else {
            return
        }

        tabBar.presentSearchViewController(.AllAnime)
    }
}
