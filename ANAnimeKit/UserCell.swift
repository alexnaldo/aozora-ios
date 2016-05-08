//
//  UserCell.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/16/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit

public protocol UserCellDelegate: class {
    func userCellPressedFollow(userCell: UserCollectionCell)
}


public class UserCollectionCell: UICollectionViewCell {

    public weak var delegate: UserCellDelegate?

    @IBOutlet weak public var username: UILabel!
    @IBOutlet weak public var avatar: UIImageView!
    @IBOutlet weak public var date: UILabel!
    @IBOutlet weak public var lastOnline: UILabel!
    @IBOutlet weak public var followButton: UIButton!

    public func configureFollowButtonWithState(following: Bool) {
        if following {
            followButton.backgroundColor = UIColor.backgroundWhite()
            followButton.setTitleColor(.peterRiver(), forState: .Normal)
            followButton.setTitle(" FOLLOWING", forState: .Normal)
        } else {
            followButton.backgroundColor = UIColor.backgroundWhite()
            followButton.setTitleColor(.darkGrayColor(), forState: .Normal)
            followButton.setTitle(" FOLLOW", forState: .Normal)
        }
        self.followButton.layoutIfNeeded()
    }

    @IBAction func followPressed(sender: AnyObject) {
        delegate?.userCellPressedFollow(self)
    }
}
