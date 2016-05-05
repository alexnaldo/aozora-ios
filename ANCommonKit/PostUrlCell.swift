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
    func postCellSelectedLink(linkCell: PostCellProtocol)
}

class PostUrlCell: PostCell {

    @IBOutlet weak var linkContentView: PostEmbeddedUrlView!
    
    weak var linkDelegate: LinkCellDelegate?
    
    override class func registerNibFor(tableView tableView: UITableView) {
        
        let listNib = UINib(nibName: "PostUrlCell", bundle: nil)
        tableView.registerNib(listNib, forCellReuseIdentifier: "PostUrlCell")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        linkContentView.openURLCallback = {
            self.linkDelegate?.postCellSelectedLink(self)
        }
    }
}

