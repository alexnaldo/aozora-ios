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

class ForumViewController: BaseThreadViewController {

    @IBOutlet weak var newThreadButton: UIButton!
    @IBOutlet weak var navigationBar: UINavigationItem!

    var dataSource: [Thread] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    var anime: Anime {
        return customTabBar.anime
    }

    var customTabBar: AnimeDetailsTabBarController {
        return tabBarController as! AnimeDetailsTabBarController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.title = "\(anime.title!) Discussion"
        newThreadButton.setTitle("New post", forState: .Normal)
        
        loadingView = LoaderView(parentView: view)
        loadingView.startAnimating()
        fetchAnimeRelatedThreads()

        threadType = .Threads

        customTabBar.updateNavigationControllerStyle(navigationController)

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Stop, target: self, action: #selector(dismissViewControllerPressed))
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        customTabBar.setCurrentViewController(self)
    }
    
    func fetchAnimeRelatedThreads() {
        
        let query = Thread.query()!
        query.whereKey("tags", containedIn: [anime])
        query.includeKey("tags")
        query.includeKey("anime")
        query.includeKey("episode")
        query.includeKey("startedBy")
        query.includeKey("postedBy")
        query.includeKey("lastPostedBy")
        query.orderByDescending("hotRanking")
        fetchController.configureWith(self, query: query, tableView: tableView, limit: 100)
    }

    func dismissViewControllerPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Actions
    
    @IBAction func createAnimeThread(sender: AnyObject) {
        
        if !User.currentUserLoggedIn() {
            presentAlertWithTitle("Login first", message: "Select 'Me' tab to login")
        }

        let comment = Storyboard.newThreadViewController()
        comment.initWith(threadType: .ThreadPosts, delegate: self, anime: anime)
        animator = presentViewControllerModal(comment)
    }

    // MARK: - Overrides

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        customTabBar.disableDragDismiss()
    }

    // MARK: - Override CommentViewControllerDelegate

    override func commentViewControllerDidFinishedPosting(post: PFObject, parentPost: PFObject?, edited: Bool) {
        fetchAnimeRelatedThreads()
    }
}
