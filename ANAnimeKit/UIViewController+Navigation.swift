//
//  AnimePresenter.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/27/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation

import ANCommonKit
import JTSImageViewController

extension UIViewController {
    
    public func presentAnimeModal(anime: Anime) -> ZFModalTransitionAnimator {
        
        let tabBarController = Storyboard.customTabBarController()
        tabBarController.initWithAnime(anime)
        
        let animator = ZFModalTransitionAnimator(modalViewController: tabBarController)
        animator.dragable = true
        animator.direction = .Bottom
        
        tabBarController.animator = animator
        tabBarController.transitioningDelegate = animator;
        tabBarController.modalPresentationStyle = UIModalPresentationStyle.Custom;
        
        presentViewController(tabBarController, animated: true, completion: nil)
        
        return animator
    }
    
    func presentSearchViewController(searchScope: SearchScope) {
        let navigation = Storyboard.searchViewControllerNav()
        let controller = navigation.viewControllers.first as! SearchViewController
        controller.initWithSearchScope(searchScope)
        presentViewController(navigation, animated: true, completion: nil)
    }
    
}