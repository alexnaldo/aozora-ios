//
//  TimelinePost.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/29/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation

public class Thread: PFObject, PFSubclassing, Postable {

    public enum Type {
        case Custom
        case Episode
        case FanClub
    }

    override public class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    public class func parseClassName() -> String {
        return "Thread"
    }

    @NSManaged public var title: String

    @NSManaged public var anime: Anime?
    @NSManaged public var episode: Episode?
    
    @NSManaged public var pinType: String?
    @NSManaged public var locked: Bool
    @NSManaged public var tags: [PFObject]
    @NSManaged public var lastPostedBy: User?
    
    public var imagesDataInternal: [ImageData]?
    public var linkDataInternal: LinkData?
    
    public var isForumGame: Bool {
        get {
            let forumGameId = "M4rpxLDwai"
            for tag in self.tags {
                if let tag = tag as? ThreadTag where tag.objectId! == forumGameId {
                    return true
                }
            }
            return false
        }
    }

    public var type: Type {
        let isFanclub = !tags.filter{ $0.objectId == "8Vm8UTKGqY" }.isEmpty

        if isFanclub {
            return .FanClub
        } else if let _ = episode, _ = anime {
            return .Episode
        } else {
            return .Custom
        }
    }
}