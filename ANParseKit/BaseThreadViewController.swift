//
//  BaseThreadViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/7/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit
import TTTAttributedLabel
import XCDYouTubeKit

enum ThreadConfiguration {
    case ThreadDetail
    case ThreadMain
}

public enum ThreadType {
    case Threads
    case ThreadPosts
    case Episode
    case Post
    case Timeline
}

// Class intended to be subclassed
class BaseThreadViewController: UIViewController {
   
    let FetchLimit = 12
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.alpha = 0.0
            tableView.estimatedRowHeight = 112.0
            tableView.rowHeight = UITableViewAutomaticDimension

            PostCell.registerNibFor(tableView: tableView)
            PostUrlCell.registerNibFor(tableView: tableView)
            CommentCell.registerNibFor(tableView: tableView)
            WriteACommentCell.registerNibFor(tableView: tableView)
            ShowMoreCell.registerNibFor(tableView: tableView)
            ThreadCell.registerNibFor(tableView: tableView)
            ThreadURLCell.registerNibFor(tableView: tableView)
        }
    }
    
    var thread: Thread?
    var timelinePost: TimelinePostable?
    var post: ThreadPostable?

    var mainPost: Postable? {
        if let post = post as? Postable {
            return post
        } else if let post = timelinePost as? Postable {
            return post
        } else if let post = thread as? Postable {
            return post
        } else {
            return nil
        }
    }

    var threadType: ThreadType = .ThreadPosts
    var threadConfiguration: ThreadConfiguration = .ThreadMain
    
    var fetchController = FetchController()
    var refreshControl = UIRefreshControl()
    var loadingView: LoaderView!
    
    var animator: ZFModalTransitionAnimator!
    var playerController: XCDYouTubeVideoPlayerViewController?

    var baseWidth: CGFloat {
        get {
            if UIDevice.isPad() {
                return 600
            } else {
                return view.bounds.size.width
            }
        }
    }

    func initWithPost(post: Postable, threadConfiguration: ThreadConfiguration) {
        if let timelinePost = post as? TimelinePostable {
            self.timelinePost = timelinePost
            threadType = .Timeline
        } else if let threadPost = post as? ThreadPostable {
            self.post = threadPost
            self.thread = threadPost.thread
            threadType = .Post
        } else if let thread = post as? Thread {
            self.thread = thread
            switch thread.type {
            case .FanClub, .Custom:
                threadType = .ThreadPosts
            case .Episode:
                threadType = .Episode
            }
        }
        self.threadConfiguration = threadConfiguration
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(moviePlayerPlaybackDidFinish(_:)), name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)

        loadingView = LoaderView(parentView: view)
    }
    
    deinit {
        fetchController.tableView = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: - Internal functions
    func openProfileForUser(user: User) {

        func openProfile(user: User) {
            let profileController = Storyboard.profileViewController()
            profileController.initWithUser(user)
            navigationController?.pushViewController(profileController, animated: true)
        }

        if let profileController = self as? ProfileViewController {
            if profileController.userProfile != user && !user.isTheCurrentUser() {
                openProfile(user)
            }
        } else if !user.isTheCurrentUser() {
            openProfile(user)
        }
    }

    func openProfileForUsername(username: String) {
        let profileController = Storyboard.profileViewController()
        profileController.initWithUsername(username)
        navigationController?.pushViewController(profileController, animated: true)
    }


    func playTrailer(videoID: String) {
        playerController = XCDYouTubeVideoPlayerViewController(videoIdentifier: videoID)
        presentMoviePlayerViewControllerAnimated(playerController)
    }
    
    func replyToPost(post: Postable) {
        if !User.currentUserLoggedIn() {
            presentAlertWithTitle("Login first", message: "Select 'Me' tab")
            return
        }

        let newPostViewController = Storyboard.newPostViewController()

        // Post thread
        if let post = post as? ThreadPostable, let thread = thread {
            if thread.locked {
                presentAlertWithTitle("Thread is locked")
            } else {
                newPostViewController.initWith(thread, threadType: threadType, delegate: self, parentPost: post)
                animator = presentViewControllerModal(newPostViewController)
            }
        // Post in timeline
        } else if let post = post as? TimelinePostable {
            newPostViewController.initWithTimelinePost(self, postedIn:post.userTimeline, parentPost: post)
            animator = presentViewControllerModal(newPostViewController)

        // Thread
        } else if let thread = post as? Thread {
            if thread.locked {
                presentAlertWithTitle("Thread is locked")
            } else {
                newPostViewController.initWith(thread, threadType: threadType, delegate: self, parentPost: nil)
                animator = presentViewControllerModal(newPostViewController)
            }
        }
    }

    func showPostReplies(post: Postable) {
        if let post = post as? Commentable {
            let notificationThread = Storyboard.threadViewController()
            notificationThread.initWithPost(post, threadConfiguration: .ThreadDetail)
            navigationController?.pushViewController(notificationThread, animated: true)
        } else if let thread = post as? Thread {
            showThreadPosts(thread)
        }
    }

    func shouldShowAllRepliesForPost(post: Postable, forIndexPath indexPath: NSIndexPath? = nil) -> Bool {
        var indexPathIsSafe = true

        switch threadConfiguration {
        case .ThreadDetail:
            // TODO: Swich to replyCount property in the future
            if let commentable = post as? Commentable, let indexPath = indexPath {
                indexPathIsSafe = indexPath.row - 1 < commentable.replies.count
            }
            return indexPathIsSafe
        case .ThreadMain:
            if let indexPath = indexPath {
                indexPathIsSafe = indexPath.row - 1 < 1
            }
            return post.replyCount <= 1 && indexPathIsSafe
        }
    }
    
    func shouldShowContractedRepliesForPost(post: Postable, forIndexPath indexPath: NSIndexPath) -> Bool {
        switch threadConfiguration {
        case .ThreadDetail:
            return post.replyCount > 1 && indexPath.row < 3
        case .ThreadMain:
            return post.replyCount > 1 && indexPath.row < 3
        }
    }
    
    func indexForContactedReplyForPost(post: Commentable, forIndexPath indexPath: NSIndexPath) -> Int {
        return post.replies.count - 3 + indexPath.row
    }
    
    func postForCell(cell: PostCellProtocol) -> Postable? {
        let indexPath = cell.currentIndexPath
        guard let post = fetchController.objectAtIndex(indexPath.section) as? Postable else {
            return nil
        }

        if cell.currentIndexPath.row == 0 {
            return post
        // TODO organize this code better it has dup lines everywhere D:
        } else if let post = post as? Commentable where shouldShowAllRepliesForPost(post, forIndexPath: indexPath) {
            switch threadConfiguration {
            case .ThreadDetail:
                return post.replies[indexPath.row - 1] as? Postable
            case .ThreadMain:
                return post.lastReply as? Postable
            }

        } else if let post = post as? Commentable where shouldShowContractedRepliesForPost(post, forIndexPath: indexPath) {
            let index = indexForContactedReplyForPost(post, forIndexPath: indexPath)
            switch threadConfiguration {
            case .ThreadDetail:
                return post.replies[index] as? Postable
            case .ThreadMain:
                return post.lastReply as? Postable
            }
        }

        return nil
    }
    
    func like(post: Postable) {
        if !User.currentUserLoggedIn() {
            presentAlertWithTitle("Login first", message: "Select 'Me' tab")
            return
        }
        
        guard let postObject = post as? PFObject where !postObject.dirty else {
            return
        }

        let likedBy = post.likedBy ?? []
        let currentUser = User.currentUser()!
        if likedBy.contains(currentUser) {
            postObject.removeObject(currentUser, forKey: "likedBy")
            post.incrementLikeCount(byAmount: -1)
        } else {
            postObject.addUniqueObject(currentUser, forKey: "likedBy")
            post.incrementLikeCount(byAmount: 1)
        }
        postObject.saveInBackground()
    }

    // MARK: - IBAction
    
    @IBAction func dismissPressed(sender: AnyObject) {
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func replyToThreadPressed(sender: AnyObject) {
        
    }

    // MARK: - Edit Sheet

    func showSheetFor(post post: Postable, parentPost: Postable? = nil, indexPath: NSIndexPath) {

        // If user's comment show delete/edit
        guard let currentUser = User.currentUser(),
            let postedBy = post.postedBy,
            let cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return
        }

        let administrating = currentUser.isAdmin() && !postedBy.isAdmin() || currentUser.isTopAdmin()
        let isCurrentUserOrAdministrating = postedBy.isTheCurrentUser() || administrating
        if let postedBy = post.postedBy where isCurrentUserOrAdministrating {
            if let post = post as? Commentable {
                showEditPostActionSheet(administrating, canEdit: true, canDelete: true, cell: cell, postedBy: postedBy, currentUser: currentUser, post: post, parentPost: parentPost)
            } else if let thread = post as? Thread {
                showEditThreadActionSheet(thread, cell: cell)
            }
        }
    }

    func showEditThreadActionSheet(thread: Thread, cell: UITableViewCell) {

        guard let currentUser = User.currentUser() else {
            return
        }
        let administrating = currentUser.isAdmin() && !thread.postedBy!.isAdmin() || currentUser.isTopAdmin()

        let alert: UIAlertController!

        if administrating {
            alert = UIAlertController(title: "NOTE: Editing \(thread.postedBy!.aozoraUsername) thread", message: "Only edit user threads if they are breaking guidelines", preferredStyle: UIAlertControllerStyle.ActionSheet)
        } else {
            alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        }
        alert.popoverPresentationController?.sourceView = cell.superview
        alert.popoverPresentationController?.sourceRect = cell.frame

        alert.addAction(UIAlertAction(title: "Edit", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction!) -> Void in
            let comment = Storyboard.newThreadViewController()
            comment.initWith(thread, threadType: self.threadType, delegate: self, editingPost: thread)
            self.animator = self.presentViewControllerModal(comment)
        }))

        if User.currentUser()!.isAdmin() {
            let locked = thread.locked
            alert.addAction(UIAlertAction(title: locked ? "Unlock" : "Lock", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction!) -> Void in
                thread.locked = !locked
                thread.saveInBackgroundWithBlock({ (success, error) -> Void in
                    if success {
                        self.presentAlertWithTitle(thread.locked ? "Locked!" : "Unlocked!")
                    } else {
                        self.presentAlertWithTitle("Failed saving")
                    }
                })
            }))

            let pinned = thread.pinType != nil

            // TODO: Refactor all this
            if pinned {
                alert.addAction(UIAlertAction(title: "Unpin", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction!) -> Void in
                    thread.pinType = nil
                    thread.saveInBackgroundWithBlock({ (success, error) -> Void in
                        var alertTitle = ""
                        if success {
                            alertTitle = "Unpinned!"
                        } else {
                            alertTitle = "Failed unpinning"
                        }
                        self.presentAlertWithTitle(alertTitle)
                    })
                }))
            } else {
                alert.addAction(UIAlertAction(title: "Pin Global", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction!) -> Void in
                    thread.pinType = "global"
                    thread.saveInBackgroundWithBlock({ (success, error) -> Void in
                        var alertTitle = ""
                        if success {
                            alertTitle = "Pinned Globally!"
                        } else {
                            alertTitle = "Failed pinning"
                        }

                        self.presentAlertWithTitle(alertTitle)
                    })
                }))
                alert.addAction(UIAlertAction(title: "Pin Tag", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction!) -> Void in
                    thread.pinType = "tag"
                    thread.saveInBackgroundWithBlock({ (success, error) -> Void in
                        var alertTitle = ""
                        if success {
                            alertTitle = "Pinned on Tag!"
                        } else {
                            alertTitle = "Failed pinning"
                        }

                        self.presentAlertWithTitle(alertTitle)
                    })
                }))
            }

        }

        alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: { (alertAction: UIAlertAction!) -> Void in

            let childPostsQuery = Post.query()!
            childPostsQuery.whereKey("thread", equalTo: thread)
            childPostsQuery.includeKey("postedBy")
            childPostsQuery.findObjectsInBackgroundWithBlock({ (result, error) -> Void in
                if let result = result {

                    PFObject.deleteAllInBackground(result+[thread], block: { (success, error) -> Void in
                        if let _ = error {
                            // Show some error
                        } else {
                            thread.postedBy?.incrementPostCount(-1)
                            if !thread.isForumGame {
                                for post in result {
                                    (post["postedBy"] as? User)?.incrementPostCount(-1)
                                }
                            }

                            self.navigationController?.popViewControllerAnimated(true)
                        }
                    })

                } else {
                    // TODO: Show error
                }
            })
        }))


        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:nil))

        self.presentViewController(alert, animated: true, completion: nil)
    }

    func showEditPostActionSheet(administrating: Bool, canEdit: Bool, canDelete: Bool, cell: UITableViewCell, postedBy: User, currentUser: User, post: Postable, parentPost: Postable?) {

        if !canEdit && !canDelete {
            return
        }

        let alert: UIAlertController!

        if administrating {
            alert = UIAlertController(title: "Warning: Editing \(postedBy.aozoraUsername) post", message: "Only edit user posts if they are breaking guidelines", preferredStyle: UIAlertControllerStyle.ActionSheet)
            alert.popoverPresentationController?.sourceView = cell.superview
            alert.popoverPresentationController?.sourceRect = cell.frame
        } else {
            alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
            alert.popoverPresentationController?.sourceView = cell.superview
            alert.popoverPresentationController?.sourceRect = cell.frame
        }

        if canEdit {
            alert.addAction(UIAlertAction(title: "Edit", style: administrating ? UIAlertActionStyle.Destructive : UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction!) -> Void in
                let newPostViewController = Storyboard.newPostViewController()

                if let post = post as? TimelinePost {
                    newPostViewController.initWithTimelinePost(self, postedIn: currentUser, editingPost: post)
                } else if let post = post as? Post, let thread = self.thread {
                    newPostViewController.initWith(thread, threadType: self.threadType, delegate: self, editingPost: post)
                }
                self.animator = self.presentViewControllerModal(newPostViewController)
            }))
        }

        if canDelete {
            alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: { (alertAction: UIAlertAction!) -> Void in
                if let post = post as? PFObject {
                    if let parentPost = parentPost as? PFObject {
                        // Just delete child post
                        self.deletePosts([post], parentPost: parentPost, removeParent: false)
                    } else {
                        // This is parent post, remove child too
                        var className = ""
                        if let _ = post as? Post {
                            className = "Post"
                        } else if let _ = post as? TimelinePost {
                            className = "TimelinePost"
                        }

                        let childPostsQuery = PFQuery(className: className)
                        childPostsQuery.whereKey("parentPost", equalTo: post)
                        childPostsQuery.findObjectsInBackgroundWithBlock({ (result, error) -> Void in
                            if let result = result {
                                self.deletePosts(result, parentPost: post, removeParent: true)
                            } else {
                                // TODO: Show error
                            }
                        })
                    }
                }
            }))
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:nil))

        self.presentViewController(alert, animated: true, completion: nil)
    }

}

// MARK: - UITableViewDataSource
extension BaseThreadViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchController.dataCount()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = fetchController.objectInSection(section) as! Postable

        switch threadConfiguration {
        case .ThreadMain:
            if post.lastReply == nil {
                return 1
            } else if shouldShowAllRepliesForPost(post) {
                return 1 + 1 + 1
            } else {
                // 1 post, 1 show more, 1 replies, 1 reply to post
                return 1 + 1 + 1 + 1
            }
        case .ThreadDetail:
            guard let post = post as? Commentable else {
                return 0
            }

            if post.replies.isEmpty {
                return 1
            } else {
                return 1 + (post.replies.count ?? 0) + 1
            }
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let post = fetchController.objectAtIndex(indexPath.section) as! Postable
        
        if indexPath.row == 0 {

            if let thread = post as? Thread {
                var reuseIdentifier = ""
                switch post.postContent {
                case .Image, .Video, .Episode:
                    reuseIdentifier = "ThreadImageCell"
                case .Link:
                    reuseIdentifier = "ThreadUrlCell"
                case .Text:
                    reuseIdentifier = "ThreadTextCell"
                }

                let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! ThreadCell
                cell.currentIndexPath = indexPath
                cell.delegate = self

                updateThreadCell(cell, withThread: thread)

                cell.layoutIfNeeded()
                return cell

            } else if let post = post as? Commentable {
                var reuseIdentifier = ""
                switch post.postContent {
                case .Image, .Video, .Episode:
                    reuseIdentifier = "PostImageCell"
                case .Link:
                    reuseIdentifier = "PostUrlCell"
                case .Text:
                    reuseIdentifier = "PostTextCell"
                }

                let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! PostCell
                cell.currentIndexPath = indexPath
                cell.delegate = self

                updatePostCell(cell, withPost: post)

                cell.layoutIfNeeded()
                return cell
            } else {
                assertionFailure()
                return UITableViewCell()
            }

        } else if shouldShowAllRepliesForPost(post, forIndexPath: indexPath) {
            guard let post = post as? Commentable else {
                assertionFailure()
                return UITableViewCell()
            }
            let replyIndex = indexPath.row - 1
            return reuseCommentCellFor(post, replyIndex: replyIndex, indexPath: indexPath)
            
        } else if shouldShowContractedRepliesForPost(post, forIndexPath: indexPath) {
            // Show all
            if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCellWithIdentifier("ShowMoreCell") as! ShowMoreCell
                cell.layoutIfNeeded()
                return cell
            } else {
                guard let post = post as? Commentable else {
                    assertionFailure()
                    return UITableViewCell()
                }
                let replyIndex = indexForContactedReplyForPost(post, forIndexPath: indexPath)
                return reuseCommentCellFor(post, replyIndex: replyIndex, indexPath: indexPath)
            }
        } else {
            
            // Write a comment cell
            let cell = tableView.dequeueReusableCellWithIdentifier("WriteACommentCell") as! WriteACommentCell
            cell.layoutIfNeeded()
            return cell
        }
    }
    
    func reuseCommentCellFor(comment: Commentable, replyIndex: Int, indexPath: NSIndexPath) -> CommentCell {
        var reply: Commentable

        switch threadConfiguration {
        case .ThreadMain:
            reply = comment.lastReply as! Commentable
        case .ThreadDetail:
            reply = comment.replies[replyIndex] as! Commentable
        }
        
        var reuseIdentifier = ""
        if reply.imagesData?.count != 0 || reply.youtubeID != nil {
            // Comment image cell
            reuseIdentifier = "CommentImageCell"
        } else {
            // Text comment update
            reuseIdentifier = "CommentTextCell"
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! CommentCell
        cell.delegate = self
        updatePostCell(cell, withPost: reply)
        cell.layoutIfNeeded()
        cell.currentIndexPath = indexPath
        return cell
    }
    
    func updatePostCell(cell: PostCellProtocol, withPost post: Commentable) {

        // Text content
        var textContent = ""
        if let content = post.content {
            textContent = content
        }

        // Setting images and youtube
        if post.hasSpoilers && post.isSpoilerHidden {
            textContent += "\n\n(Show Spoilers)"
            cell.imageHeightConstraint?.constant = 0
            cell.playButton?.hidden = true
        } else {
            if let spoilerContent = post.spoilerContent {
                textContent += "\n\n\(spoilerContent)"
            }
            let calculatedBaseWidth = post.replyLevel == 0 ? baseWidth : baseWidth - 60
            setImages(post.imagesData, imageView: cell.imageContent, imageHeightConstraint: cell.imageHeightConstraint, baseWidth: calculatedBaseWidth)
            prepareForVideo(cell.playButton, imageView: cell.imageContent, imageHeightConstraint: cell.imageHeightConstraint, youtubeID: post.youtubeID)
        }

        // Poster information
        if let postedBy = post.postedBy {
            if let avatarFile = postedBy.avatarThumb {
                cell.userView?.avatar.setImageWithPFFile(avatarFile)
            } else {
                cell.userView?.avatar.image = UIImage(named: "default-avatar")
            }
            cell.userView?.username?.text = postedBy.aozoraUsername
            cell.userView?.onlineIndicator.hidden = !postedBy.active
        }

        // Edited date
        cell.userView?.date.text = post.createdDate?.timeAgo()
        if var postedAgo = cell.userView?.date.text where post.edited {
            postedAgo += " · Edited"
            cell.userView?.date.text = postedAgo
        }

        let postedByUsername = post.postedBy?.aozoraUsername ?? ""

        // Comment cells have a different text content
        if let _ = cell as? CommentCell {
            textContent = postedByUsername + " " + textContent
        }

        if let linkCell = cell as? PostUrlCell,
            let linkData = post.linkData {
            linkCell.linkDelegate = self
            prepareForLink(linkCell.linkContentView, linkData: linkData)
        }

        // From and to information
        if let timelinePostable = post as? TimelinePostable,
            postedBy = post.postedBy
            where timelinePostable.userTimeline != postedBy {
            cell.userView?.toUsername?.text = timelinePostable.userTimeline.aozoraUsername
            cell.userView?.toIcon?.text = ""
        } else {
            cell.userView?.toUsername?.text = ""
            cell.userView?.toIcon?.text = ""
        }

        // Adding links to text content
        updateAttributedTextProperties(cell.textContent)

        cell.textContent.setText(textContent)
        cell.textContent.addLinkForUsername(postedByUsername)

        // Like button
        updateActionsView(cell, post: post)
    }

    func updateThreadCell(cell: PostCellProtocol, withThread thread: Thread) {
        // Case of showing threads!
        let calculatedBaseWidth = baseWidth

        // Handle episode thread case
        if let episode = thread.episode {
            cell.imageHeightConstraint?.constant = 190
            cell.imageContent?.setImageFrom(urlString: episode.imageURLString())
            cell.playButton?.hidden = true
        } else if thread.type == .FanClub {
            cell.imageHeightConstraint?.constant = 0
            cell.playButton?.hidden = true
        } else {
            setImages(thread.imagesData, imageView: cell.imageContent, imageHeightConstraint: cell.imageHeightConstraint, baseWidth: calculatedBaseWidth)
            prepareForVideo(cell.playButton, imageView: cell.imageContent, imageHeightConstraint: cell.imageHeightConstraint, youtubeID: thread.youtubeID)
        }

        cell.userView?.hidden = true

        // Case of threads

        let hightlightedAttributes = { (inout attr: Attributes) in
            attr.color = UIColor.midnightBlue()
            attr.font = UIFont.systemFontOfSize(18, weight: UIFontWeightLight)
        }

        let contentAttributes = { (inout attr: Attributes) in
            attr.color = UIColor.darkGrayColor()
            attr.font = UIFont.systemFontOfSize(14)
        }

        let subtitleAttributes = { (inout attr: Attributes) in
            attr.color = UIColor.lightGrayColor()
            attr.font = UIFont.systemFontOfSize(12)
        }

        let smallSpaceAttributes = { (inout attr: Attributes) in
            attr.font = UIFont.systemFontOfSize(4)
        }

        let attributedContent: NSMutableAttributedString

        switch thread.type {
        case .Episode:
            guard let episode = thread.episode, let anime = thread.anime else {
                return
            }

            let subtitleAttributes = { (inout attr: Attributes) in
                attr.color = UIColor.belizeHole()
                attr.font = UIFont.systemFontOfSize(14)
            }

            attributedContent = NSMutableAttributedString()

            if anime.type == "Movie" {
                attributedContent
                    .add("Movie\n", setter: subtitleAttributes)
                    .add("\(anime.title ?? "") [Spoilers]", setter: hightlightedAttributes)
            } else {
                attributedContent
                    .add("\(anime.title ?? "")\n", setter: subtitleAttributes)
                    .add("Episode \(episode.number) Review [Spoilers]", setter: hightlightedAttributes)
            }

            // TODO: fix .ThreadPosts
//            if let overview = episode.overview where threadType == .ThreadPosts {
//                attributedContent.add("\n\n"+overview, setter: contentAttributes)
//            }

        case .Custom:

            let titleAttributes = { (inout attr: Attributes) in
                attr.color = UIColor.midnightBlue()
                attr.font = UIFont.systemFontOfSize(18, weight: UIFontWeightLight)
            }

            var tagName: String = ""
            if let tag = thread.tags.last as? ThreadTag {
                tagName = tag.name
            } else if let anime = thread.tags.last as? Anime {
                tagName = anime.title!
            }

            let title = "\(thread.postedBy!.aozoraUsername) · \(thread.createdAt!.timeAgo()) · #\(tagName)"
            attributedContent = NSMutableAttributedString()
                .add(title+"\n", setter: subtitleAttributes)
                .add("\n", setter: smallSpaceAttributes)
                .add(thread.title, setter: titleAttributes)

        case .FanClub:
            let titleAttributes = { (inout attr: Attributes) in
                attr.color = UIColor.midnightBlue()
                attr.font = UIFont.systemFontOfSize(18, weight: UIFontWeightLight)
            }

            attributedContent = NSMutableAttributedString()
                .add(thread.title+"\n", setter: titleAttributes)
                .add("\n", setter: smallSpaceAttributes)
                .add("by \(thread.postedBy!.aozoraUsername)", setter: subtitleAttributes)
        }

        if thread.locked {
            let alertAttributes = { (inout attr: Attributes) in
                attr.color = UIColor.onHold()
                attr.font = UIFont.systemFontOfSize(14)
            }
            attributedContent.add(" [Locked]", setter: alertAttributes)
        }

        switch threadType {
        case .ThreadPosts:
            if let content = thread.content where content.characters.count > 1 {
                attributedContent
                    .add("\n\n\(thread.content ?? "")", setter: contentAttributes)
            }
        default:
            break
        }

        // Link support
        if let linkCell = cell as? ThreadURLCell,
            let linkData = thread.linkData {
            linkCell.linkDelegate = self
            prepareForLink(linkCell.linkContentView, linkData: linkData)
        }

        updateAttributedTextProperties(cell.textContent)
        cell.textContent.setText(attributedContent)
        if let username = thread.postedBy?.aozoraUsername {
            cell.textContent.addLinkForUsername(username)
        }

        // Like button
        updateActionsView(cell, post: thread)
    }
    
    func setImages(images: [ImageData]?, imageView: UIImageView?, imageHeightConstraint: NSLayoutConstraint?, baseWidth: CGFloat) {
        if let image = images?.first {
            imageHeightConstraint?.constant = min(baseWidth * CGFloat(image.height)/CGFloat(image.width), baseWidth)
            imageView?.setImageFrom(urlString: image.url, animated: false)
        } else {
            imageHeightConstraint?.constant = 0
        }
    }

    func prepareForVideo(playButton: UIButton?, imageView: UIImageView?, imageHeightConstraint: NSLayoutConstraint?, youtubeID: String?) {
        guard let playButton = playButton else {
            return
        }

        if let youtubeID = youtubeID {
            let urlString = "https://i.ytimg.com/vi/\(youtubeID)/hqdefault.jpg"
            imageView?.setImageFrom(urlString: urlString, animated: false)
            imageHeightConstraint?.constant = baseWidth * CGFloat(180)/CGFloat(340)
            
            playButton.hidden = false
            playButton.layer.borderWidth = 1.0;
            playButton.layer.borderColor = UIColor(white: 1.0, alpha: 0.5).CGColor;
        } else {
            playButton.hidden = true
        }
    }

    func prepareForLink(linkContentView: PostEmbeddedUrlView, linkData: LinkData) {

        linkContentView.linkTitleLabel.text = linkData.title
        linkContentView.linkContentLabel.text = linkData.description
        linkContentView.linkUrlLabel.text = NSURL(string: linkData.url)?.host?.uppercaseString
        if let imageURL = linkData.imageUrls.first {
            linkContentView.imageContent?.setImageFrom(urlString: imageURL, animated: false)
            linkContentView.imageHeightConstraint?.constant = (baseWidth - 16) * CGFloat(158)/CGFloat(305)
        } else {
            linkContentView.imageContent?.image = nil
            linkContentView.imageHeightConstraint?.constant = 0
        }
    }

    func updateAttributedTextProperties(textContent: TTTAttributedLabel, linkColor: UIColor = UIColor.peterRiver()) {
        textContent.linkAttributes = [kCTForegroundColorAttributeName: linkColor]
        textContent.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        textContent.delegate = self
    }
    
    func updateActionsView(cell: PostCellProtocol, post: Postable) {

        guard let currentUser = User.currentUser() else { return }
        let likedBy = post.likedBy ?? []
        let liked = likedBy.contains(currentUser)
        if cell.isComment {
            cell.actionsView?.setupWithSmallLikeStatus(liked, likeCount: post.likeCount)
        } else {
            cell.actionsView?.setupWithLikeStatus(liked, likeCount: post.likeCount, commentCount: post.replyCount)
        }
    }
}

// MARK: - UITableViewDelegate
extension BaseThreadViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UIDevice.isPad() ? 8.0 : 6.0
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.min
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let post = fetchController.objectAtIndex(indexPath.section)

        if let post = post as? Commentable {
            selectedPost(post, atIndexPath: indexPath)
        } else if let thread = post as? Thread {
            if threadType == .ThreadPosts {
                showSheetFor(post: thread, indexPath: indexPath)
            } else {
                showThreadPosts(thread)
            }
        }
    }

    func selectedPost(post: Commentable, atIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            if post.hasSpoilers && post.isSpoilerHidden == true {
                post.isSpoilerHidden = false
                tableView.layoutIfNeeded()
                tableView.reloadData()
            } else {
                showSheetFor(post: post, indexPath: indexPath)
            }

        } else if shouldShowAllRepliesForPost(post, forIndexPath: indexPath) {

            var comment: Commentable?

            switch threadConfiguration {
            case .ThreadMain:
                comment = post.lastReply as? Commentable
            case .ThreadDetail:
                comment = post.replies[indexPath.row - 1] as? Commentable
            }

            if let comment = comment {
                pressedOnAComment(post, comment: comment, indexPath: indexPath)
            }

        } else if shouldShowContractedRepliesForPost(post, forIndexPath: indexPath) {
            // Show all
            if indexPath.row == 1 {
                showPostReplies(post)
            } else {
                let index = indexForContactedReplyForPost(post, forIndexPath: indexPath)
                var comment: Commentable?

                switch threadConfiguration {
                case .ThreadMain:
                    comment = post.lastReply as? Commentable
                case .ThreadDetail:
                    comment = post.replies[index] as? Commentable
                }

                if let comment = comment {
                    pressedOnAComment(post, comment: comment, indexPath: indexPath)
                }
            }
        } else {
            // Write a comment cell
            replyToPost(post)
        }
    }

    func showThreadPosts(thread: Thread) {
        let threadController = Storyboard.threadViewController()
        threadController.initWithPost(thread, threadConfiguration: .ThreadMain)
        navigationController?.pushViewController(threadController, animated: true)
    }

    func pressedOnAComment(post: Commentable, comment: Commentable, indexPath: NSIndexPath) {
        if comment.hasSpoilers && comment.isSpoilerHidden == true {
            comment.isSpoilerHidden = false
            tableView.layoutIfNeeded()
            tableView.reloadData()
        } else {
            showSheetFor(post: comment, parentPost: post, indexPath: indexPath)
        }
    }

    func deletePosts(childPosts: [PFObject] = [], parentPost: PFObject, removeParent: Bool) {
        var allPosts = childPosts

        if removeParent {
            allPosts.append(parentPost)
        }

        PFObject.deleteAllInBackground(allPosts, block: { (success, error) -> Void in
            if let _ = error {
                // Show some error
            } else {

                for post in allPosts {
                    (post["postedBy"] as? User)?.incrementPostCount(-1)
                }

                self.thread?.incrementReplyCount(byAmount: -allPosts.count)
                self.thread?.saveInBackground()

                if removeParent {
                    // Delete parent post, and entire section
                    if let section = self.fetchController.dataSource.indexOf(parentPost) {
                        self.fetchController.dataSource.removeAtIndex(section)
                        self.tableView.reloadData()
                    }
                } else {
                    // Delete child post
                    let parentPost = parentPost as! Commentable

                    if let index = parentPost.replies.indexOf(childPosts.last!) {
                        parentPost.replies.removeAtIndex(index)
                    }

                    // Decrement parentPost reply count
                    parentPost.incrementReplyCount(byAmount: -childPosts.count)
                    
                    if let last = parentPost.replies.last {
                        parentPost.lastReply = last
                    } else {
                        (parentPost as! PFObject).removeObjectForKey("lastReply")
                    }

                    // Reload after updating replies and lastReply
                    self.tableView.reloadData()

                    (parentPost as! PFObject).saveInBackground()
                }
            }
        })
    }
    
    func moviePlayerPlaybackDidFinish(notification: NSNotification) {
        playerController = nil;
    }
}

// MARK: - FetchControllerDelegate
extension BaseThreadViewController: FetchControllerDelegate {
    func didFetchFor(skip skip: Int) {
        refreshControl.endRefreshing()
        loadingView.stopAnimating()
    }
}

// MARK: - TTTAttributedLabelDelegate
extension BaseThreadViewController: TTTAttributedLabelDelegate {
    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        
        if let host = url.host where host == "profile",
            let username = url.pathComponents?[1] {
                let isNotCurrentUser = username != User.currentUser()!.aozoraUsername
                if let profileController = self as? ProfileViewController {
                    if profileController.userProfile?.aozoraUsername != username && isNotCurrentUser {
                        openProfileForUsername(username)
                    }
                } else if isNotCurrentUser {
                    openProfileForUsername(username)
                }
            
        } else if url.scheme != "aozoraapp" {

            let webController = Storyboard.webBrowserViewController()
            webController.initWithInitialUrl(url)
            webController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(webController, animated: true)
        }
    }
}

// MARK: - CommentViewControllerDelegate
extension BaseThreadViewController: CommentViewControllerDelegate {
    func commentViewControllerDidFinishedPosting(newPost: PFObject, parentPost: PFObject?, edited: Bool) {
        if let thread = newPost as? Thread {
            self.thread = thread
        }
    }
}

// MARK: - PostCellDelegate
extension BaseThreadViewController: PostCellDelegate {
    func postCellSelectedImage(postCell: PostCellProtocol) {
        guard let post = postForCell(postCell) else {
            return
        }

        if let imagesData = post.imagesData where !imagesData.isEmpty {
            let photosViewController = PhotosViewController(allPhotos: imagesData)
            presentViewController(photosViewController, animated: true, completion: nil)
        } else if let videoID = post.youtubeID {
            playTrailer(videoID)
        }
    }
    
    func postCellSelectedUserProfile(postCell: PostCellProtocol) {
        if let post = postForCell(postCell), let postedByUser = post.postedBy {
            openProfileForUser(postedByUser)
        }
    }

    func postCellSelectedShowComments(postCell: PostCellProtocol) {
        guard let post = postForCell(postCell) else {
            return
        }

        switch threadConfiguration {
        case .ThreadDetail:
            replyToPost(post)
        case .ThreadMain:
            if post.replyCount == 0 {
                replyToPost(post)
                break
            }

            // Don't show thread replies if in a thread post
            if let _ = post as? Thread where threadType == .ThreadPosts {
                replyToPost(post)
                break
            }

            showPostReplies(post)
        }
    }
    
    func postCellSelectedComment(postCell: PostCellProtocol) {
        postCellSelectedShowComments(postCell)
    }
    
    func postCellSelectedToUserProfile(postCell: PostCellProtocol) {
        if let post = postForCell(postCell) as? TimelinePostable {
            openProfileForUser(post.userTimeline)
        }
    }
    
    func postCellSelectedLike(postCell: PostCellProtocol) {
        guard let post = postForCell(postCell) else {
            return
        }

        like(post)
        updateActionsView(postCell, post: post)

        // Resizes the cell without updating the tableView, sweet!
        UIView.animateWithDuration(0.3, animations: {
            self.tableView.layoutIfNeeded()
        })

        // TODO: Temporal fix, only resize cell height if it's a PostCell
        if let _ = postCell as? PostCell {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }


    func postCellSelectedShowLikes(postCell: PostCellProtocol) {

        guard let post = postForCell(postCell), likedBy = post.likedBy else {
            return
        }

        let userListController = Storyboard.userListViewController()

        let likedByIds = likedBy.flatMap{ $0.objectId }
        let query = User.query()!
        query.whereKey("objectId", containedIn: likedByIds)
        query.orderByAscending("aozoraUsername")
        query.limit = 2000
        userListController.initWithQuery(query, title: "Liked by", user: User.currentUser())
        userListController.hidesBottomBarWhenPushed = true

        // TODO: Use a modal instead..
        let cell = postCell.actionsView?.superview != nil ? postCell.actionsView! : tableView.cellForRowAtIndexPath(postCell.currentIndexPath)!
        presentSmallViewController(userListController, sender: cell)
    }
}

// MARK: - LinkCellDelegate
extension BaseThreadViewController: LinkCellDelegate {
    func postCellSelectedLink(linkCell: PostCellProtocol) {
        guard let cell = linkCell as? UITableViewCell,
            let indexPath = tableView.indexPathForCell(cell),
            let postable = fetchController.objectAtIndex(indexPath.section) as? Postable,
            let linkData = postable.linkData else {
            return
        }

        let webController = Storyboard.webBrowserViewController()
        let initialUrl = NSURL(string: linkData.url)
        webController.initWithInitialUrl(initialUrl)
        webController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(webController, animated: true)
    }
}

// MARK: - FetchControllerQueryDelegate
extension BaseThreadViewController: FetchControllerQueryDelegate {
    
    func resultsForSkip(skip skip: Int) -> BFTask? {
        return nil
    }
    
    func processResult(result result: [PFObject], dataSource: [PFObject]) -> [PFObject] {
        
        let posts = result.filter({ $0["replyLevel"] as? Int == 0 })
        let replies = result.filter({ $0["replyLevel"] as? Int == 1 })
        
        // If page 0 was loaded and there are new posts, page 1 could return repeated results,
        // For this, we need to remove duplicates
        var searchIn: [PFObject] = []
        if dataSource.count > result.count {
            let b = dataSource.count
            let a = b-result.count
            searchIn = Array(dataSource[a..<b])
        } else {
            searchIn = dataSource
        }
        var uniquePosts: [PFObject] = []
        for post in posts {
            let exists = searchIn.filter({$0.objectId! == post.objectId!})
            if exists.count == 0 {
                uniquePosts.append(post)
            }
        }
        
        for post in uniquePosts {
            let postReplies = replies.filter({ ($0["parentPost"] as! PFObject) == post }) as [PFObject]
            let postable = post as! Commentable
            postable.replies = postReplies
        }

        return uniquePosts
    }
}

// MARK: - ModalTransitionScrollable
extension BaseThreadViewController: ModalTransitionScrollable {
    var transitionScrollView: UIScrollView? {
        return tableView
    }
}
