//
//  NotificationViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 9/7/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANCommonKit
import XLPagerTabStrip  

protocol NotificationsViewControllerDelegate: class {
    func notificationsViewControllerHasUnreadNotifications(count: Int)
    func notificationsViewControllerClearedAllNotifications()
}

class NotificationsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var fetchController = FetchController()
    var animator: ZFModalTransitionAnimator!
    
    weak var delegate: NotificationsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 112.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(fetchNotifications), name: "newNotification", object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        tableView.userInteractionEnabled = true
    }

    deinit {
        fetchController.tableView = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func fetchNotifications() {
        guard let currentUser = User.currentUser() else {
            return
        }

        let query = Notification.query()!
        query.includeKey("lastTriggeredBy")
        query.includeKey("triggeredBy")
        query.includeKey("owner")
        query.includeKey("readBy")
        query.whereKey("subscribers", containedIn: [currentUser])
        query.orderByDescending("lastUpdatedAt")
        fetchController.configureWith(self, query: query, queryDelegate:self, tableView: tableView, limit: 30)
    }
    
    func clearAllPressed(sender: AnyObject) {
        let unreadNotifications = fetchController.dataSource.filter { (notification: PFObject) -> Bool in
            
            let notification = notification as! Notification
            guard !notification.readBy.contains(User.currentUser()!) else {
                return false
            }
            
            notification.addUniqueObject(User.currentUser()!, forKey: "readBy")
            return true
        }
        
        if unreadNotifications.count != 0 {
            PFObject.saveAllInBackground(unreadNotifications)
            tableView.reloadData()
        }
        
        delegate?.notificationsViewControllerClearedAllNotifications()
    }
    
    func updateUnreadNotifications() {
        guard let currentUser = User.currentUser() else {
            return
        }
        
        var unreadNotifications = 0
        for index in 0..<fetchController.dataCount() {
            guard let notification = fetchController.objectAtIndex(index, viewed: false) as? Notification else {
                continue
            }
            if !notification.readBy.contains(currentUser) {
                unreadNotifications += 1
            }
        }
        
        delegate?.notificationsViewControllerHasUnreadNotifications(unreadNotifications)
    }
    
    
    @IBAction func searchPressed(sender: AnyObject) {
        if let tabBar = tabBarController {
            tabBar.presentSearchViewController(.AllAnime)
        }
    }
}

extension NotificationsViewController: UITableViewDataSource {
   
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchController.dataCount()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let notification = fetchController.objectAtIndex(indexPath.row) as! Notification
        
        let cell = tableView.dequeueReusableCellWithIdentifier("NotificationCell") as! BasicTableCell
        
        if notification.lastTriggeredBy.isTheCurrentUser() {
            var selectedUser = notification.lastTriggeredBy
            for user in notification.triggeredBy where !user.isTheCurrentUser() {
                selectedUser = user
                break
            }
            if let avatarThumb = selectedUser.avatarThumb {
                cell.titleimageView.setImageWithPFFile(avatarThumb)
            } else {
                cell.titleimageView.image = UIImage(named: "default-avatar")
            }
            
        } else {
            if let avatarThumb = notification.lastTriggeredBy.avatarThumb {
                cell.titleimageView.setImageWithPFFile(avatarThumb)
            } else {
                cell.titleimageView.image = UIImage(named: "default-avatar")
            }
        }

        if notification.owner.isTheCurrentUser() {
            cell.titleLabel.text = notification.messageOwner
        } else if notification.lastTriggeredBy.isTheCurrentUser() {
            cell.titleLabel.text = notification.previousMessage ?? notification.message
        } else {
            cell.titleLabel.text = notification.message
        }
        
        if notification.readBy.contains(User.currentUser()!) {
            cell.contentView.backgroundColor = UIColor.backgroundWhite()
        } else {
            cell.contentView.backgroundColor = UIColor.backgroundDarker()
        }
        
        cell.subtitleLabel.text = (notification.lastUpdatedAt ?? notification.updatedAt!).timeAgo()
        cell.layoutIfNeeded()
        return cell
    }
}

extension NotificationsViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Open
        let notification = fetchController.objectAtIndex(indexPath.row) as! Notification
        
        if !notification.readBy.contains(User.currentUser()!) {
            // The actual save of this change happens on `handleNotification`
            notification.addUniqueObject(User.currentUser()!, forKey: "readBy")
            tableView.reloadData()
        }
        
        // Prevents opening the notification twice
        tableView.userInteractionEnabled = false
        NotificationsController
            .handleNotification(notification.objectId!, objectClass: notification.targetClass, objectId: notification.targetID, returnAnimator: true)
            .continueWithBlock { (task: BFTask!) -> AnyObject? in
            
            if let animator = task.result as? ZFModalTransitionAnimator {
                self.animator = animator
            }
            return nil
        }
        
        updateUnreadNotifications()
    }
}

extension NotificationsViewController: FetchControllerQueryDelegate {
    func resultsForSkip(skip skip: Int) -> BFTask? {
        return nil
    }
    func processResult(result result: [PFObject], dataSource: [PFObject]) -> [PFObject] {
        let filtered = result.filter({ (object: PFObject) -> Bool in
            let notification = object as! Notification
            return notification.triggeredBy.count > 1 || (notification.triggeredBy.count == 1 && !notification.triggeredBy.last!.isTheCurrentUser())
        })
        return filtered
    }
}

extension NotificationsViewController: FetchControllerDelegate {
    func didFetchFor(skip skip: Int) {
        updateUnreadNotifications()
        tableView?.reloadData()
    }
}

// MARK: - IndicatorInfoProvider
extension NotificationsViewController: IndicatorInfoProvider {

    func indicatorInfoForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Notifications")
    }
}
