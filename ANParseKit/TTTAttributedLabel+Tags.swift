//
//  TTTAttributedLabel+Tags.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/24/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import TTTAttributedLabel

extension TTTAttributedLabel {
    public func updateTag(tag: PFObject?, delegate: TTTAttributedLabelDelegate, addLinks: Bool = true) {
        linkAttributes = [kCTForegroundColorAttributeName: UIColor.peterRiver()]
        textColor = UIColor.peterRiver()
        self.delegate = delegate

        if tag == nil {
            text = ""
            return
        }
        
        var tagsString = ""
        if let tag = tag as? ThreadTag {
            tagsString += "#\(tag.name)  "
        } else if let anime = tag as? Anime {
            tagsString += "#\(anime.title!)  "
        }

        setText(tagsString, afterInheritingLabelAttributesAndConfiguringWithBlock: { (attributedString) -> NSMutableAttributedString! in
            return attributedString
        })
        
        if addLinks {
            var idx = 0

            var tagName: String?
            if let tag = tag as? ThreadTag {
                tagName = "#\(tag.name)  "
            } else if let anime = tag as? Anime {
                tagName = "#\(anime.title!)  "
            }
            
            if let tag = tagName {
                let url = NSURL(string: "aozoraapp://tag/\(idx)")
                let range = (tagsString as NSString).rangeOfString(tag)
                addLinkToURL(url, withRange: range)
                idx += 1
            }
        }
    }
}