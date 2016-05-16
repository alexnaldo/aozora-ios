//
//  Posts.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 4/15/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

class PostsService {
    static func addLikeAndCommentToTimelinePostsCounters(date: NSDate = NSDate()) {
        print("Fetching [TimelinePost] earlier than: \(date)")

        let query = TimelinePost.query()!
        query.orderByDescending("createdAt")
        query.selectKeys(["likeCount", "likedBy"])
        query.whereKeyExists("likedBy")
        query.whereKey("createdAt", lessThan: date)
        query.limit = 11000
        query.findObjectsInBackground().continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in

            guard let result = task.result as? [TimelinePost] else {
                return nil
            }

            for post in result {
                let likes = post.likedBy?.count ?? 0
                if likes != 0 && post.likeCount != likes {
                    print("> updated timeline \(post.objectId) like count \(likes)")
                    post.likeCount = likes
                    do {
                        try post.save()
                    } catch {
                        print("failed saving \(post.objectId)")
                    }
                }
            }

            if result.count == 11000 {
                self.addLikeAndCommentToTimelinePostsCounters(result.last!.createdAt!)
            }

            return nil
        }).continueWithBlock { (task) -> AnyObject? in
            print(task.error)
            print(task.exception)
            return nil
        }
    }

    static func addLikeAndCommentToPostsCounters(date: NSDate = NSDate()) {
        print("Fetching [Post] earlier than: \(date)")

        let query = Post.query()!
        query.orderByDescending("createdAt")
        query.selectKeys(["likeCount", "likedBy"])
        query.whereKeyExists("likedBy")
        query.whereKey("createdAt", lessThan: date)
        query.limit = 11000
        query.findObjectsInBackground().continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in

            guard let result = task.result as? [Post] else {
                return nil
            }

            for post in result {
                let likes = post.likedBy?.count ?? 0
                if likes != 0 && post.likeCount != likes {
                    print("> updated post \(post.objectId) like count \(likes)")
                    post.likeCount = likes
                    do {
                        try post.save()
                    } catch {
                        print("failed saving \(post.objectId)")
                    }
                }
            }

            if result.count == 11000 {
                self.addLikeAndCommentToPostsCounters(result.last!.createdAt!)
            }

            return nil
        }).continueWithBlock { (task) -> AnyObject? in
            print(task.error)
            print(task.exception)
            return nil
        }
    }

    static func addCommentsToPosts(date: NSDate = NSDate()) {
        print("Fetching [Post] comments earlier than: \(date)")

        let query = Post.query()!
        query.orderByDescending("createdAt")
        query.selectKeys(["replyCount"])
        query.whereKey("replyLevel", equalTo: 0)
        query.whereKey("createdAt", lessThan: date)
        query.limit = 11000
        query.findObjectsInBackground().continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in

            guard let result = task.result as? [Post] else {
                return nil
            }

            for post in result {
                let query = Post.query()!
                query.whereKey("parentPost", equalTo: post)
                let replies = query.countObjects(nil)

                if replies > 0 {
                    print("> updated post \(post.objectId) comment count \(replies)")
                    post.replyCount = replies
                    do {
                        try post.save()
                    } catch {
                        print("failed saving \(post.objectId)")
                    }
                }
            }

            if result.count == 11000 {
                self.addCommentsToPosts(result.last!.createdAt!)
            }

            return nil
        }).continueWithBlock { (task) -> AnyObject? in
            print(task.error)
            print(task.exception)
            return nil
        }
    }

    static func addCommentsToTimelinePosts(date: NSDate = NSDate()) {
        print("Fetching [TimelinePost] comments earlier than: \(date)")

        let query = TimelinePost.query()!
        query.orderByDescending("createdAt")
        query.selectKeys(["replyCount"])
        query.whereKey("replyLevel", equalTo: 0)
        query.whereKey("createdAt", lessThan: date)
        query.limit = 11000
        query.findObjectsInBackground().continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task) -> AnyObject? in

            guard let result = task.result as? [TimelinePost] else {
                return nil
            }

            for post in result {
                let query = TimelinePost.query()!
                query.whereKey("parentPost", equalTo: post)
                let replies = query.countObjects(nil)

                if replies > 0 {
                    print("> updated post \(post.objectId) comment count \(replies)")
                    post.replyCount = replies
                    do {
                        try post.save()
                    } catch {
                        print("failed saving \(post.objectId)")
                    }
                }
            }

            if result.count == 11000 {
                self.addCommentsToTimelinePosts(result.last!.createdAt!)
            }

            return nil
        }).continueWithBlock { (task) -> AnyObject? in
            print(task.error)
            print(task.exception)
            return nil
        }
    }
    
}
