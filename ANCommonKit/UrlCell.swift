//
//  PostLinkCell.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 12/15/15.
//  Copyright © 2015 AnyTap. All rights reserved.
//

import UIKit
import TTTAttributedLabel

public protocol LinkCellDelegate: PostCellDelegate {
    func postCellSelectedLink(linkCell: UrlCell)
}

public class UrlCell: PostCell {
    
    @IBOutlet public weak var linkTitleLabel: UILabel!
    @IBOutlet public weak var linkContentLabel: UILabel!
    @IBOutlet public weak var linkUrlLabel: UILabel!
    
    @IBOutlet weak var linkContentView: UIView!
    
    public weak var linkDelegate: LinkCellDelegate?
    
    public override class func registerNibFor(tableView tableView: UITableView) {
        
        super.registerNibFor(tableView: tableView)
        
        let listNib = UINib(nibName: "UrlCell", bundle: nil)
        tableView.registerNib(listNib, forCellReuseIdentifier: "UrlCell")
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
    
        do {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UrlCell.pressedOnLink(_:)))
            gestureRecognizer.numberOfTouchesRequired = 1
            gestureRecognizer.numberOfTapsRequired = 1
            linkContentView.addGestureRecognizer(gestureRecognizer)
        }
        
        do {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UrlCell.pressedOnLink(_:)))
            gestureRecognizer.numberOfTouchesRequired = 1
            gestureRecognizer.numberOfTapsRequired = 1
            imageContent?.addGestureRecognizer(gestureRecognizer)
        }
        
        let borderWidth: CGFloat = 1
        linkContentView.layer.borderColor = UIColor.backgroundDarker().CGColor
        linkContentView.layer.borderWidth = borderWidth
    }
    
    // MARK: - UITapGestureRecognizer
    
    func pressedOnLink(sender: AnyObject) {
        linkDelegate?.postCellSelectedLink(self)
    }
    
}

