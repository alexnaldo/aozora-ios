//
//  AnimeDetail.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/12/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation

public class AnimeDetail: PFObject, PFSubclassing {
    override public class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    public class func parseClassName() -> String {
        return "AnimeDetail"
    }
    
    @NSManaged public var tvdbStart: Int
    @NSManaged public var tvdbEnd: Int
    @NSManaged public var inTvdbSpecials: Int
    @NSManaged public var synopsis: String?
    @NSManaged public var classification: String
    @NSManaged public var englishTitles: [String]
    @NSManaged public var japaneseTitles: [String]
    @NSManaged public var synonyms: [String]
    @NSManaged public var youtubeID: String?

    public func synopsisString() -> String? {

        guard let synopsis = synopsis else { return nil }
        return synopsis
            .stringByReplacingOccurrencesOfString("<br>", withString: "\n")
            .stringByReplacingOccurrencesOfString("<i>", withString: "")
            .stringByReplacingOccurrencesOfString("</i>", withString: "")

    }
}