//
//  CustomTabBar.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/9/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit

public class RootTabBar: UITabBarController {
    public static let LastOpenTab = "Defaults.LastOpenTab"
    public static let ShowedMyAnimeListLoginDefault = "Defaults.ShowedMyAnimeListLogin"
    
    var selectedDefaultTabOnce = false
    var chechedForNotificationsOnce = false
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Load library
        LibraryController.sharedInstance.fetchAnimeList(false)
            .continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { task -> AnyObject? in
                FriendsController.sharedInstance.fetchFollowers()
                FriendsController.sharedInstance.fetchFollowing()
                return nil
            })
        
        delegate = self
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if !selectedDefaultTabOnce {
            selectedDefaultTabOnce = true
            if let value = NSUserDefaults.standardUserDefaults().valueForKey(RootTabBar.LastOpenTab) as? Int {
                selectedIndex = value

                Analytics.viewedRootTabTab(number: value)
            }
        }
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if !chechedForNotificationsOnce {
            chechedForNotificationsOnce = true
            checkIfThereAreNotifications()
        }
    }
    
    func updateUnreadNotificationCount(count: Int) {
        var result: String? = nil
        if count > 0 {
            result = "\(count)"
        }
        
        tabBar.items?[3].badgeValue = result
        UIApplication.sharedApplication().applicationIconBadgeNumber = count
    }
    
    func checkIfThereAreNotifications() {
        if let navController = viewControllers![3] as? UINavigationController,
            let notificationVC = navController.viewControllers.first as? BaseNotificationViewController {
            notificationVC.fetchNotifications()
        }
    }
}

// MARK: - NotificationsViewControllerDelegate
extension RootTabBar: NotificationsViewControllerDelegate {
    func notificationsViewControllerHasUnreadNotifications(count: Int) {
        updateUnreadNotificationCount(count)
    }
    func notificationsViewControllerClearedAllNotifications() {
        updateUnreadNotificationCount(0)
    }
}

extension RootTabBar: UITabBarControllerDelegate {
    public func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {

        if let navController = viewController as? UINavigationController {
            
            let profileController = navController.viewControllers.first as? ProfileViewController
            let libraryController = navController.viewControllers.first as? AnimeLibraryViewController
            
            if profileController == nil && libraryController == nil {
                return true
            }
            
            if User.currentUserIsGuest() {
                let onboarding = UIStoryboard(name: "Onboarding", bundle: nil).instantiateInitialViewController() as! OnboardingViewController
                onboarding.isInWindowRoot = false
                presentViewController(onboarding, animated: true, completion: nil)
                return false
            }
            
            if let _ = libraryController where !NSUserDefaults.standardUserDefaults().boolForKey(RootTabBar.ShowedMyAnimeListLoginDefault) {
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: RootTabBar.ShowedMyAnimeListLoginDefault)
                NSUserDefaults.standardUserDefaults().synchronize()

                let loginController = Storyboard.malLoginViewController()
                loginController.delegate = self
                presentViewController(loginController, animated: true, completion: nil)
                return false
                
            }
        }
        
        return true
    }

    public func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        // Update the selected index
        Analytics.viewedRootTabTab(number: selectedIndex)
        NSUserDefaults.standardUserDefaults().setObject(selectedIndex, forKey: RootTabBar.LastOpenTab)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}

extension RootTabBar: MALLoginViewControllerDelegate {
    public func loginViewControllerPressedDoesntHaveAnAccount() {
        selectedIndex = 2
    }
}