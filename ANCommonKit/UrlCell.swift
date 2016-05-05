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

    @IBOutlet weak var linkContentView: PostEmbeddedUrlView!
    
    weak var linkDelegate: LinkCellDelegate?
    
    override class func registerNibFor(tableView tableView: UITableView) {
        
        super.registerNibFor(tableView: tableView)
        
        let listNib = UINib(nibName: "UrlCell", bundle: nil)
        tableView.registerNib(listNib, forCellReuseIdentifier: "UrlCell")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        linkContentView.openURLCallback = {
            self.linkDelegate?.postCellSelectedLink(self)
        }
    }

    
}

