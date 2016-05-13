//
//  PostUserView.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 4/15/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import UIKit

final class PostUserView: UIView {

    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var username: UILabel?
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var onlineIndicator: UIImageView!

    @IBOutlet weak var toIcon: UILabel?
    @IBOutlet weak var toUsername: UILabel?

    var pressedUserProfile: ActionCallback!
    var pressedToUserProfile: ActionCallback!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        reuseViewWithClass(PostUserView)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        initializeTapTargets()
    }

    func initializeTapTargets() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pressedUserProfile(_:)))
        gestureRecognizer.numberOfTouchesRequired = 1
        gestureRecognizer.numberOfTapsRequired = 1
        avatar.addGestureRecognizer(gestureRecognizer)

        if let username = username {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pressedUserProfile(_:)))
            gestureRecognizer.numberOfTouchesRequired = 1
            gestureRecognizer.numberOfTapsRequired = 1
            username.addGestureRecognizer(gestureRecognizer)
        }

        if let toUsername = toUsername {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pressedToUserProfile(_:)))
            gestureRecognizer.numberOfTouchesRequired = 1
            gestureRecognizer.numberOfTapsRequired = 1
            toUsername.addGestureRecognizer(gestureRecognizer)
        }
    }

    // MARK: - Actions

    func pressedUserProfile(sender: AnyObject) {
        pressedUserProfile?()
    }

    func pressedToUserProfile(sender: AnyObject) {
        pressedToUserProfile?()
    }

}