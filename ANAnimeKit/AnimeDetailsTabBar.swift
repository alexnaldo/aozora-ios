//
//  CustomTabBar.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/9/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit

import ANCommonKit

protocol CustomAnimatorProtocol {
    func scrollView() -> UIScrollView?
}

protocol StatusBarVisibilityProtocol {
    func shouldHideStatusBar() -> Bool
    func updateCanHideStatusBar(canHide: Bool)
}

public class AnimeDetailsTabBarController: UITabBarController {
    
    var anime: Anime!
    public var animator: ZFModalTransitionAnimator!
    
    public func initWithAnime(anime: Anime) {
        self.anime = anime
    }
    
    func setCurrentViewController(controller: CustomAnimatorProtocol) {
        animator.gesture.enabled = true
        animator.setContentScrollView(controller.scrollView())
    }

    func disableDragDismiss() {
        animator.gesture.enabled = false
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Forum view controller
        let forumNavController = Storyboard.animeForumViewController()

        self.viewControllers?.append(forumNavController)
        
        // Update icons frame
        for controller in viewControllers! {
            controller.tabBarItem.imageInsets = UIEdgeInsets(top: 4, left: 0, bottom: -4, right: 0)
        }
        
        delegate = self
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isBeingDismissed() {
            selectedViewControllerCantHideStatusBar()
            
            UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
            UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        }
    }
    
    func selectedViewControllerCantHideStatusBar() {
        let currentNavController = selectedViewController as! UINavigationController
        if let controller = currentNavController.viewControllers.first as? StatusBarVisibilityProtocol {
            controller.updateCanHideStatusBar(false)
        }
        
    }
}

class CustomTabBar: UITabBar {
    override func sizeThatFits(size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = 44
        return sizeThatFits
    }
}

extension AnimeDetailsTabBarController: UITabBarControllerDelegate {
    public func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        
        selectedViewControllerCantHideStatusBar()
        
        let navController = viewController as! UINavigationController
        if let controller = navController.viewControllers.first as? StatusBarVisibilityProtocol {
            
            let hide = controller.shouldHideStatusBar()
            UIApplication.sharedApplication().setStatusBarHidden(hide, withAnimation: UIStatusBarAnimation.None)
        }
        
        return true
    }
}