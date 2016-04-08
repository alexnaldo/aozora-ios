//
//  AnimePresenter.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/27/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import JTSImageViewController

public protocol ModalTransitionScrollable {
    var transitionScrollView: UIScrollView? { get }
}

extension ModalTransitionScrollable {
    public func updateTransitionScrollView(animator: ZFModalTransitionAnimator) {
        if let transitionScrollView = transitionScrollView {
            animator.setContentScrollView(transitionScrollView)
        }
    }
}

// Allows to update the ScrollView
public protocol ModalTransitionMultiScrollable: ModalTransitionScrollable {
    var animator: ZFModalTransitionAnimator! { get set }
}

extension ModalTransitionMultiScrollable {
    public func updateTransitionScrollView() {
        if let transitionScrollView = transitionScrollView {
            animator.setContentScrollView(transitionScrollView)
        }
    }
}

extension UIViewController {
    
    public func presentViewControllerModal(controller: UIViewController) -> ZFModalTransitionAnimator {
        
        let animator = ZFModalTransitionAnimator(modalViewController: controller)
        animator.dragable = true
        animator.direction = .Bottom

        controller.transitioningDelegate = animator
        controller.modalPresentationStyle = .Custom
        
        presentViewController(controller, animated: true) { _ in
            var animatedController = controller
            if let navController = animatedController as? UINavigationController,
                let viewController = navController.viewControllers.last {
                animatedController = viewController
            }
            
            if let controller = animatedController as? ModalTransitionScrollable {
                controller.updateTransitionScrollView(animator)
                
                if var controller = controller as? ModalTransitionMultiScrollable {
                    controller.animator = animator
                }
            }
        }
        
        return animator
    }

    public func presentAnimeModal(anime: Anime, callback: ((CustomTabBarController) -> Void)? = nil) -> ZFModalTransitionAnimator {

        let tabBarController = Storyboard.customTabBarController()
        tabBarController.initWithAnime(anime)
        callback?(tabBarController)

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