//
//  PostLinkCell.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 12/15/15.
//  Copyright © 2015 AnyTap. All rights reserved.
//

import UIKit
import TTTAttributedLabel

protocol LinkCellDelegate: PostCellDelegate {
    func postCellSelectedLink(linkCell: UrlCell)
}

class UrlCell: PostCell {
    
    @IBOutlet weak var linkTitleLabel: UILabel!
    @IBOutlet weak var linkContentLabel: UILabel!
    @IBOutlet weak var linkUrlLabel: UILabel!
    
    @IBOutlet weak var linkContentView: UIView!
    
    weak var linkDelegate: LinkCellDelegate?
    
    override class func registerNibFor(tableView tableView: UITableView) {
        
        super.registerNibFor(tableView: tableView)
        
        let listNib = UINib(nibName: "UrlCell", bundle: nil)
        tableView.registerNib(listNib, forCellReuseIdentifier: "UrlCell")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        do {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pressedOnLink(_:)))
            gestureRecognizer.numberOfTouchesRequired = 1
            gestureRecognizer.numberOfTapsRequired = 1
            linkContentView.addGestureRecognizer(gestureRecognizer)
        }
        
        do {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pressedOnLink(_:)))
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

