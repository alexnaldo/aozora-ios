//
//  NewThreadViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/24/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANCommonKit
import TTTAttributedLabel

public class NewThreadViewController: CommentViewController {
    
    let EditingTitleCacheKey = "NewThread.TitleContent"
    let EditingContentCacheKey = "NewThread.TextContent"
    
    @IBOutlet weak var threadTitle: UITextField!
    @IBOutlet weak var tagLabel: TTTAttributedLabel!

    var tag: PFObject? {
        didSet {
            if let tag = tag {
                tagLabel.updateTag(tag, delegate: self)
            }
        }
    }

    var tagToSet: PFObject?

    public func initCustomThreadWithDelegate(delegate: CommentViewControllerDelegate?, tag: PFObject?) {
        super.initWith(threadType: ThreadType.Custom, delegate: delegate)
        tagToSet = tag
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        if let title = NSUserDefaults.standardUserDefaults().objectForKey(EditingTitleCacheKey) as? String {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(EditingTitleCacheKey)
            NSUserDefaults.standardUserDefaults().synchronize()
            threadTitle.text = title
        }
        
        if let content = NSUserDefaults.standardUserDefaults().objectForKey(EditingContentCacheKey) as? String {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(EditingContentCacheKey)
            NSUserDefaults.standardUserDefaults().synchronize()
            textView.text = content
        }
        
        threadTitle.becomeFirstResponder()
        threadTitle.textColor = UIColor.blackColor()
        tagLabel.attributedText = nil

        tag = tagToSet
        
        if let anime = anime, let animeTitle = anime.title {
            threadTitle.placeholder = "Enter a thread title for \(animeTitle)"
        } else {
            threadTitle.placeholder = "Enter a thread title"
        }
        
        if let anime = anime {
            tag = anime
        }
        
        if let thread = editingPost as? Thread {
            textView.text = thread.content
            threadTitle.text = thread.title
            tag = thread.tags.last
            
            if let youtubeID = thread.youtubeID {
                selectedVideoID = youtubeID
                videoCountLabel.hidden = false
                photoCountLabel.hidden = true
            } else if let imageData = thread.imagesData?.last {
                selectedImageData = imageData
                videoCountLabel.hidden = true
                photoCountLabel.hidden = false
            }
        }
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if !dataPersisted && editingPost == nil {
            NSUserDefaults.standardUserDefaults().setObject(threadTitle.text, forKey: EditingTitleCacheKey)
            NSUserDefaults.standardUserDefaults().setObject(textView.text, forKey: EditingContentCacheKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    override func performPost() {
        super.performPost()
        
        if !validThread() {
            return
        }
        
        self.sendButton.setTitle("Creating...", forState: .Normal)
        self.sendButton.backgroundColor = UIColor.watching()
        self.sendButton.userInteractionEnabled = false
        
        let thread = Thread()
        thread.edited = false
        thread.title = threadTitle.text!
        thread.content = textView.text
        let postable = thread as Postable
        postable.replyCount = 0
        thread.tags = [tag!]
        thread.subscribers = [postedBy!]
        thread.lastPostedBy = postedBy
        
        if let selectedImageData = selectedImageData {
            thread.imagesData = [selectedImageData]
        }
        
        if let youtubeID = selectedVideoID {
            thread.youtubeID = youtubeID
        }
    
        thread.startedBy = postedBy
        thread.saveInBackgroundWithBlock({ (result, error) -> Void in
            self.postedBy?.incrementPostCount(1)
            self.completeRequest(thread, parentPost:nil, error: error)
        })
        
    }
    
    override func performUpdate(post: PFObject) {
        super.performUpdate(post)
        
        if !validThread() {
            return
        }
        
        self.sendButton.setTitle("Updating...", forState: .Normal)
        self.sendButton.backgroundColor = UIColor.watching()
        self.sendButton.userInteractionEnabled = false
        
        if let thread = post as? Thread {
            thread.edited = true
            thread.title = threadTitle.text!
            thread.content = textView.text
            thread.tags = [tag!]
            
            if let selectedImageData = selectedImageData {
                thread.imagesData = [selectedImageData]
            } else {
                thread.imagesData = []
            }
            
            if let youtubeID = selectedVideoID {
                thread.youtubeID = youtubeID
            } else {
                thread.youtubeID = nil
            }
            
            thread.saveInBackgroundWithBlock({ (result, error) -> Void in
                self.completeRequest(thread, parentPost:nil, error: error)
            })
        }
    }
    
    override func completeRequest(post: PFObject, parentPost: PFObject?, error: NSError?) {
        super.completeRequest(post, parentPost: parentPost, error: error)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(EditingTitleCacheKey)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(EditingContentCacheKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func validThread() -> Bool {
        let content = textView.text
        
        if User.muted(self) {
            return false
        }
    
        if content.characters.count < 1 {
            presentBasicAlertWithTitle("Content too short", message: "Content should be a 1 character or longer, now \(content.characters.count)")
            return false
        }
        
        let title = threadTitle.text
        if title!.characters.count < 3 {
            presentBasicAlertWithTitle("Title too short", message: "Thread title should be 3 characters or longer, now \(content.characters.count)")
            return false
        }
        
        if tag == nil {
            presentBasicAlertWithTitle("Add a tag", message: "You need to add a tag for this thread")
            return false
        }
        
        return true
    }
    
    // MARK: - IBActions
    
    @IBAction func addTags(sender: AnyObject) {
        let tagsController = Storyboard.tagsViewController()
        tagsController.selectedTag = tag
        tagsController.delegate = self
        animator = presentViewControllerModal(tagsController)
    }
}

extension NewThreadViewController: TagsViewControllerDelegate {
    func tagsViewControllerSelected(tag tag: PFObject?) {
        self.tag = tag
    }
}

extension NewThreadViewController: TTTAttributedLabelDelegate {
    
    public func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        tag = nil
    }
}

extension NewThreadViewController: ModalTransitionScrollable {
    public var transitionScrollView: UIScrollView? {
        return textView
    }
}