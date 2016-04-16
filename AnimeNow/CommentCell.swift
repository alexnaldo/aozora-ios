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

    // Just to conform to protocol, refactor later..
    weak var userView: PostUserView?
    weak var actionsView: PostActionsView?
    // --

    weak var delegate: PostCellDelegate?
    var currentIndexPath: NSIndexPath!

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

    @IBAction func likePressed(sender: AnyObject) {
        delegate?.postCellSelectedLike(self)
    }
    
}