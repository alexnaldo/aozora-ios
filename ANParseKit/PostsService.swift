//
//  Posts.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 4/15/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

class PostsService {
    static func addLikeAndCommentCounters(date: NSDate = NSDate()) {
        print("Fetching earlier than: \(date)")

        let query = TimelinePost.query()!
        query.orderByDescending("createdAt")
        query.selectKeys(["likeCount", "replyCount", "likedBy"])
        //query.includeKey("likedBy")
        query.whereKey("createdAt", lessThan: date)
        query.findAllObjectsInBackground().continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in

            guard let result = task.result as? [TimelinePost] else {
                return nil
            }

            for post in result {
                processPost(post)
            }

            if result.count == 11000 {
                self.addLikeAndCommentCounters(result.last!.createdAt!)
            }

            return nil
        }).continueWithBlock { (task) -> AnyObject? in
            print(task.error)
            print(task.exception)
            return nil
        }
    }


    static func processPost(post: TimelinePost) {
        let likes = post.likedBy?.count ?? 0
        if likes != 0 {
            print("Saving likes \(likes)")
            post.likeCount = likes
            post.saveInBackground()
            NSThread.sleepForTimeInterval(0.1)
        }

    }

}
