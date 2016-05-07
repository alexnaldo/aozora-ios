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
    case MALLogin
    case Anime
    case Rate
    case Forum
    case Library

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

    static func animeDetailsTabBarController() -> AnimeDetailsTabBarController {
        return Storyboard.Anime.viewControllerWithClass(AnimeDetailsTabBarController)
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

    static func threadViewController() -> ThreadViewController {
        return Storyboard.Thread.viewControllerWithClass(ThreadViewController)
    }

    static func malLoginViewController() -> MALLoginViewController {
        return Storyboard.MALLogin.viewControllerWithClass(MALLoginViewController)
    }

    static func webBrowserViewController() -> WebBrowserViewController {
        return Storyboard.WebBrowser.viewControllerWithClass(WebBrowserViewController)
    }

    static func animeForumViewController() -> UINavigationController {
        return Storyboard.Forum.navigationControllerForViewControllerWithClass(ForumViewController)
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

    static func publicListViewController() -> PublicListViewController {
        return Storyboard.Library.viewControllerWithClass(PublicListViewController)
    }

    static func editProfileViewController() -> EditProfileViewController {
        return Storyboard.Profile.viewControllerWithClass(EditProfileViewController)
    }

}

