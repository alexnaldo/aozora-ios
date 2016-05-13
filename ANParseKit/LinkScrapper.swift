//
//  LinkScrapper.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 12/14/15.
//  Copyright © 2015 AnyTap. All rights reserved.
//

import Foundation

public class LinkData {
    
    public var url: String = ""
    public var type: String?
    public var title: String?
    public var description: String?
    public var siteName: String?
    public var imageUrl: String?
    public var relatedImages: [String]?
    public var imageWidth: Int?
    public var imageHeight: Int?

    // Deprecated
    public var imageUrls: [String] = []
    public var updatedTime: String?
    
    class func mapDataWithDictionary(dictionary: [String: AnyObject]) -> LinkData {
        let linkData = LinkData()
        
        if let url = dictionary["url"] as? String {
            linkData.url = url
        }
        if let type = dictionary["type"] as? String {
            linkData.type = type
        }
        if let url = dictionary["title"] as? String {
            linkData.title = url
        }
        if let description = dictionary["description"] as? String {
            linkData.description = description
        }
        if let imageUrls = dictionary["images"] as? [String] {
            linkData.imageUrls = imageUrls
        }
        if let updatedTime = dictionary["updatedTime"] as? String {
            linkData.updatedTime = updatedTime
        }
        if let siteName = dictionary["siteName"] as? String {
            linkData.siteName = siteName
        }
        return linkData
    }

    class func mapJSON(dictionary: [String: AnyObject]) -> LinkData {
        let linkData = LinkData()

        if let url = dictionary["url"] as? String {
            linkData.url = url
        }
        if let type = dictionary["type"] as? String {
            linkData.type = type
        }
        if let url = dictionary["title"] as? String {
            linkData.title = url
        }
        if let description = dictionary["image"] as? String {
            linkData.imageUrl = description
            // For compatibility only
            linkData.imageUrls = [description]
        }
        if let description = dictionary["description"] as? String {
            linkData.description = description
        }
        if let string = dictionary["image_width"] as? Int {
            linkData.imageWidth = string
        }
        if let string = dictionary["image_height"] as? Int {
            linkData.imageHeight = string
        }
        if let description = dictionary["related_images"] as? [String] {
            linkData.relatedImages = description
        }

        if let siteName = dictionary["siteName"] as? String {
            linkData.siteName = siteName
        }
        return linkData
    }
    
    public func toDictionary() -> [String: AnyObject] {
        return [
            "url": url ?? "",
            "type": type ?? "",
            "title": title ?? "",
            "description": description ?? "",
            "images": imageUrls,
            "updatedTime": updatedTime ?? "",
            "siteName": siteName ?? ""
        ]
    }
}
