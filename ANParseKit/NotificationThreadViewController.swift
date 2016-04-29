//
//  AnimeThreadViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/8/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import TTTAttributedLabel
import ANCommonKit

class NotificationThreadViewController: ThreadViewController {
    
    @IBOutlet weak var viewMoreButton: UIButton!
    var timelinePost: TimelinePostable?
    var post: ThreadPostable?
    
    func initWithPost(post: Postable) {
        if let timelinePost = post as? TimelinePostable {
            self.timelinePost = timelinePost
        } else if let threadPost = post as? ThreadPostable {
            self.post = threadPost
            self.thread = threadPost.thread
        }
        self.threadType = .Custom
        self.replyConfiguration = .ShowCreateReply
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let _ = timelinePost {
            // Fetch posts, if not a thread
            tableView.tableHeaderView = nil
            fetchPosts()
        } else if let _ = post {
            // Other class will call fetchPosts...
            viewMoreButton.setTitle("View Thread  ", forState: .Normal)
        }
    }
    
    override func updateUIWithThread(thread: Thread) {
        super.updateUIWithThread(thread)
        
        title = "Loading..."
        
        if thread.locked {
            navigationItem.rightBarButtonItem?.enabled = false
        }
    }
    
    override func fetchPosts() {
        super.fetchPosts()
        fetchController.configureWith(self, queryDelegate: self, tableView: tableView, limit: FetchLimit, datasourceUsesSections: true)
    }
    
    // MARK: - FetchControllerQueryDelegate
    
    override func resultsForSkip(skip skip: Int) -> BFTask? {

        let queryBatch = QueryBatch()

        var query: PFQuery!
        var repliesQuery: PFQuery!
        if let timelinePost = timelinePost as? TimelinePost {
            query = TimelinePost.query()!
            query.whereKey("objectId", equalTo: timelinePost.objectId!)
            
            repliesQuery = TimelinePost.query()!
        } else if let post = post as? Post {
            query = Post.query()!
            query.whereKey("objectId", equalTo: post.objectId!)
            
            repliesQuery = Post.query()!
        }
        
        query.includeKey("postedBy")
        query.includeKey("userTimeline")
        
        repliesQuery.skip = 0
        repliesQuery.orderByAscending("createdAt")
        repliesQuery.includeKey("postedBy")
        repliesQuery.limit = 2000
        queryBatch.whereQuery(repliesQuery, matchesKey: "parentPost", onQuery: query)
        
        return queryBatch.executeQueries([query, repliesQuery])
    }

    
    // MARK: - CommentViewControllerDelegate

    override func commentViewControllerDidFinishedPosting(post: PFObject, parentPost: PFObject?, edited: Bool) {
        super.commentViewControllerDidFinishedPosting(post, parentPost: parentPost, edited: edited)
        
        if edited {
            // Don't insert if edited
            tableView.reloadData()
            return
        }
        
        if let parentPost = parentPost {
            // Inserting a new reply in-place
            let parentPost = parentPost as! Commentable
            parentPost.replies.append(post)
            tableView.reloadData()
        } else if parentPost == nil {
            // Inserting a new post in the bottom, if we're in the bottom of the thread
            if !fetchController.canFetchMoreData {
                fetchController.dataSource.append(post)
                tableView.reloadData()
            }
        }
    }

    
    // MARK: - FetchControllerDelegate

    override func didFetchFor(skip skip: Int) {
        super.didFetchFor(skip: skip)
        let post = fetchController.objectInSection(0)
        if let post = post as? TimelinePostable {
            navigationItem.title = post.userTimeline.aozoraUsername
        } else if let post = post as? ThreadPostable {
            navigationItem.title = "In " + post.thread.title
        }
    }
    
    // MARK: - IBAction

    @IBAction func replyToPostPressed(sender: AnyObject) {
        super.replyToPost(post ?? timelinePost!)
    }
    
    override func replyToThreadPressed(sender: AnyObject) {
        super.replyToThreadPressed(sender)
        
        if let thread = thread where User.currentUserLoggedIn() {
            let comment = Storyboard.newPostViewController()
            comment.initWith(thread, threadType: threadType, delegate: self)
            presentViewController(comment, animated: true, completion: nil)
        } else if let thread = thread where thread.locked {
            presentAlertWithTitle("Thread is locked", message: nil)
        } else {
            presentAlertWithTitle("Login first", message: "Select 'Me' tab")
        }
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let _ = timelinePost {
            return CGFloat.min
        } else {
            return super.tableView(tableView, heightForHeaderInSection: section)
        }
    }
    
    @IBAction func openUserProfile(sender: AnyObject) {
        if let startedBy = thread?.startedBy {
            openProfile(startedBy)
        }
    }
    
    @IBAction func dismissViewController(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func viewAllPostsPressed(sender: AnyObject) {
        if let timelinePost = timelinePost {
            openProfile(timelinePost.userTimeline)
            
        } else if let _ = post, let thread = thread {
            let threadController = Storyboard.customThreadViewController()
            if let episode = thread.episode, let anime = thread.anime {
                threadController.initWithEpisode(episode, anime: anime)
            } else {
                threadController.initWithThread(thread, replyConfiguration: .ShowCreateReply)
            }
            
            navigationController?.pushViewController(threadController, animated: true)
        }
    }
}


extension NotificationThreadViewController: UINavigationBarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
}
