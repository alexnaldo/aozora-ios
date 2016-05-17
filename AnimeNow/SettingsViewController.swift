//
//  SettingsViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/28/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import iRate
import ANCommonKit
import FBSDKShareKit
import ParseFacebookUtilsV4
import RMStore
import uservoice_iphone_sdk

class SettingsViewController: UITableViewController {
    
    let FacebookPageDeepLink = "fb://profile/713541968752502";
    let FacebookPageURL = "https://www.facebook.com/AozoraApp";
    let TwitterPageDeepLink = "twitter://user?id=3366576341";
    let TwitterPageURL = "https://www.twitter.com/AozoraApp";
    
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var linkWithMyAnimeListLabel: UILabel!
    @IBOutlet weak var facebookLikeButton: FBSDKLikeButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        facebookLikeButton.objectID = "https://www.facebook.com/AozoraApp"

        let config = UVConfig(site: "aozora.uservoice.com")
        let email = User.currentUser()?.email ?? "unknown"
        let username = User.currentUser()?.aozoraUsername ?? "unknown"
        let id = User.currentUser()?.objectId ?? "unknown"
        config.identifyUserWithEmail(email, name: username, guid: id)

        if let infoDictionary = NSBundle.mainBundle().infoDictionary,
            let marketingVersion = infoDictionary["CFBundleShortVersionString"],
            let buildNumber = infoDictionary["CFBundleVersion"] {
            config.customFields = ["build": "\(marketingVersion) (\(buildNumber))"]

            UVStyleSheet.instance().navigationBarTextColor = .blackColor()
            UVStyleSheet.instance().navigationBarTintColor = .blackColor()
        }

        UserVoice.initialize(config)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateLoginButton()
    }
    
    func updateLoginButton() {
        let animeApp = AppEnvironment.application().rawValue
        if User.currentUserLoggedIn() {
            // Logged In both
            loginLabel.text = "Logout \(animeApp)"
        } else if User.currentUserIsGuest() {
            // User is guest
            loginLabel.text = "Login \(animeApp)"
        }
        
        if User.syncingWithMyAnimeList() {
            linkWithMyAnimeListLabel.text = "Unlink MyAnimeList"
        } else {
            linkWithMyAnimeListLabel.text = "Sync with MyAnimeList"
        }

    }

    func updateUsername(error: String?) {
        let alert = UIAlertController(title: "Enter your new username", message: error, preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler(nil)
        alert.addAction(UIAlertAction(title: "Update Username", style: .Default, handler: { _ in

            guard let textField = alert.textFields?.last,
                let newUsername = textField.text
                where newUsername.validUsername(self) else {
                    self.updateUsername("Invalid username")
                    return
            }

            let query = User.query()!
            query.whereKey("aozoraUsername", matchesRegex: "^\(newUsername)$", modifiers: "i")
            let query2 = User.query()!
            query2.whereKey("username", equalTo: newUsername.lowercaseString)

            do {
                let result = try PFQuery.orQueryWithSubqueries([query, query2]).findObjects()
                if !result.isEmpty {
                    self.updateUsername("Username '\(newUsername)' already exists")
                    return
                } else if let currentUser = User.currentUser() {

                    InAppPurchaseController
                        .purchaseProductWithID(InAppController.ChangeUsernameIdentifier)
                        .continueWithExecutor(BFExecutor.mainThreadExecutor(),  withSuccessBlock: { (task) -> AnyObject? in

                            currentUser.aozoraUsername = newUsername
                            if !PFFacebookUtils.isLinkedWithUser(currentUser) {
                                currentUser.username = newUsername.lowercaseString
                            }
                            return currentUser.saveInBackground()
                        }).continueWithBlock({ (task) -> AnyObject? in
                            if let _ = task.error {
                                self.updateUsername("Failed updating username")
                            }
                            return nil
                        })
                }
            } catch {
                self.updateUsername("Failed updating username")
            }
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))

        self.presentViewController(alert, animated: true, completion: nil)
    }

    // MARK: - IBActions

    @IBAction func dismissPressed(sender: AnyObject) {
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - TableView functions
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return
        }
        
        switch (indexPath.section, indexPath.row) {
        case (0,0):
            // Login / Logout
            if User.currentUserLoggedIn() {
                // Logged In both, logout
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
                alert.popoverPresentationController?.sourceView = cell.superview
                alert.popoverPresentationController?.sourceRect = cell.frame
                let animeApp = AppEnvironment.application().rawValue
                alert.addAction(UIAlertAction(title: "Logout \(animeApp)", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
                    
                    WorkflowController.logoutUser().continueWithExecutor( BFExecutor.mainThreadExecutor(), withSuccessBlock: { (task: BFTask!) -> AnyObject! in
                        
                        if let error = task.error {
                            print("failed loggin out: \(error)")
                        } else {
                            print("logout succeeded")
                        }
                        WorkflowController.presentOnboardingController(true)
                        return nil
                    })
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                }))
                
                self.presentViewController(alert, animated: true, completion: nil)
                
            } else if User.currentUserIsGuest() {
                // User is guest, login
                WorkflowController.presentOnboardingController(true)
            }
        case (0,1):
            // Sync with MyAnimeList
            if User.syncingWithMyAnimeList() {
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
                alert.popoverPresentationController?.sourceView = cell.superview
                alert.popoverPresentationController?.sourceRect = cell.frame
                
                alert.addAction(UIAlertAction(title: "Stop syncing with MyAnimeList", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
                    
                    User.logoutMyAnimeList()
                    self.updateLoginButton()
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                }))
                
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                
                let loginController = Storyboard.malLoginViewController()
                presentViewController(loginController, animated: true, completion: nil)
                
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: RootTabBar.ShowedMyAnimeListLoginDefault)
                NSUserDefaults.standardUserDefaults().synchronize()
            }
        case (1,0):
            // Uservoice
            UserVoice.presentUserVoiceInterfaceForParentViewController(self)
        case (2,0):
            // Unlock features
            PurchaseViewController.showInAppPurchaseWith(self)
        case (2,1):
            // Restore purchases
            InAppPurchaseController.restorePurchases().continueWithBlock({ (task: BFTask!) -> AnyObject! in
                
                if let _ = task.result {
                    let alert = UIAlertController(title: "Restored!", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                
                return nil
            })

        case (2,2):

            let products: Set = [InAppController.ChangeUsernameIdentifier]
            RMStore
                .defaultStore()
                .requestProducts(products, success: { (products, invalidProducts) -> Void in
                    self.updateUsername(nil)
            }) { (error) -> Void in

            }
        case (3,0):
            // Rate app
            iRate.sharedInstance().openRatingsPageInAppStore()
        case (4,0):
            // Open Facebook
            var url: NSURL?
            if let twitterScheme = NSURL(string: "fb://requests") where UIApplication.sharedApplication().canOpenURL(twitterScheme) {
                url = NSURL(string: FacebookPageDeepLink)
            } else {
                url = NSURL(string: FacebookPageURL)
            }
            UIApplication.sharedApplication().openURL(url!)
        case (4,1):
            // Open Twitter
            var url: NSURL?
            if let twitterScheme = NSURL(string: "twitter://") where UIApplication.sharedApplication().canOpenURL(twitterScheme) {
                url = NSURL(string: TwitterPageDeepLink)
            } else {
                url = NSURL(string: TwitterPageURL)
            }
            UIApplication.sharedApplication().openURL(url!)
        default:
            break
        }
        
        
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        switch section {
        case 0:
            return nil
        case 1:
            return "Before sending a message, please first read the Knowledge base."
        case 2:
            var message = ""
            if let user = User.currentUser() where
                    user.hasTrial() &&
                    !InAppController.purchasedPro() &&
                    !InAppController.purchasedProPlus() {
                message = "✨ You're on a 15 day PRO trial 🎋 ✨\n"
            }
            message += "Going PRO unlocks all features and help us keep improving the app 👍"
            return message
        case 3:
            return nil
        case 4:
            let version = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
            let build = NSBundle.mainBundle().infoDictionary!["CFBundleVersion"] as! String
            let animeApp = AppEnvironment.application().rawValue
            return "Created by anime fans for anime fans, enjoy!\n\(animeApp) \(version) (\(build))"
        default:
            return nil
        }
    }
}

extension SettingsViewController: ModalTransitionScrollable {
    var transitionScrollView: UIScrollView? {
        return tableView
    }
}