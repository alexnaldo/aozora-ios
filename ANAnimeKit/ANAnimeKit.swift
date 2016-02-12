//
//  ANAnimeKit.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/9/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

public class ANAnimeKit {
    
    public class func threadStoryboard() -> UIStoryboard {
        return UIStoryboard(name: "Thread", bundle: nil)
    }
    
    public class func rootTabBarController() -> CustomTabBarController {
        let tabBarController = UIStoryboard(name: "Anime", bundle: nil).instantiateInitialViewController() as! CustomTabBarController
        return tabBarController
    }
    
    public class func profileViewController() -> ProfileViewController {
        let controller = UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("ProfileViewController") as! ProfileViewController
        return controller
    }
    
    public class func animeForumViewController() -> (UINavigationController,ForumViewController) {
        let controller = UIStoryboard(name: "Forum", bundle: nil).instantiateInitialViewController() as! UINavigationController
        return (controller,controller.viewControllers.last! as! ForumViewController)
    }
    
    public class func customThreadViewController() -> CustomThreadViewController {
        let controller = UIStoryboard(name: "Thread", bundle: nil).instantiateViewControllerWithIdentifier("CustomThread") as! CustomThreadViewController
        return controller
    }
    
    public class func notificationThreadViewController() -> (UINavigationController, NotificationThreadViewController) {
        let controller = UIStoryboard(name: "Notifications", bundle: nil).instantiateViewControllerWithIdentifier("NotificationThreadNav") as! UINavigationController
        return (controller, controller.viewControllers.last! as! NotificationThreadViewController)
    }
    
    class func searchViewController() -> (UINavigationController, SearchViewController) {
        let navigation = UIStoryboard(name: "Browse", bundle: nil).instantiateViewControllerWithIdentifier("NavSearch") as! UINavigationController
        navigation.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        
        let controller = navigation.viewControllers.last as! SearchViewController
        return (navigation, controller)
    }

    public class func commentStoryboard() -> UIStoryboard {
        return UIStoryboard(name: "Comment", bundle: nil)
    }

    public class func newPostViewController() -> NewPostViewController {
        let controller = commentStoryboard().instantiateViewControllerWithIdentifier("NewPost") as! NewPostViewController
        return controller
    }

    public class func newThreadViewController() -> NewThreadViewController {
        let controller = commentStoryboard().instantiateViewControllerWithIdentifier("NewThread") as! NewThreadViewController
        return controller
    }

    public class func loginViewController() -> LoginViewController {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let loginController = storyboard.instantiateInitialViewController() as! LoginViewController
        return loginController
    }

    public class func webViewController() -> (UINavigationController,WebBrowserViewController) {
        let controller = UIStoryboard(name: "WebBrowser", bundle: NSBundle(forClass: self)).instantiateInitialViewController() as! UINavigationController
        return (controller,controller.viewControllers.last! as! WebBrowserViewController)
    }

    public class func shortClassification(classification: String) -> String {

        switch classification {
        case "None":
            return "?"
        case "G - All Ages":
            return "G"
        case "PG-13 - Teens 13 or older":
            return "PG-13"
        case "R - 17+ (violence & profanity)":
            return "R17+"
        case "Rx - Hentai":
            return "Rx"
        default:
            return "?"
        }

    }
}