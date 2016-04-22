//
//  ForumViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/16/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit
import iAd

extension ForumViewController: StatusBarVisibilityProtocol {
    func shouldHideStatusBar() -> Bool {
        return false
    }
    func updateCanHideStatusBar(canHide: Bool) {
    }
}

extension ForumViewController: CustomAnimatorProtocol {
    func scrollView() -> UIScrollView? {
        return tableView
    }
}

public class ForumViewController: AnimeBaseViewController {

    @IBOutlet weak var newThreadButton: UIButton!
    @IBOutlet weak public var navigationBar: UINavigationItem!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.estimatedRowHeight = 150.0
            tableView.rowHeight = UITableViewAutomaticDimension
        }
    }

    var dataSource: [Thread] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    var loadingView: LoaderView!
    var fetchController = FetchController()
    var animator: ZFModalTransitionAnimator!

    public override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.title = "Discussion"
        newThreadButton.setTitle("New anime thread", forState: .Normal)
        
        loadingView = LoaderView(parentView: view)
        loadingView.startAnimating()
        fetchAnimeRelatedThreads()
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        customTabBar.setCurrentViewController(self)
    }
    
    func fetchAnimeRelatedThreads() {
        
        let query = Thread.query()!
        query.whereKey("tags", containedIn: [anime])
        query.includeKey("tags")
        query.includeKey("anime")
        query.includeKey("startedBy")
        query.includeKey("lastPostedBy")
        fetchController.configureWith(self, query: query, tableView: tableView, limit: 100)
    }
    
    @IBAction func createAnimeThread(sender: AnyObject) {
        
        if User.currentUserLoggedIn() {
            let comment = Storyboard.newThreadViewController()
            comment.initWith(threadType: .Custom, delegate: self, anime: anime)
            animator = presentViewControllerModal(comment)
        } else {
            presentBasicAlertWithTitle("Login first", message: "Select 'Me' tab to login", style: .Alert)
        }
    }
}

extension ForumViewController: UITableViewDataSource {
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return fetchController.dataCount()
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("TopicCell") as! TopicCell
        
        let thread = fetchController.objectAtIndex(indexPath.row) as! Thread
        let title = thread.title
        
        if let _ = thread.episode {
            cell.typeLabel.text = " "
        } else {
            cell.typeLabel.text = ""
        }
        
        cell.title.text = title
        let lastPostedByUsername = thread.lastPostedBy?.aozoraUsername ?? ""
        cell.information.text = "\(thread.replyCount) comments · \(thread.updatedAt!.timeAgo()) · \(lastPostedByUsername)"
        cell.layoutIfNeeded()
        return cell
    }
    
}

extension ForumViewController: UITableViewDelegate {
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let tabBar = tabBarController as? AnimeDetailsTabBarController {
            tabBar.disableDragDismiss()
        }
        
        let thread = fetchController.objectAtIndex(indexPath.row) as! Thread
        
        let threadController = Storyboard.customThreadViewController()
        if let episode = thread.episode, let anime = thread.anime  {
            threadController.initWithEpisode(episode, anime: anime)
        } else {
            threadController.initWithThread(thread)
        }
        
        navigationController?.pushViewController(threadController, animated: true)
    }
}

extension ForumViewController: FetchControllerDelegate {
    public func didFetchFor(skip skip: Int) {
        self.loadingView.stopAnimating()
    }
}

extension ForumViewController: CommentViewControllerDelegate {
    public func commentViewControllerDidFinishedPosting(post: PFObject, parentPost: PFObject?, edited: Bool) {
        fetchAnimeRelatedThreads()
    }
}