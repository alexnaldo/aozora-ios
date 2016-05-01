//
//  ThreadCell.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 4/30/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import TTTAttributedLabel
import FLAnimatedImage

class ThreadCell: UITableViewCell, PostCellProtocol {
    @IBOutlet weak var userView: PostUserView?
    @IBOutlet weak var actionsView: PostActionsView?

    @IBOutlet weak var imageContent: FLAnimatedImageView?
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint?
    @IBOutlet weak var textContent: TTTAttributedLabel!

    @IBOutlet weak var playButton: UIButton?

    weak var delegate: PostCellDelegate?
    var currentIndexPath: NSIndexPath!

    enum PostType {
        case Text
        case Image
        case Video
    }

    var isComment: Bool {
        return false
    }

    class func registerNibFor(tableView tableView: UITableView) {

        let listNib = UINib(nibName: "ThreadTextCell", bundle: nil)
        tableView.registerNib(listNib, forCellReuseIdentifier: "ThreadTextCell")
        let listNib2 = UINib(nibName: "ThreadImageCell", bundle: nil)
        tableView.registerNib(listNib2, forCellReuseIdentifier: "ThreadImageCell")
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        if let imageContent = imageContent {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pressedOnImage(_:)))
            gestureRecognizer.numberOfTouchesRequired = 1
            gestureRecognizer.numberOfTapsRequired = 1
            imageContent.addGestureRecognizer(gestureRecognizer)
        }

        actionsView?.showLikesCallback = {
            self.delegate?.postCellSelectedShowLikes(self)
        }

        actionsView?.showRepliesCallback = {
            self.delegate?.postCellSelectedShowComments(self)
        }

        actionsView?.likeCallback = {
            self.delegate?.postCellSelectedLike(self)
        }

        actionsView?.replyCallback = {
            self.delegate?.postCellSelectedComment(self)
        }

        userView?.pressedUserProfile = {
            self.delegate?.postCellSelectedUserProfile(self)
        }

        userView?.pressedToUserProfile = {
            self.delegate?.postCellSelectedToUserProfile(self)
        }
    }

    // MARK: - IBActions

    func pressedOnImage(sender: AnyObject) {
        delegate?.postCellSelectedImage(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textContent.preferredMaxLayoutWidth = textContent.frame.size.width
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        textContent.preferredMaxLayoutWidth = textContent.frame.size.width
    }
}