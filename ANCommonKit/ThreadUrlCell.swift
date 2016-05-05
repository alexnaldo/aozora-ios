//
//  PostLinkCell.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 12/15/15.
//  Copyright © 2015 AnyTap. All rights reserved.
//

import UIKit
import TTTAttributedLabel

class ThreadURLCell: ThreadCell {

    @IBOutlet weak var linkContentView: PostEmbeddedUrlView!
    
    weak var linkDelegate: LinkCellDelegate?
    
    override class func registerNibFor(tableView tableView: UITableView) {
        let listNib = UINib(nibName: "ThreadUrlCell", bundle: nil)
        tableView.registerNib(listNib, forCellReuseIdentifier: "ThreadUrlCell")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        linkContentView.openURLCallback = {
            self.linkDelegate?.postCellSelectedLink(self)
        }
    }
}

