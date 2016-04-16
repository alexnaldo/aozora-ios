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

    @IBOutlet weak var showLikesConstraint: NSLayoutConstraint!

    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeCountLabel: UIButton!
    @IBOutlet weak var commentCountLabel: UIButton!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        reuseViewWithClass(PostActionsView)
    }


    var showDetails: Bool = false {
        didSet {
            if showDetails {
                showLikesConstraint.constant = 30
            } else {
                showLikesConstraint.constant = 0
            }
        }
    }

    func setupWithLikeStatus(liked: Bool, likeCount: Int, commentCount: Int) {
        if liked {
            likeButton.setImage(UIImage(named: "icon-like-filled"), forState: .Normal)
        } else {
            likeButton.setImage(UIImage(named: "icon-like-empty"), forState: .Normal)
        }

        let likeString = likeCount == 1 ? "like" : "likes"
        likeCountLabel.setTitle(" \(likeCount) \(likeString)", forState: .Normal)

        let commentString = commentCount == 1 ? "comment" : "comments"
        commentCountLabel.setTitle("\(commentCount) \(commentString)", forState: .Normal)
    }

    var replyCallback: ActionCallback!
    var likeCallback: ActionCallback!
    var showLikesCallback: ActionCallback!

    @IBAction func showLikesPressed(sender: AnyObject) {
        showLikesCallback?()
    }

    @IBAction func replyPressed(sender: AnyObject) {
        replyCallback?()
        replyButton.animateBounce()
    }

    @IBAction func likePressed(sender: AnyObject) {
        likeCallback?()
        likeButton.animateBounce()
    }
}
