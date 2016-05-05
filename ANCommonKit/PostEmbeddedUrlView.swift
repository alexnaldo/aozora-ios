//
//  PostEmbeddedUrlView.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 5/5/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import UIKit

class PostEmbeddedUrlView: UIView {
    @IBOutlet weak var linkTitleLabel: UILabel!
    @IBOutlet weak var linkContentLabel: UILabel!
    @IBOutlet weak var linkUrlLabel: UILabel!
    @IBOutlet weak var imageContent: FLAnimatedImageView?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        reuseViewWithClass(PostEmbeddedUrlView)
    }

    var openURLCallback: ActionCallback!

    override func awakeFromNib() {
        super.awakeFromNib()

        let borderWidth: CGFloat = 1
        layer.borderColor = UIColor.backgroundEvenDarker().CGColor
        layer.borderWidth = borderWidth
        layer.cornerRadius = 4.0

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pressedOnLink(_:)))
        addGestureRecognizer(gestureRecognizer)

    }

    func pressedOnLink(sender: AnyObject) {
        openURLCallback?()
    }
}

