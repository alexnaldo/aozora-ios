//
//  NewPostViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/24/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANCommonKit

public class NewPostViewController: CommentViewController {
    
    let EditingContentCacheKey = "NewPost.TextContent"
    let EditingSpoilerCacheKey = "NewPost.SpoilerContent"
    
    @IBOutlet weak var spoilersButton: UIButton!
    @IBOutlet weak var spoilerContentHeight: NSLayoutConstraint!
    @IBOutlet weak var spoilerTextView: UITextView!
    
    var hasSpoilers = false {
        didSet {
            if hasSpoilers {
                spoilersButton.setTitle(" Spoilers", forState: .Normal)
                spoilersButton.setTitleColor(UIColor.dropped(), forState: .Normal)
                spoilerContentHeight.constant = 160
                
            } else {
                spoilersButton.setTitle("No Spoilers", forState: .Normal)
                spoilersButton.setTitleColor(UIColor(white: 0.75, alpha: 1.0), forState: .Normal)
                spoilerContentHeight.constant = 0
            }
            
            
            UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 1.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.view.layoutIfNeeded()
                }) { (finished) -> Void in
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        spoilerContentHeight.constant = 0
        
        if let content = NSUserDefaults.standardUserDefaults().objectForKey(EditingContentCacheKey) as? String where content.characters.count > 0 {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(EditingContentCacheKey)
            textView.text = content
        }

        if let content = NSUserDefaults.standardUserDefaults().objectForKey(EditingSpoilerCacheKey) as? String where content.characters.count > 0 {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(EditingSpoilerCacheKey)
            spoilerTextView.text = content
            hasSpoilers = true
        }

        textView.becomeFirstResponder()
        
        if let editingPost = editingPost {
            
            let postable = editingPost as! Commentable
            hasSpoilers = postable.hasSpoilers
            
            if hasSpoilers {
                spoilerTextView.text = postable.spoilerContent
                textView.text = postable.content
            } else {
                textView.text = postable.content
            }
            
            if let youtubeID = postable.youtubeID {
                selectedVideoID = youtubeID
                videoCountLabel.hidden = false
            } else if let imageData = postable.imagesData?.last {
                selectedImageData = imageData
                photoCountLabel.hidden = false
            } else if let linkData = postable.linkData {
                selectedLinkData = linkData
                linkCountLabel?.hidden = false
            }
            
            if let _ = parentPost {
                inReply.text = "  Editing Post Reply"
            } else {
                inReply.text = "  Editing Post"
            }

        } else {
            if let _ = parentPost {
                inReply.text = "  New Post Reply"
            } else {
                inReply.text = "  New Post"
            }
        }
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if !dataPersisted && editingPost == nil {
            NSUserDefaults.standardUserDefaults().setObject(textView.text, forKey: EditingContentCacheKey)
            NSUserDefaults.standardUserDefaults().setObject(spoilerTextView.text, forKey: EditingSpoilerCacheKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }

    override func performPost() {
        super.performPost()
        
        if !validPost() {
            return
        }
        
        if fetchingData {
            presentAlertWithTitle("Fetching link data...", message: nil)
            return
        }
        
        self.sendButton.setTitle("Sending...", forState: .Normal)
        self.sendButton.backgroundColor = UIColor.watching()
        self.sendButton.userInteractionEnabled = false
        
        switch threadType {
        case .Timeline:
            performTimelinePost()
        case .Post, .ThreadPosts, .Episode, .Threads:
            performPostPost()
        }
    }

    func performTimelinePost() {
        var timelinePost = TimelinePost()
        timelinePost = updatePostable(timelinePost, edited: false) as! TimelinePost

        var saveTask: BFTask?

        if let parentPost = parentPost as? TimelinePost {
            parentPost.lastReply = timelinePost
            parentPost.incrementReplyCount(byAmount: 1)
            saveTask = parentPost.saveInBackground()
        }

        if let parentPost = parentPost as? TimelinePostable {
            timelinePost.replyLevel = 1
            timelinePost.userTimeline = parentPost.userTimeline
            timelinePost.parentPost = parentPost as? TimelinePost
        } else {
            timelinePost.replyLevel = 0
            timelinePost.userTimeline = postedIn
        }

        if saveTask == nil {
            saveTask = timelinePost.saveInBackground()
        }

        saveTask?.continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task: BFTask!) -> AnyObject! in
            // Send timeline post notification
            var message: String?
            let username = self.postedBy!.aozoraUsername
            if let content = timelinePost.content where content.characters.count > 1 {
                message = "\(username): \(content)"
            }

            if let parentPost = self.parentPost as? TimelinePost {
                if message == nil {
                    switch timelinePost.postContent {
                    case .Link:
                        message = "\(username) replied with a link"
                    case .Image:
                        message = "\(username) replied with an image"
                    case .Video:
                        message = "\(username) replied with a video"
                    default:
                        message = "\(username) replied"
                    }
                }

                let parameters = [
                    "toUserId": self.postedIn.objectId!,
                    "timelinePostId": parentPost.objectId!,
                    "toUserUsername": self.postedIn.aozoraUsername,
                    "message": message!
                    ] as [String : AnyObject]
                PFCloud.callFunctionInBackground("sendNewTimelinePostReplyPushNotificationV2", withParameters: parameters)

            } else {
                if message == nil {
                    switch timelinePost.postContent {
                    case .Link:
                        message = "\(username) posted a link in your timeline"
                    case .Image:
                        message = "\(username) posted an image in your timeline"
                    case .Video:
                        message = "\(username) posted a video in your timeline"
                    default:
                        message = "\(username) posted in your timeline"
                    }
                }

                let parameters = [
                    "toUserId": self.postedIn.objectId!,
                    "timelinePostId": timelinePost.objectId!,
                    "message": message!
                    ] as [String : AnyObject]
                PFCloud.callFunctionInBackground("sendNewTimelinePostPushNotificationV2", withParameters: parameters)
            }

            self.postedBy?.incrementPostCount(1)
            self.completeRequest(timelinePost, parentPost: self.parentPost as? PFObject, error: task.error)
            return nil
        })
    }

    func performPostPost() {
        var post = Post()
        post = updatePostable(post, edited: false) as! Post

        // Add subscribers to parent post or current post if there is no parent
        var saveTask: BFTask?

        if let parentPost = parentPost as? Post {
            parentPost.incrementReplyCount(byAmount: 1)
            parentPost.lastReply = post
            saveTask = parentPost.saveInBackground()
        }

        if let parentPost = parentPost as? ThreadPostable {
            post.replyLevel = 1
            post.thread = parentPost.thread
            post.parentPost = parentPost as? Post
        } else {
            post.replyLevel = 0
            post.thread = thread!
        }
        post.thread.incrementReplyCount()
        post.thread.lastPostedBy = postedBy

        if saveTask == nil {
            saveTask = post.saveInBackground()
        }

        saveTask?.continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task: BFTask!) -> AnyObject! in

            PFCloud.callFunctionInBackground("Thread.UpdateHotRanking", withParameters: ["threadId": post.thread.objectId!])

            // Send post notification
            if let parentPost = self.parentPost as? Post {
                let parameters = [
                    "toUserId": parentPost.postedBy!.objectId!,
                    "postId": parentPost.objectId!,
                    "threadName": post.thread.title
                    ] as [String : AnyObject]
                PFCloud.callFunctionInBackground("sendNewPostReplyPushNotification", withParameters: parameters)
            } else {
                var parameters = [
                    "postId": post.objectId!,
                    "threadName": post.thread.title
                    ] as [String : AnyObject]

                // Only on user threads, episode threads do not have startedBy
                if let startedBy = post.thread.postedBy {
                    parameters["toUserId"] = startedBy.objectId!
                }

                PFCloud.callFunctionInBackground("sendNewPostPushNotification", withParameters: parameters)
            }
            // Incrementing post counts only if thread does not contain #ForumGame tag
            if let thread = self.thread where !thread.isForumGame {
                self.postedBy?.incrementPostCount(1)
            }
            self.completeRequest(post, parentPost: self.parentPost as? PFObject, error: task.error)
            return nil
        })
    }

    func updatePostable(post: Commentable, edited: Bool) -> Commentable {
        if hasSpoilers {
            post.content = textView.text
            post.spoilerContent = spoilerTextView.text
        } else {
            post.content = textView.text
            post.spoilerContent = nil
        }
        
        if !edited {
            post.postedBy = postedBy
            post.edited = false
        } else {
            post.edited = true
        }
        
        post.hasSpoilers = hasSpoilers
        
        if let selectedImageData = selectedImageData {
            post.imagesData = [selectedImageData]
        } else {
            post.imagesData = []
        }
        
        if let youtubeID = selectedVideoID {
            post.youtubeID = youtubeID
        } else {
            post.youtubeID = nil
        }
        
        if let linkData = selectedLinkData {
            post.linkData = linkData
        } else {
            post.linkData = nil
        }
        
        return post
    }
    
    override func performUpdate(post: PFObject) {
        super.performUpdate(post)
        
        if !validPost() {
            return
        }
        
        self.sendButton.setTitle("Updating...", forState: .Normal)
        self.sendButton.backgroundColor = UIColor.watching()
        self.sendButton.userInteractionEnabled = false
        
        if var post = post as? Commentable {
            post = updatePostable(post, edited: true)
        }
        
        post.saveInBackgroundWithBlock ({ (result, error) -> Void in
            self.completeRequest(post, parentPost: self.parentPost as? PFObject, error: error)
        })
    }
    
    override func completeRequest(post: PFObject, parentPost: PFObject?, error: NSError?) {
        super.completeRequest(post, parentPost: parentPost, error: error)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(EditingContentCacheKey)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(EditingSpoilerCacheKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func validPost() -> Bool {
        let content = max(textView.text.characters.count, spoilerTextView.text.characters.count)
        // Validate post
        if content < 1 && selectedImageData == nil && selectedVideoID == nil && selectedLinkData == nil {
            presentAlertWithTitle("Too Short", message: "Message/spoiler should be 1 character or longer")
            return false
        }
        if User.muted(self) {
            return false
        }
        return true
    }
    
  
    // MARK: - IBActions
    
    @IBAction func spoilersButtonPressed(sender: AnyObject) {
        hasSpoilers = !hasSpoilers
    }
}

extension NewPostViewController: ModalTransitionScrollable {
    public var transitionScrollView: UIScrollView? {
        return textView
    }
}


