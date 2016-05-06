//
//  ForumViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/21/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit

import TTTAttributedLabel

class ForumsViewController: BaseThreadViewController {
    
    enum SelectedList: Int {
        case All = 0
        case Anime
        case Episode
        case Videos
        case FanClub
        case Tag
    }

    enum SelectedSorting: String {
        case Popular
        case New
    }

    let titles = ["All Activity", "Anime Posts", "Episode Discussion", "Videos", "Fan Clubs"]

    var allTagsDataSource: [ThreadTag] = []
    var tagsDataSource: [ThreadTag] = []
    var animeDataSource: [Anime] = []
    var dataSource: [Thread] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    @IBOutlet weak var navigationBarTitle: UILabel!
    @IBOutlet weak var createThreadButton: UIButton!
    @IBOutlet weak var sortingButton: UIButton!

    var selectedList: SelectedList = .All
    var selectedSort: SelectedSorting = .Popular
    var selectedThreadTag: ThreadTag?
    var selectedAnime: Anime?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        threadType = .Threads

        loadingView = LoaderView(parentView: view)
        loadingView.startAnimating()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ForumsViewController.changeList))
        navigationBarTitle.addGestureRecognizer(tapGestureRecognizer)
        
        fetchThreadTags()
        prepareForList(selectedList)

        addRefreshControl(refreshControl, action: #selector(ForumsViewController.refetchThreads), forTableView: tableView)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        canDisplayBannerAds = InAppController.canDisplayAds()

        if loadingView.animating == false {
            loadingView.stopAnimating()
            tableView.animateFadeIn()
        }
    }
    
    // MARK: - NavigationBar Options
    
    func prepareForList(selectedList: SelectedList) {
        self.selectedList = selectedList
        
        switch selectedList {
        case .All, .Anime, .Episode, .FanClub, .Videos:
            navigationBarTitle.text = titles[selectedList.rawValue]
            fetchThreads()
        case .Tag:
            if let selectedThreadTag = selectedThreadTag {
                navigationBarTitle.text = selectedThreadTag.name
                fetchTagThreads(selectedThreadTag)
            }
        }
        navigationBarTitle.text! += " " + FontAwesome.AngleDown.rawValue
    }
    
    func changeList() {
        if let sender = navigationController?.navigationBar,
        let viewController = tabBarController where view.window != nil {
            let tagsTitles = tagsDataSource.map({ " #"+$0.name })
            
            let dataSource = [titles, tagsTitles]
            DropDownListViewController.showDropDownListWith(
                sender: sender,
                viewController: viewController,
                delegate: self,
                dataSource: dataSource)
        }
    }

    // MARK: - Fetching
    
    func refetchThreads() {
        prepareForList(selectedList)
    }
    
    var startDate: NSDate?
    var cachedGlobalThreads: [Thread] = []
    
    func fetchThreads() {
        
        startDate = NSDate()

        sortingButton.hidden = false

        if cachedGlobalThreads.isEmpty {
            let pinnedQuery = Thread.query()!
            pinnedQuery.whereKey("pinType", equalTo: "global")
            pinnedQuery.includeKey("tags")
            pinnedQuery.includeKey("lastPostedBy")
            pinnedQuery.includeKey("startedBy")
            pinnedQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
                if let pinnedData = result as? [Thread] {
                    self.cachedGlobalThreads = pinnedData
                    self.fetchThreadDetails(pinnedData)
                }
            }
        } else {
            self.fetchThreadDetails(cachedGlobalThreads)
        }
    }

    func fetchThreadDetails(pinnedThreads: [Thread]) {
        var finalQuery: PFQuery!

        let fanClub = ThreadTag(outDataWithObjectId: "8Vm8UTKGqY")

        switch selectedList {
        case .All:
            let query = Thread.query()!
            query.whereKey("replyCount", greaterThan: 0)
            query.whereKeyExists("episode")

            let query2 = Thread.query()!
            query2.whereKeyDoesNotExist("episode")

            finalQuery = PFQuery.orQueryWithSubqueries([query, query2])
            finalQuery.whereKey("tags", notContainedIn: [fanClub])
            finalQuery.includeKey("episode")
        case .Anime:
            finalQuery = Thread.query()!
            finalQuery.whereKeyDoesNotExist("episode")
            //let anime = LibraryController.sharedInstance.library ?? []
            //finalQuery.whereKey("tags", containedIn: anime)
            finalQuery.whereKey("tags", notContainedIn: allTagsDataSource)
        case .Episode:
            finalQuery = Thread.query()!
            finalQuery.whereKeyExists("episode")
            //let anime = LibraryController.sharedInstance.library ?? []
            //finalQuery.whereKey("tags", containedIn: anime)
            //finalQuery.whereKey("tags", notContainedIn: [tagsDataSource])
            finalQuery.includeKey("episode")
            finalQuery.includeKey("anime")
        case .Videos:
            finalQuery = Thread.query()!
            finalQuery.whereKeyExists("youtubeID")
            finalQuery.whereKey("youtubeID", notEqualTo: NSNull())
            finalQuery.whereKey("tags", notContainedIn: [fanClub])
        case .FanClub:
            finalQuery = Thread.query()!
            finalQuery.whereKey("tags", containedIn: [fanClub])
        default:
            break
        }

        finalQuery.whereKeyDoesNotExist("pinType")
        finalQuery.includeKey("tags")
        finalQuery.includeKey("startedBy")
        finalQuery.includeKey("lastPostedBy")

        switch selectedSort {
        case .Popular:
            switch selectedList {
            case .All, .Anime, .Episode, .Videos:
                finalQuery.orderByDescending("hotRanking")
            case .FanClub:
                finalQuery.orderByDescending("updatedAt")
            default:
                break
            }
        case .New:
            finalQuery.orderByDescending("createdAt")
        }

        fetchController.configureWith(self, query: finalQuery, tableView: self.tableView, limit: 50, pinnedData: [])
    }

    func fetchTagThreads(tag: PFObject) {

        sortingButton.hidden = true

        let query = Thread.query()!
        query.whereKey("pinType", equalTo: "tag")
        query.whereKey("tags", containedIn: [tag])
        query.includeKey("tags")
        query.includeKey("lastPostedBy")
        query.includeKey("startedBy")
        query.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if let pinnedData = result as? [Thread] {
                let query = Thread.query()!

                query.whereKey("tags", containedIn: [tag])
                query.whereKeyDoesNotExist("pinType")
                query.includeKey("tags")
                query.includeKey("lastPostedBy")
                query.includeKey("startedBy")
                query.orderByDescending("updatedAt")
                self.fetchController.configureWith(self, query: query, tableView: self.tableView, limit: 50, pinnedData: pinnedData)
            }
        }
    }
    
    func fetchThreadTags() {
        let query = ThreadTag.query()!
        query.limit = 1000
        query.orderByAscending("order")
        query.findObjectsInBackground().continueWithSuccessBlock { (task: BFTask!) -> AnyObject! in

            self.allTagsDataSource = task.result as! [ThreadTag]
            self.tagsDataSource = self.allTagsDataSource.filter{ $0.visible == true }

            return nil
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func createThread(sender: AnyObject) {
        
        if User.currentUserLoggedIn() {
            let comment = Storyboard.newThreadViewController()
            if let selectedAnime = selectedAnime where selectedList == .Anime {
                comment.initCustomThreadWithDelegate(self, tag: selectedAnime)
            } else {
                comment.initCustomThreadWithDelegate(self, tag: nil)
            }

            animator = presentViewControllerModal(comment)
        } else {
            presentAlertWithTitle("Login first", message: "Select 'Me' tab to login", style: .Alert)
        }
    }
    
    @IBAction func searchForums(sender: AnyObject) {
        
        if let tabBar = tabBarController {
            tabBar.presentSearchViewController(.Forum)
        }
    }
    
    @IBAction func updateSorting(sender: AnyObject) {
        if selectedSort == .Popular {
            selectedSort = .New
            sortingButton.setTitle(" New", forState: .Normal)
        } else {
            selectedSort = .Popular
            sortingButton.setTitle(" Popular", forState: .Normal)
        }
        fetchThreads()
    }

    // MARK: - Override CommentViewControllerDelegate

    override func commentViewControllerDidFinishedPosting(post: PFObject, parentPost: PFObject?, edited: Bool) {
        prepareForList(selectedList)
    }

    // MARK: - Override TTTAttributedLabelDelegate

    override func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        super.attributedLabel(label, didSelectLinkWithURL: url)

        if let host = url.host where host == "tag",
            let index = url.pathComponents?[1],
            let idx = Int(index) {
            print(idx)
        }
    }
}

extension ForumsViewController: DropDownListDelegate {
    func selectedAction(trigger: UIView, action: String, indexPath: NSIndexPath) {
        
        if trigger.isEqual(navigationController?.navigationBar) {
            switch (indexPath.row, indexPath.section) {
            case (_, 0):
                prepareForList(SelectedList(rawValue: indexPath.row)!)
            case (_, 1):
                selectedThreadTag = tagsDataSource[indexPath.row]
                prepareForList(.Tag)
            default: break
            }
        }
    }
}
