//
//  PostCell.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/28/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import TTTAttributedLabel
import FLAnimatedImage

protocol PostCellDelegate: class {
    func postCellSelectedImage(postCell: PostCellProtocol)
    func postCellSelectedUserProfile(postCell: PostCellProtocol)
    func postCellSelectedToUserProfile(postCell: PostCellProtocol)
    func postCellSelectedComment(postCell: PostCellProtocol)
    func postCellSelectedLike(postCell: PostCellProtocol)
}

protocol PostCellProtocol: class {
    weak var imageContent: FLAnimatedImageView? { get }
    var currentIndexPath: NSIndexPath! { get set }
    weak var userView: PostUserView? { get }
    weak var imageHeightConstraint: NSLayoutConstraint? { get }
    weak var textContent: TTTAttributedLabel! { get }
    weak var playButton: UIButton? { get }
    weak var actionsView: PostActionsView? { get }
}

class PostCell: UITableViewCell, PostCellProtocol {
    
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
    
    class func registerNibFor(tableView tableView: UITableView) {

        let listNib = UINib(nibName: "PostTextCell", bundle: nil)
        tableView.registerNib(listNib, forCellReuseIdentifier: "PostTextCell")
        let listNib2 = UINib(nibName: "PostImageCell", bundle: nil)
        tableView.registerNib(listNib2, forCellReuseIdentifier: "PostImageCell")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let imageContent = imageContent {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pressedOnImage(_:)))
            gestureRecognizer.numberOfTouchesRequired = 1
            gestureRecognizer.numberOfTapsRequired = 1
            imageContent.addGestureRecognizer(gestureRecognizer)
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
