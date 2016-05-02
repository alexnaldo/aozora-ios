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
    
    var episode: Episode?
    var anime: Anime?
    var timelinePost: TimelinePostable?
    var post: ThreadPostable?

    func initWithPost(post: Commentable) {
        if let timelinePost = post as? TimelinePostable {
            self.timelinePost = timelinePost
            threadType = .Timeline
        } else if let threadPost = post as? ThreadPostable {
            self.post = threadPost
            self.thread = threadPost.thread
            threadType = .Post
        }
        replyConfiguration = .ShowCreateReply
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        switch threadType {
        case .Timeline, .Post:
            // Fetch posts, if not a thread
            fetchPosts()
        case .ThreadPosts:
            if let thread = thread where thread.locked {
                navigationItem.rightBarButtonItem?.enabled = false
            }
        case .Threads:
            break
        case .Episode:
            break
        }

        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        canDisplayBannerAds = InAppController.canDisplayAds()
    }
    
    override func fetchThread() {

        super.fetchThread()

        let query = Thread.query()!
        query.limit = 1
        
        if let episode = episode {
            query.whereKey("episode", equalTo: episode)
            query.includeKey("episode")
        } else if let thread = thread, let objectId = thread.objectId {
            query.whereKey("objectId", equalTo: objectId)
        }
        
        query.includeKey("anime")
        query.includeKey("startedBy")
        query.includeKey("tags")
        query.findObjectsInBackgroundWithBlock({ (result, error) -> Void in
            
            if let _ = error {
                // TODO: Show error
            } else if let result = result, let thread = result.last as? Thread {
                self.thread = thread
                //self.updateUIWithThread(thread)
            } else if let episode = self.episode, let anime = self.anime where self.threadType == ThreadType.Episode {
                
                // Create episode threads lazily
                let parameters = [
                    "animeID":anime.objectId!,
                    "episodeID":episode.objectId!,
                    "animeTitle": anime.title!,
                    "episodeNumber": anime.type == "Movie" ? -1 : episode.number
                ] as [String : AnyObject]
                
                PFCloud.callFunctionInBackground("createEpisodeThread", withParameters: parameters, block: { (result, error) -> Void in
                    
                    if let _ = error {
                        
                    } else {
                        print("Created episode thread")
                        self.fetchThread()
                    }
                })
            }
        })
        
    }
    
    override func fetchPosts() {
        super.fetchPosts()
        var pinnedData: [PFObject] = []

        if let thread = thread where threadType == .ThreadPosts {
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

            repliesQuery.skip = 0
            repliesQuery.orderByAscending("createdAt")
            repliesQuery.includeKey("postedBy")
            repliesQuery.limit = 2000
            queryBatch.whereQuery(repliesQuery, matchesKey: "parentPost", onQuery: query)

        case .Episode, .ThreadPosts:

            query = Post.query()!
            query.skip = skip
            query.limit = FetchLimit
            query.whereKey("thread", equalTo: thread!)
            query.whereKey("replyLevel", equalTo: 0)
            query.orderByDescending("updatedAt")
            query.includeKey("postedBy")

            repliesQuery = Post.query()!
            repliesQuery.skip = 0
            repliesQuery.orderByAscending("createdAt")
            repliesQuery.includeKey("postedBy")
            repliesQuery.limit = 2000

            queryBatch.whereQuery(repliesQuery, matchesKey: "parentPost", onQuery: query)
        default:
            assertionFailure()
            break
        }

        return queryBatch.executeQueries([query, repliesQuery])


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
        
        if let thread = thread where User.currentUserLoggedIn() && !thread.locked {
            let newPostViewController = Storyboard.newPostViewController()
            newPostViewController.initWith(thread, threadType: threadType, delegate: self)
            animator = presentViewControllerModal(newPostViewController)
        } else if let thread = thread where thread.locked {
            presentAlertWithTitle("Thread is locked", message: nil)
        } else {
            presentAlertWithTitle("Login first", message: "Select 'Me' tab")
        }
    }
    
    @IBAction func playTrailerPressed(sender: AnyObject) {
        if let thread = thread, let youtubeID = thread.youtubeID {
            playTrailer(youtubeID)
        }
    }
    
    @IBAction func openUserProfile(sender: AnyObject) {
        if let startedBy = thread?.postedBy {
            openProfile(startedBy)
        }
    }
}

extension ThreadViewController: UINavigationBarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
}
