    //
//  ReminderController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/24/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANCommonKit

public class ReminderController {
    public class func scheduleReminderForAnime(anime: Anime) -> Bool {
        
        guard let nextEpisode = anime.nextEpisode else {
            return false
        }

        let notificationDate = anime.nextEpisodeDate
        
        var message: String = ""
        if nextEpisode == 1 {
            message = "\(anime.title!) first episode airing today!"
        } else {
            message = "\(anime.title!) ep \(nextEpisode) airing today"
        }
        
        let infoDictionary = ["objectID": anime.myAnimeListID]
        
        let localNotification = UILocalNotification()
        localNotification.fireDate = notificationDate
        localNotification.timeZone = NSTimeZone.defaultTimeZone()
        localNotification.alertBody = message
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.userInfo = infoDictionary as [NSObject : AnyObject]
        
        // This is to prevent it to expire
        localNotification.repeatInterval = .Year
        
        print("Scheduled notification: '" + message + "' for date \(notificationDate)")
        
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
        
        return true
    }
    
    public class func disableReminderForAnime(anime: Anime) {
        
        if let notificationToDelete = ReminderController.scheduledReminderFor(anime) {
            UIApplication.sharedApplication().cancelLocalNotification(notificationToDelete)
        }
    }
    
    public class func scheduledReminderFor(anime: Anime) -> UILocalNotification? {
        guard let scheduledNotifications = UIApplication.sharedApplication().scheduledLocalNotifications else {
            return nil
        }

        let matchingNotifications = scheduledNotifications.filter{ (notification: UILocalNotification) -> Bool in
            let objectID = notification.userInfo as! [String: AnyObject]
            return objectID["objectID"] as! Int == anime.myAnimeListID
        }
        return matchingNotifications.last
    }
    
    public class func updateScheduledLocalNotifications() {
        
        // Update titles, fire dates and disable notifications
        guard let scheduledNotifications = UIApplication.sharedApplication().scheduledLocalNotifications else {
            return
        }

        UIApplication.sharedApplication().cancelAllLocalNotifications()
            
        let idList: [Int] = scheduledNotifications
            .flatMap{ $0.userInfo as? [String: AnyObject] }
            .flatMap{ $0["objectID"] as? Int }
        
        let query = Anime.query()!
        query.whereKey("myAnimeListID", containedIn: idList)
        query.limit = 2000
        query.findObjectsInBackground()
            .continueWithExecutor(BFExecutor.mainThreadExecutor(), withSuccessBlock: { (task: BFTask!) -> AnyObject! in
                
                guard let animeList = task.result as? [Anime] else {
                    return nil
                }
                
                LibrarySyncController.matchAnimeWithProgress(animeList)
                
                for anime in animeList {
                    if let progress = anime.progress where progress.myAnimeListList() != .Dropped {
                        self.scheduleReminderForAnime(anime)
                    }
                }  
                return nil
            })

    }
    
}