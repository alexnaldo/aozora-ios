//
//  Storyboard+Aozora.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 2/12/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import UIKit

enum Storyboard: String {
    case Onboarding
    case Home
    case Browser
    case Forums
    case Browse
    case Settings
    case InApp
    case Profile
    case Notifications
    case Thread
    case Comment
    case Search
    case WebBrowser
    case Login
    case Anime
    case Rate
    case Forum

    func storyboard() -> UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: nil)
    }

    private func viewControllerWithClass<T>(className: T.Type) -> T {
        let identifier = String(className)
        return storyboard().instantiateViewControllerWithIdentifier(identifier) as! T
    }

    private func navigationControllerForViewControllerWithClass<T>(className: T.Type) -> UINavigationController {
        let identifier = String(className)
        return storyboard().instantiateViewControllerWithIdentifier("\(identifier)Nav") as! UINavigationController
    }

    static func profileViewController() -> ProfileViewController {
        return Storyboard.Profile.viewControllerWithClass(ProfileViewController)
    }

    static func newThreadViewController() -> NewThreadViewController {
        return Storyboard.Comment.viewControllerWithClass(NewThreadViewController)
    }

    static func newPostViewController() -> NewPostViewController {
        return Storyboard.Comment.viewControllerWithClass(NewPostViewController)
    }

    static func customTabBarController() -> CustomTabBarController {
        return Storyboard.Anime.viewControllerWithClass(CustomTabBarController)
    }

    static func imageViewController() -> ImageViewController {
        return Storyboard.Comment.viewControllerWithClass(ImageViewController)
    }

    static func searchViewController() -> SearchViewController {
        return Storyboard.Search.viewControllerWithClass(SearchViewController)
    }

    static func searchViewControllerNav() -> UINavigationController {
        return Storyboard.Search.navigationControllerForViewControllerWithClass(SearchViewController)
    }

    static func customThreadViewController() -> CustomThreadViewController {
        return Storyboard.Thread.viewControllerWithClass(CustomThreadViewController)
    }

    static func loginViewController() -> LoginViewController {
        return Storyboard.Login.viewControllerWithClass(LoginViewController)
    }

    static func webBrowserViewControllerNav() -> UINavigationController {
        return Storyboard.WebBrowser.navigationControllerForViewControllerWithClass(WebBrowserViewController)
    }

    static func animeForumViewController() -> UINavigationController {
        return Storyboard.Forum.navigationControllerForViewControllerWithClass(ForumViewController)
    }

    static func notificationThreadViewController() -> NotificationThreadViewController {
        return Storyboard.Notifications.viewControllerWithClass(NotificationThreadViewController)
    }

    static func tagsViewController() -> TagsViewController {
        return Storyboard.Comment.viewControllerWithClass(TagsViewController)
    }

    static func imagesViewController() -> ImagesViewController {
        return Storyboard.Comment.viewControllerWithClass(ImagesViewController)
    }

    static func webBrowserSelectorViewControllerNav() -> UINavigationController {
        return Storyboard.Comment.navigationControllerForViewControllerWithClass(WebBrowserSelectorViewController)
    }


    static func filterViewController() -> FilterViewController {
        return Storyboard.Browse.viewControllerWithClass(FilterViewController)
    }

    static func userListViewController() -> UserListViewController {
        return Storyboard.Profile.viewControllerWithClass(UserListViewController)
    }
}

