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

    func showLikeAsLiked() {
        //likeButton.
    }

    func showLikeAsNotLiked() {

    }

    var replyCallback: ActionCallback!
    var likeCallback: ActionCallback!

    @IBAction func replyPressed(sender: AnyObject) {
        replyCallback?()
        replyButton.animateBounce()
    }

    @IBAction func likePressed(sender: AnyObject) {
        likeCallback?()
        likeButton.animateBounce()
    }
}
