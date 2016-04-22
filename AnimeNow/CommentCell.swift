//
//  PostUserCell.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/28/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import TTTAttributedLabel

class CommentCell: UITableViewCell, PostCellProtocol {

    @IBOutlet weak var imageContent: FLAnimatedImageView?
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint?
    @IBOutlet weak var textContent: TTTAttributedLabel!

    @IBOutlet weak var likeButton: UIButton!

    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var onlineIndicator: UIImageView!

    @IBOutlet weak var playButton: UIButton?

    @IBOutlet weak var likes: UIButton!

    var userView: PostUserView?
    var actionsView: PostActionsView?

    weak var delegate: PostCellDelegate?
    var currentIndexPath: NSIndexPath!

    var isComment: Bool {
        return true
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        if let imageContent = imageContent {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pressedOnImage(_:)))
            gestureRecognizer.numberOfTouchesRequired = 1
            gestureRecognizer.numberOfTapsRequired = 1
            imageContent.addGestureRecognizer(gestureRecognizer)
        }

        userView = PostUserView()
        userView?.onlineIndicator = onlineIndicator
        userView?.avatar = avatar
        userView?.date = date

        actionsView = PostActionsView()
        actionsView?.likeButton = likeButton
        actionsView?.likeCountLabel = likes
    }

    enum CommentType {
        case Text
        case Image
        case Video
    }
    
    class func registerNibFor(tableView tableView: UITableView) {

        do {
            let listNib = UINib(nibName: "CommentTextCell", bundle: nil)
            tableView.registerNib(listNib, forCellReuseIdentifier: "CommentTextCell")
        }
        
        do {
            let listNib = UINib(nibName: "CommentImageCell", bundle: nil)
            tableView.registerNib(listNib, forCellReuseIdentifier: "CommentImageCell")
        }
    }


    // MARK: - IBActions
    
    func pressedOnImage(sender: AnyObject) {
        delegate?.postCellSelectedImage(self)
    }

    @IBAction func showLikesPressed(sender: AnyObject) {
        delegate?.postCellSelectedShowLikes(self)
    }

    @IBAction func likePressed(sender: AnyObject) {
        delegate?.postCellSelectedLike(self)
    }
    
}