//
//  PostActionsView.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 4/15/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import UIKit

typealias ActionCallback = () -> Void

final class PostActionsView: UIView {

    @IBOutlet weak var showLikesConstraint: NSLayoutConstraint?

    @IBOutlet weak var replyButton: UIButton?
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeCountLabel: UIButton?
    @IBOutlet weak var commentCountLabel: UIButton?

    @IBOutlet weak var separatorTopView: UIView!
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        reuseViewWithClass(PostActionsView)
    }

    func setupWithSmallLikeStatus(liked: Bool, likeCount: Int) {
        if liked {
            likeButton.setImage(UIImage(named: "icon-like-filled-small"), forState: .Normal)
        } else {
            likeButton.setImage(UIImage(named: "icon-like-empty-small"), forState: .Normal)
        }

        if likeCount == 0 {
            likeButton.setTitle("", forState: .Normal)
            likeCountLabel?.hidden = true
        } else {
            likeButton.setTitle(" \(likeCount)", forState: .Normal)
            likeCountLabel?.hidden = false
        }

    }

    func setupWithLikeStatus(liked: Bool, likeCount: Int, commentCount: Int) {
        if liked {
            likeButton.setImage(UIImage(named: "icon-like-filled"), forState: .Normal)
        } else {
            likeButton.setImage(UIImage(named: "icon-like-empty"), forState: .Normal)
        }

        if likeCount == 0 {
            likeCountLabel?.setTitle("Like", forState: .Normal)
        } else {
            let likeString = likeCount == 1 ? "Like" : "Likes"
            likeCountLabel?.setTitle("\(likeCount) \(likeString)", forState: .Normal)
        }

        if commentCount == 0 {
            commentCountLabel?.setTitle("Comment", forState: .Normal)
        } else {
            let commentString = commentCount == 1 ? "Comment" : "Comments"
            commentCountLabel?.setTitle("\(commentCount) \(commentString)", forState: .Normal)
        }
    }

    var replyCallback: ActionCallback!
    var likeCallback: ActionCallback!
    var showLikesCallback: ActionCallback!
    var showRepliesCallback: ActionCallback!

    @IBAction func showLikesPressed(sender: AnyObject) {
        showLikesCallback?()
    }

    @IBAction func showRepliesPressed(sender: AnyObject) {
        showRepliesCallback?()
    }

    @IBAction func replyPressed(sender: AnyObject) {
        replyCallback?()
        replyButton?.animateBounce()
    }

    @IBAction func likePressed(sender: AnyObject) {
        likeCallback?()
        likeButton.animateBounce()
    }
}
