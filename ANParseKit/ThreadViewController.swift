//
//  AnimeThreadViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/8/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import TTTAttributedLabel
import ANCommonKit

// Shows a thread(custom/episode/timelinepost) comments
class ThreadViewController: BaseThreadViewController {

    @IBOutlet weak var viewMoreButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        switch threadType {
        case .Timeline, .Post:
            // Fetch posts, if not a thread
            fetchPosts()
        case .Threads:
            break
        case .ThreadPosts, .Episode:
            if let thread = thread {
                title = thread.title
                fetchPosts()
            } else {
                fetchThread()
            }
        }

        addRefreshControl(refreshControl, action:#selector(fetchPosts), forTableView: tableView)

        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        canDisplayBannerAds = InAppController.canDisplayAds()
    }
    
    func fetchThread() {

        let query = Thread.query()!
        query.limit = 1
        query.whereKey("objectId", equalTo: thread!.objectId!)
        query.includeKey("anime")
        query.includeKey("startedBy")
        query.includeKey("tags")
        query.findObjectsInBackgroundWithBlock({ (result, error) -> Void in
            
            if let _ = error {
                // TODO: Show error
            } else if let result = result, let thread = result.last as? Thread {
                self.thread = thread
            }
        })
        
    }

    static func threadForEpisode(episode: Episode, anime: Anime) -> BFTask {
        let query = Thread.query()!
        query.limit = 1
        query.whereKey("episode", equalTo: episode)
        query.includeKey("episode")
        query.includeKey("anime")
        query.includeKey("startedBy")
        query.includeKey("tags")
        return query.findObjectsInBackground().continueWithSuccessBlock { task -> AnyObject? in

            if let threads = task.result as? [Thread], let thread = threads.last {
                return BFTask(result: thread)
            }

            // Create episode threads lazily, new episodes will be created automatically
            let parameters = [
                "animeID":anime.objectId!,
                "episodeID":episode.objectId!,
                "animeTitle": anime.title!,
                "episodeNumber": anime.type == "Movie" ? -1 : episode.number
                ] as [String : AnyObject]

            let successful = BFTaskCompletionSource()

            PFCloud.callFunctionInBackground("createEpisodeThread", withParameters: parameters, block: { (result, error) -> Void in
                if let error = error {
                    successful.setError(error)
                } else {
                    successful.setResult(result)
                }
            })

            return successful.task.continueWithSuccessBlock { task -> AnyObject? in
                return threadForEpisode(episode, anime: anime)
            }
        }
    }
    
    func fetchPosts() {

        var pinnedData: [PFObject] = []

        if let thread = thread where
            threadType == .ThreadPosts || threadType == .Episode {
            pinnedData.append(thread)
        }

        fetchController.configureWith(self, queryDelegate: self, tableView: tableView, limit: FetchLimit, datasourceUsesSections: true, pinnedData: pinnedData)
    }
    
    // MARK: - FetchControllerQueryDelegate
    
    override func resultsForSkip(skip skip: Int) -> BFTask? {

        let queryBatch = QueryBatch()

        var query: PFQuery!
        var repliesQuery: PFQuery!

        switch threadType {
        case .Timeline, .Post:

            if let timelinePost = timelinePost as? TimelinePost {
                query = TimelinePost.query()!
                query.whereKey("objectId", equalTo: timelinePost.objectId!)
                query.includeKey("userTimeline")

                repliesQuery = TimelinePost.query()!
            } else if let post = post as? Post {
                query = Post.query()!
                print(post.objectId)
                query.whereKey("objectId", equalTo: post.objectId!)

                repliesQuery = Post.query()!
            }

            query.includeKey("postedBy")

            switch threadConfiguration {
            case .ThreadMain:
                query.includeKey("lastReply")
                query.includeKey("lastReply.postedBy")
                return queryBatch.executeQueries([query])
            case .ThreadDetail:
                repliesQuery.skip = 0
                repliesQuery.orderByAscending("createdAt")
                repliesQuery.includeKey("postedBy")
                repliesQuery.limit = 2000
                queryBatch.whereQuery(repliesQuery, matchesKey: "parentPost", onQuery: query)
                return queryBatch.executeQueries([query, repliesQuery])
            }

        case .Episode, .ThreadPosts:

            query = Post.query()!
            query.skip = skip
            query.limit = FetchLimit
            query.whereKey("thread", equalTo: thread!)
            query.whereKey("replyLevel", equalTo: 0)
            query.orderByDescending("updatedAt")
            query.includeKey("postedBy")

            query.includeKey("lastReply")
            query.includeKey("lastReply.postedBy")

            return queryBatch.executeQueries([query])
        default:
            assertionFailure()
            return nil
        }
    }

    // MARK: - FetchControllerDelegate

    override func didFetchFor(skip skip: Int) {
        super.didFetchFor(skip: skip)

        switch threadType {
        case .Episode, .ThreadPosts:
            break
        case .Timeline, .Post:
            let post = fetchController.objectInSection(0)
            if let post = post as? TimelinePostable {
                navigationItem.title = post.userTimeline.aozoraUsername
            } else if let post = post as? ThreadPostable {
                navigationItem.title = "In " + post.thread.title
            }
        default:
            assertionFailure()
            break
        }
    }

    
    // MARK: - TTTAttributedLabelDelegate
    
    override func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        super.attributedLabel(label, didSelectLinkWithURL: url)
        
        if let host = url.host where host == "tag",
            let index = url.pathComponents?[1],
            let idx = Int(index) {
                if let thread = thread, let anime = thread.tags[idx] as? Anime {
                    self.animator = presentAnimeModal(anime)
                }
        }
    }
    
    // MARK: - CommentViewControllerDelegate

    override func commentViewControllerDidFinishedPosting(post: PFObject, parentPost: PFObject?, edited: Bool) {
        super.commentViewControllerDidFinishedPosting(post, parentPost: parentPost, edited: edited)
        
        guard let _ = post as? Commentable else {
            return
        }

        if edited {
            // Don't insert if edited
            tableView.reloadData()
            return
        }
        
        // Only posts and TimelinePosts
        if let parentPost = parentPost {
            // Inserting a new reply in-place
            let parentPost = parentPost as! Commentable
            parentPost.replies.append(post)
            tableView.reloadData()
        } else if parentPost == nil {

            switch threadType {
            case .ThreadPosts:
                // Inserting a new post in the bottom, if we're in the bottom of the thread
                if !fetchController.canFetchMoreData {
                    fetchController.dataSource.append(post)
                    tableView.reloadData()
                }
            case .Episode:
                // Inserting a new post in the top
                fetchController.dataSource.insert(post, atIndex: 0)
                tableView.reloadData()
            case .Timeline, .Post:
                break
            default:
                assertionFailure()
                break
            }
        }
    }

    // MARK: - IBAction
    
    override func replyToThreadPressed(sender: AnyObject) {
        super.replyToThreadPressed(sender)

        switch threadType {
        case .ThreadPosts, .Episode:
            if let thread = thread {
                replyToPost(thread)
            }
        case .Post:
            if let post = post {
                replyToPost(post)
            }
        case .Timeline:
            if let post = timelinePost {
                replyToPost(post)
            }
        default:
            assertionFailure()
            break
        }
    }
    
    @IBAction func playTrailerPressed(sender: AnyObject) {
        if let thread = thread, let youtubeID = thread.youtubeID {
            playTrailer(youtubeID)
        }
    }
    
    @IBAction func openUserProfile(sender: AnyObject) {
        if let startedBy = thread?.postedBy {
            openProfileForUser(startedBy)
        }
    }
}

extension ThreadViewController: UINavigationBarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
}
