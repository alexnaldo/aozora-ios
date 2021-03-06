//
//  AppDelegate.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 4/29/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit
import XCDYouTubeKit
import iRate
import FBSDKShareKit
import Fabric
import Crashlytics
import ParseFacebookUtilsV4
import MMWormhole
import Keys
import Flurry_iOS_SDK
import NYTPhotoViewer
import PINCache
import PINRemoteImage

struct ParseConfig {
    static var lastFetchedDate: NSDate? = nil

    static func FetchIfNeeded() {
        // Fetches the config at most once every 12 hours per app runtime
        let date: NSDate? = ParseConfig.lastFetchedDate
        let configRefreshInterval: NSTimeInterval = 12.0 * 60.0 * 60.0

        if date == nil || date!.timeIntervalSinceNow * -1.0 > configRefreshInterval {
            PFConfig.getConfigInBackgroundWithBlock(nil)
            ParseConfig.lastFetchedDate = NSDate()
        }
    }

    static func ProfilePopularFeedMinimumLikeCount() -> Int {
        return PFConfig.currentConfig()["Profile_PopularFeed_MinimumLikeCount"] as? Int ?? 5
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let MaximumCacheSize: UInt = 1024 * 1024 * 400
    var window: UIWindow?
    var backgroundTask: UIBackgroundTaskIdentifier!
    
    override class func initialize() -> Void {
        iRate.sharedInstance().promptForNewVersionIfUserRated = true
        iRate.sharedInstance().daysUntilPrompt = 2.0
        iRate.sharedInstance().verboseLogging = false
    }

    func initializeParse() {
        AnimeDetail.registerSubclass()
        AnimeCast.registerSubclass()
        AnimeCharacter.registerSubclass()
        AnimeRelation.registerSubclass()
        AnimeReview.registerSubclass()
        Anime.registerSubclass()
        SeasonalChart.registerSubclass()
        Episode.registerSubclass()
        UserDetails.registerSubclass()
        User.registerSubclass()
        TimelinePost.registerSubclass()
        Thread.registerSubclass()
        Post.registerSubclass()
        AnimeProgress.registerSubclass()
        ThreadTag.registerSubclass()
        Notification.registerSubclass()

        let configuration = ParseClientConfiguration {
            $0.applicationId = AozoraKeys().parseApplicationId()
            $0.clientKey = " "
            //$0.server = "http://8f12bab1.ngrok.io/parse"
            $0.server = AozoraKeys().parseServerURL()
            $0.localDatastoreEnabled = true
        }
        Parse.initializeWithConfiguration(configuration)
        PFUser.enableRevocableSessionInBackground()

        if let currentUser = User.currentUser() {
            Analytics.setSessionDataforUser(currentUser)
            Crashlytics.sharedInstance().setUserEmail(currentUser.email)
            Crashlytics.sharedInstance().setUserIdentifier(currentUser.objectId)
            Crashlytics.sharedInstance().setUserName(currentUser.aozoraUsername)
        }
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        Fabric.with([Crashlytics()])

        Flurry.startSession(AozoraKeys().flurryAPIKey())
        Flurry.addSessionOrigin("App.Initialized.HomeIconPress")

        initializeParse()
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        
        trackPushOpen(application, didFinishLaunchingWithOptions:launchOptions)
        registerForPushNotifications(application)
        customizeAppearance()
    
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        if let _ = User.currentUser() {
            WorkflowController.presentRootTabBar(animated: false)
        } else {
            WorkflowController.presentOnboardingController(true)
        }
        
        makeUpdateChanges()

        PINRemoteImageManager.sharedImageManager().cache.diskCache.byteLimit = MaximumCacheSize
        
        NSUserDefaults.standardUserDefaults().setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {

        }

        return true
    }
    
    func application(application: UIApplication,
        didReceiveRemoteNotification userInfo: [NSObject : AnyObject],
        fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        handleIncomingNotification(userInfo as! [String : AnyObject], completionHandler: completionHandler)
    }
    
    func handleIncomingNotification(userInfo: [String: AnyObject], completionHandler: ((UIBackgroundFetchResult) -> Void)? ) {
        // Extract the notification data
        if let objectClass = userInfo["targetClass"] as? String,
            let objectId = userInfo["targetID"] as? String,
            let notificationId = userInfo["notificationID"] as? String,
            let aps = userInfo["aps"] as? [String: AnyObject],
            let alert = aps["alert"] as? String {
                
                let state = UIApplication.sharedApplication().applicationState;
                if state == UIApplicationState.Background || state == UIApplicationState.Inactive
                {
                    Flurry.addSessionOrigin("App.FromBackground.Notification")
                    NotificationsController.handleNotification(notificationId, objectClass: objectClass, objectId: objectId)
                } else {
                    // Not from background
                    Flurry.addSessionOrigin("App.Initialized.Notification")
                    NotificationsController.instance.broadcastNotification(notificationId, objectClass: objectClass, objectId: objectId, message: alert)
                }
                
                if let completionHandler = completionHandler {
                    completionHandler(UIBackgroundFetchResult.NewData)
                }
                
        } else {
            if let completionHandler = completionHandler {
                completionHandler(UIBackgroundFetchResult.Failed)
            }
        }
    }
    
    func trackPushOpen(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) {
        // Tracking push opens when application is not running nor in background
        if application.applicationState != UIApplicationState.Background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced
            // in iOS 7). In that case, we skip tracking here to avoid double
            // counting the app-open.
            let oldPushHandlerOnly = !self.respondsToSelector(#selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)))
            let noPushPayload: AnyObject? = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey]
            if oldPushHandlerOnly || noPushPayload != nil {
                //PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
            }
        }
    }
    
    func registerForPushNotifications(application: UIApplication) {

        let muteAction = UIMutableUserNotificationAction()
        muteAction.identifier = "MUTE_ACTION"
        muteAction.title = "Mute"
        muteAction.activationMode = UIUserNotificationActivationMode.Background
        muteAction.authenticationRequired = false
        muteAction.destructive = false


        let counterCategory = UIMutableUserNotificationCategory()
        counterCategory.identifier = "NEW_POST_CATEGORY"

        // A. Set actions for the default context
        counterCategory.setActions([muteAction],
        forContext: UIUserNotificationActionContext.Default)

        // B. Set actions for the minimal context
        counterCategory.setActions([muteAction],
        forContext: UIUserNotificationActionContext.Minimal)

        let userNotificationTypes: UIUserNotificationType = ([UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound]);
        
        let settings = UIUserNotificationSettings(
            forTypes: userNotificationTypes,
            categories: NSSet(object: counterCategory) as? Set<UIUserNotificationCategory>
        )
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
    }

    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        // Handle notification action *****************************************
        if let aps = userInfo["aps"] as? [String: AnyObject],
            let category = aps["category"] as? String
            where category == "NEW_POST_CATEGORY" {

            guard let identifier = identifier,
                let userInfo = userInfo as? [String : AnyObject] else {
                return
            }

            switch identifier {
            case "MUTE_ACTION":
                // Mute future notifications
                guard let notificationID = userInfo["notificationID"] as? String,
                    let currentUser = User.currentUser() else {
                    return
                }

                let notification = Notification(outDataWithObjectId: notificationID)
                notification.removeObjectsInArray([currentUser], forKey: "subscribers")
                notification.saveInBackgroundWithBlock({ (result, error) in
                    completionHandler()
                })
            default:
                break;
            }
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            var taskID = application.beginBackgroundTaskWithExpirationHandler { () }
    
            guard let user = User.currentUser() else {
                return
            }
            
            user.active = false
            user.activeEnd = NSDate()
            user.saveInBackgroundWithBlock({ (success, error) -> Void in
                application.endBackgroundTask(taskID)
                taskID = UIBackgroundTaskInvalid
            })
        })
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        if let user = User.currentUser() {
            
            //let isRunningTestFlight = NSBundle.mainBundle().appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
            
            user.active = true
            user.activeStart = NSDate()
            user.saveInBackgroundWithBlock({ (success, error) -> Void in

                guard let error = error where error.domain == PFParseErrorDomain else {
                    return
                }
                
                // Checking for invalid sessions
                if error.code == 209 || error.code == 206 {
                    WorkflowController.logoutUser()
                    WorkflowController.presentOnboardingController(true)
                }
            })
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("newNotification", object: nil)
        FBSDKAppEvents.activateApp()

        ParseConfig.FetchIfNeeded()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // Store the deviceToken in the current Installation and save it to Parse
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.saveInBackground()
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(
        application: UIApplication,
        didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        PFPush.handlePush(userInfo)
        if application.applicationState == .Inactive  {
            // The application was just brought from the background to the foreground,
            // so we consider the app as having been "opened by a push notification."
            //PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
        }
    }
    
    func application(
    application: UIApplication,
    openURL url: NSURL,
    sourceApplication: String?,
    annotation: AnyObject) -> Bool {
            
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    // MARK: - Internal functions

    func customizeAppearance() {
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().barTintColor = UIColor.darkBlue()
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        
        UIToolbar.appearance().tintColor = UIColor.whiteColor()
        UIToolbar.appearance().barTintColor = UIColor.darkBlue()
        
        UITabBar.appearance().tintColor = UIColor.peterRiver()
        UITabBar.appearance().translucent = false
    }
    
    func makeUpdateChanges() {
        // Logout if previous version is installed
        let version120 = "1.2.0-launched"
        
        if User.currentUser() == nil {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: version120)
            NSUserDefaults.standardUserDefaults().synchronize()
            return
        }
        
        if (!NSUserDefaults.standardUserDefaults().boolForKey(version120)) {
            WorkflowController.logoutUser().continueWithExecutor( BFExecutor.mainThreadExecutor(), withSuccessBlock: { (task: BFTask!) -> AnyObject! in
                
                if let error = task.error {
                    print("failed loggin out: \(error)")
                } else {
                    print("logout succeeded")
                }
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: version120)
                NSUserDefaults.standardUserDefaults().synchronize()
                WorkflowController.presentOnboardingController(true)
                return nil
            })
        }
    }
    
    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
        
        let topViewController = UIApplication.topViewController()
        
        if let controller = topViewController as? NYTPhotosViewController where !controller.isBeingDismissed() {
            return UIInterfaceOrientationMask.All
        } else if let controller = topViewController as? XCDYouTubeVideoPlayerViewController where !controller.isBeingDismissed() {
            return UIInterfaceOrientationMask.All
        } else if let controller = topViewController as? ImageViewController where !controller.isBeingDismissed() {
            return UIInterfaceOrientationMask.All
        } else {
            if UIDevice.isPad() {
                return UIInterfaceOrientationMask.All
            } else {
                return UIInterfaceOrientationMask.Portrait
            }
        }
    }
}
