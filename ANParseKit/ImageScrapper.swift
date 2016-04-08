//
//  MALScrapper.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 5/23/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit

public class ImageData {
    
    public var url: String
    public var width: Int
    public var height: Int
    
    init(url: String, width: Int, height: Int) {
        self.url = url
        self.width = width
        self.height = height
    }
    
    class func imageDataWithDictionary(dictionary: [String: AnyObject]) -> ImageData {
        return ImageData(
            url: dictionary["url"] as! String,
            width: dictionary["width"] as! Int,
            height: dictionary["height"] as! Int)
    }
    
    public func toDictionary() -> [String: AnyObject] {
        return ["url": url, "width": width, "height": height]
    }
}

public class ImageScrapper {
    
    weak var viewController: UIViewController?
    
    public init(viewController: UIViewController) {
        self.viewController = viewController
    }

    public func findImagesWithQuery(string: String, animated: Bool) -> BFTask {
        let baseURL = "https://www.google.com/search"
        let queryURL = "?q=\(string)&tbm=isch&safe=active&tbs=isz:m" + (animated ? ",itp:animated" : "")
        let encodedRequest = baseURL + queryURL.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
        let completion = BFTaskCompletionSource()
        
        viewController?.webScraper.scrape(encodedRequest) { [weak self] (hpple) -> Void in
            if hpple == nil {
                print("hpple is nil")
                completion.setError(NSError(domain: "aozora", code: 0, userInfo: nil))
                return
            }
            
            guard let results = hpple.searchWithXPathQuery("//div[@id='rg_s']/div/div[@class='rg_meta']") as? [TFHppleElement] else {
                return
            }

            var images: [ImageData] = []
            
            for result in results {
                let jsonString = result.text() ?? ""

                if let jsonDic = self?.convertStringToDictionary(jsonString),
                let width = jsonDic["ow"] as? Int,
                let height = jsonDic["oh"] as? Int,
                let imageURL = jsonDic["ou"] as? String {

                    if width <= 1400 && height <= 1400 {
                        if animated && imageURL.endsWith(".gif") {
                            let imageData = ImageData(url: imageURL, width: width, height: height)
                            images.append(imageData)
                        } else if !animated && (imageURL.endsWith(".jpg") || imageURL.endsWith(".jpeg") || imageURL.endsWith(".png")) {
                            let imageData = ImageData(url: imageURL, width: width, height: height)
                            images.append(imageData)
                        }
                    }
                }
            }
            
            print("found \(images.count) images")
            completion.setResult(images)
        }
        
        return completion.task
    }

    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
}

