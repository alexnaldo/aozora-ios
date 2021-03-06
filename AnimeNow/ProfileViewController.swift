//
//  UserProfileViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/22/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit
import TTTAttributedLabel
import XCDYouTubeKit
import Crashlytics

class ProfileViewController: BaseThreadViewController {
    
    enum SelectedFeed: Int {
        case Feed = 0
        case Popular
        case Me
    }
    
    @IBOutlet weak var settingsButton: UIButton!
    
    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userBanner: UIImageView!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var followingButton: UIButton!
    @IBOutlet weak var followersButton: UIButton!
    @IBOutlet weak var aboutLabel: TTTAttributedLabel!
    @IBOutlet weak var activeAgo: UILabel!
    
    @IBOutlet weak var proBadge: UILabel!
    @IBOutlet weak var postsBadge: UILabel!
    @IBOutlet weak var tagBadge: UILabel!
    
    @IBOutlet weak var segmentedControlView: UIView?
    
    @IBOutlet weak var proBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var settingsTrailingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var segmentedControlTopSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableHeaderViewBottomSpaceConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var segmentedControl: ADVSegmentedControl! {
        didSet {
            segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), forControlEvents: .ValueChanged)
        }
    }
    @IBOutlet weak var segmentedControlHeight: NSLayoutConstraint!
    
    var userProfile: User?
    var username: String?
    
    func initWithUser(user: User) {
        self.userProfile = user
    }
    
    func initWithUsername(username: String) {
        self.username = username
    }

    lazy var settingsIcon: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(named: "icon-settings"), style: UIBarButtonItemStyle.Plain, target:self, action: #selector(settingsPressed))
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        threadType = .Threads
        
        segmentedControlView?.hidden = true
        
        if userProfile == nil && username == nil {
            if let currentUser = User.currentUser() {
                self.userProfile = currentUser
            } else {
                WorkflowController.logoutUser()
                WorkflowController.presentOnboardingController(true)
            }

            segmentedControl.selectedIndex = SelectedFeed.Feed.rawValue
        } else {
            segmentedControl.selectedIndex = SelectedFeed.Me.rawValue
            tableBottomSpaceConstraint.constant = 0
        }
        
        if tabBarController == nil {
            navigationItem.rightBarButtonItem = nil
        }
        
        aboutLabel.linkAttributes = [kCTForegroundColorAttributeName: UIColor.peterRiver()]
        aboutLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        aboutLabel.delegate = self;

        addRefreshControl(refreshControl, action:#selector(fetchPosts), forTableView: tableView)

        fetchPosts()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        canDisplayBannerAds = InAppController.canDisplayAds()

        navigationController?.setNavigationBarHidden(false, animated: true)

        if let profile = userProfile where profile.details.dataAvailable {
            updateFollowingButtons()
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func sizeHeaderToFit() {
        guard let header = tableView.tableHeaderView else {
            return
        }
        
        if let userProfile = userProfile where !userProfile.isTheCurrentUser() {
            tableHeaderViewBottomSpaceConstraint.constant = 8
            segmentedControl.hidden = true
        }
        
        header.setNeedsLayout()
        header.layoutIfNeeded()
        
        aboutLabel.preferredMaxLayoutWidth = aboutLabel.frame.size.width
        
        let height = header.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        var frame = header.frame
        
        frame.size.height = height
        header.frame = frame
        tableView.tableHeaderView = header
    }

    // MARK: - Overrides

    override func showSheetFor(post post: Postable, parentPost: Postable?, indexPath: NSIndexPath) {
        guard let currentUser = User.currentUser(), let postedBy = post.postedBy, let cell = tableView.cellForRowAtIndexPath(indexPath),
            let userProfile = userProfile where userProfile.isTheCurrentUser() && !userProfile.isAdmin() else {
                // Fallback to default implementation
                super.showSheetFor(post: post, parentPost: parentPost, indexPath: indexPath)
                return
        }

        // Allow user to delete posts from it's timeline.
        let canEdit = postedBy == currentUser
        let canDelete = SelectedFeed(rawValue: segmentedControl.selectedIndex)! == .Me
        showEditPostActionSheet(false, canEdit: canEdit, canDelete: canDelete, cell: cell, postedBy: postedBy, currentUser: currentUser, post: post, parentPost: parentPost)
    }
    
    
    // MARK: - Fetching
    
    func fetchPosts() {
        let username = self.username ?? userProfile!.aozoraUsername
        fetchUserDetails(username)
    }
    
    func fetchUserDetails(username: String) {
        
        if let _ = self.userProfile {
            configureFetchController()
        }
        
        let query = User.query()!
        query.whereKey("aozoraUsername", equalTo: username)
        query.includeKey("details")
        query.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            
            guard let user = result?.last as? User else {
                return
            }

            self.userProfile = user

            if user.isTheCurrentUser() {
                self.navigationItem.leftBarButtonItem = self.settingsIcon
                InAppController.updateUserUnlockedContent(user.unlockedContent)
            }

            self.updateViewWithUser(user)
            self.aboutLabel.setText(user.details.about, afterInheritingLabelAttributesAndConfiguringWithBlock: { (attributedString) -> NSMutableAttributedString! in
                return attributedString
            })

            let activeEndString = user.activeEnd.timeAgo().uppercaseString
            let activeEndStringFormatted = activeEndString == "JUST NOW" ? "ACTIVE NOW" : "\(activeEndString)" != "" ? "\(activeEndString) AGO" : ""
            self.activeAgo.font = UIFont.systemFontOfSize(11, weight: UIFontWeightMedium)
            self.activeAgo.text = user.active ? "ACTIVE NOW" : activeEndStringFormatted

            if user.details.posts >= 1000 {
                self.postsBadge.text = String(format: "%.1fk", Float(user.details.posts-49)/1000.0 )
            } else {
                self.postsBadge.text = user.details.posts.description
            }

            self.updateFollowingButtons()
            self.sizeHeaderToFit()
            // Start fetching if didn't had User class
            if let _ = self.username {
                self.configureFetchController()
            }


            if !user.isTheCurrentUser() && !User.currentUserIsGuest() {
                let relationQuery = User.currentUser()!.following().query()
                relationQuery.whereKey("aozoraUsername", equalTo: username)
                relationQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
                    if let _ = result?.last as? User {
                        // Following this user
                        self.followButton.setTitle("  Following", forState: .Normal)
                        user.followingThisUser = true
                    } else if let _ = error {
                        // TODO: Show error

                    } else {
                        // NOT following this user
                        self.followButton.setTitle("  Follow", forState: .Normal)
                        user.followingThisUser = false
                    }
                    self.followButton.layoutIfNeeded()
                }
            }
        }
    }
    
    func updateViewWithUser(user: User) {
        usernameLabel.text = user.aozoraUsername
        title = user.aozoraUsername
        navigationController?.tabBarItem.title = ""

        if let avatarFile = user.avatarThumb {
            userAvatar.setImageWithPFFile(avatarFile)
        } else {
            userAvatar.image = UIImage(named: "default-avatar")
        }
        
        if let bannerFile = user.banner {
            userBanner.setImageWithPFFile(bannerFile)
        }
        
        let proPlusString = "PRO+"
        let proString = "PRO"
        
        proBadge.hidden = true
        
        if user.isTheCurrentUser() {
            // If is current user, only show PRO when unlocked in-apps
            if InAppController.purchasedProPlus() {
                proBadge.hidden = false
                proBadge.text = proPlusString
            } else if InAppController.purchasedPro() {
                proBadge.hidden = false
                proBadge.text = proString
            }
        } else {
            if user.badges.indexOf(proPlusString) != nil {
                proBadge.hidden = false
                proBadge.text = proPlusString
            } else if user.badges.indexOf(proString) != nil {
                proBadge.hidden = false
                proBadge.text = proString
            }
        }
        
        if user.isAdmin() {
            tagBadge.backgroundColor = UIColor.aozoraPurple()
        }
        
        if User.currentUserIsGuest() {
            followButton.hidden = true
            settingsButton.hidden = true
        } else if user.isTheCurrentUser() {
            followButton.hidden = true
            settingsTrailingSpaceConstraint.constant = -10
        } else {
            followButton.hidden = false
        }
        
        var hasABadge = false
        for badge in user.badges where badge != proString && badge != proPlusString {
            tagBadge.text = badge
            hasABadge = true
            break
        }
        
        if hasABadge {
            tagBadge.hidden = false
        } else {
            tagBadge.hidden = true
            proBottomLayoutConstraint.constant = 4
        }
    }
    
    func updateFollowingButtons() {
        guard let profile = userProfile else {
            return
        }

        let numberAttributes = { (inout attr: Attributes) in
            attr.color = UIColor.darkGrayColor()
            attr.font = UIFont.boldSystemFontOfSize(13)
        }

        let textAttributes = { (inout attr: Attributes) in
            attr.color = UIColor.lightGrayColor()
            attr.font = UIFont.systemFontOfSize(13)
        }

        let followingTitle = NSMutableAttributedString()
            .add("\(profile.details.followingCount)", setter: numberAttributes)
            .add(" FOLLOWING", setter: textAttributes)

        let followersTitle = NSMutableAttributedString()
            .add("\(profile.details.followersCount)", setter: numberAttributes)
            .add(" FOLLOWERS", setter: textAttributes)

        followingButton.setAttributedTitle(followingTitle, forState: .Normal)
        followersButton.setAttributedTitle(followersTitle, forState: .Normal)
    }
    
    func configureFetchController() {
        var offset = tableView.contentOffset

        let yOffset = tableView.tableHeaderView!.bounds.height - 44 - 64
        if offset.y > yOffset {
           offset.y = yOffset
        }
        fetchController.configureWith(self, queryDelegate: self, tableView: tableView, limit: FetchLimit, datasourceUsesSections: true)
        tableView.setContentOffset(offset, animated: false)
    }
    
    // MARK: - IBAction
    var lastSelectedIndex = 0
    @IBAction func segmentedControlValueChanged(sender: AnyObject) {
        if segmentedControl.selectedIndex == lastSelectedIndex {
            return
        }

        lastSelectedIndex = segmentedControl.selectedIndex
        configureFetchController()
    }
    
    @IBAction func followOrUnfollow(sender: AnyObject) {
    
        if let thisProfileUser = userProfile,
            let followingUser = thisProfileUser.followingThisUser,
            let currentUser = User.currentUser() where !thisProfileUser.isTheCurrentUser() {
            
            currentUser.followUser(thisProfileUser, follow: !followingUser)
            
            if !followingUser {
                // Follow
                self.followButton.setTitle("  Following", forState: .Normal)
                updateFollowingButtons()
            } else {
                // Unfollow
                self.followButton.setTitle("  Follow", forState: .Normal)
                updateFollowingButtons()
            }
        }
    }

    @IBAction func searchPressed(sender: AnyObject) {
        if let tabBar = tabBarController {
            tabBar.presentSearchViewController(.AllAnime)
        }
    }

    @IBAction func settingsPressed(sender: AnyObject) {
        let settings = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController() as! UINavigationController
        if UIDevice.isPad() {
            self.presentSmallViewController(settings, sender: navigationController!.navigationBar)
        } else {
            self.animator = self.presentViewControllerModal(settings)
        }
    }

    override func replyToThreadPressed(sender: AnyObject) {
        super.replyToThreadPressed(sender)
        
        if let profile = userProfile where User.currentUserLoggedIn() {
            let comment = Storyboard.newPostViewController()
            comment.initWithTimelinePost(self, postedIn: profile)
            animator = presentViewControllerModal(comment)
        } else {
            presentAlertWithTitle("Login first", message: "Select 'Me' tab")
        }
    }
    
    
    // MARK: - FetchControllerQueryDelegate
    
    override func resultsForSkip(skip skip: Int) -> BFTask? {

        let queryBatch = QueryBatch()

        let query = TimelinePost.query()!
        query.skip = skip
        query.limit = FetchLimit
        query.whereKey("replyLevel", equalTo: 0)
        query.orderByDescending("createdAt")
        
        let selectedFeed = SelectedFeed(rawValue: segmentedControl.selectedIndex)!
        switch selectedFeed {
        case .Feed:
            if let allUsers = FriendsController.sharedInstance.following {
                let aozoraAccount = User(outDataWithObjectId: "bR0DT6mStO")
                let darkciriusAccount = User(outDataWithObjectId: "Bt5dy11isC")
                let allUsers2 = allUsers+[aozoraAccount, darkciriusAccount]
                query.whereKey("userTimeline", containedIn: allUsers2)
            } else {
                let followingQuery = userProfile!.following().query()
                followingQuery.orderByDescending("activeStart")
                followingQuery.selectKeys(["objectId"])
                followingQuery.limit = 1000
                queryBatch.whereQuery(query, matchesKey: "userTimeline", onQuery: followingQuery)
            }

        case .Popular:
            let minimumLikeCount = ParseConfig.ProfilePopularFeedMinimumLikeCount()
            query.whereKey("likeCount", greaterThan: minimumLikeCount)
        case .Me:
            query.whereKey("userTimeline", equalTo: userProfile!)
        }
        
        // 'Feed' query
        query.includeKey("episode")
        query.includeKey("postedBy")
        query.includeKey("userTimeline")
        query.includeKey("lastReply")
        query.includeKey("lastReply.postedBy")
        query.includeKey("lastReply.userTimeline")
        query.limit = FetchLimit

        startDate = NSDate()
        return queryBatch.executeQueries([query])
    }
    
    
    // MARK: - CommentViewControllerDelegate
    
    override func commentViewControllerDidFinishedPosting(newPost: PFObject, parentPost: PFObject?, edited: Bool) {
        super.commentViewControllerDidFinishedPosting(newPost, parentPost: parentPost, edited: edited)
        
        if edited {
            // Don't insert if edited
            tableView.reloadData()
            return
        }
        
        if let parentPost = parentPost {
            // Inserting a new reply in-place
            let parentPost = parentPost as! Commentable
            parentPost.replies.append(newPost)
            tableView.reloadData()
        } else if parentPost == nil {
            // Inserting a new post in the top, if we're in the top of the thread
            fetchController.dataSource.insert(newPost, atIndex: 0)
            tableView.reloadData()
        }
    }
    
    
    // MARK: - FetchControllerDelegate
    var startDate: NSDate?
    override func didFetchFor(skip skip: Int) {
        super.didFetchFor(skip: skip)

        if let startDate = startDate {
            print("Load profile = \(NSDate().timeIntervalSinceDate(startDate))s")
            self.startDate = nil
        }

        if let segmentedControlView = segmentedControlView,
            let userProfile = userProfile
            where userProfile.isTheCurrentUser() && segmentedControlView.hidden {
                segmentedControlView.hidden = false
                scrollViewDidScroll(tableView)
                segmentedControlView.animateFadeIn()
        }
    }
    
    func addMuteUserAction(alert: UIAlertController) {
        alert.addAction(UIAlertAction(title: "Mute", style: UIAlertActionStyle.Destructive, handler: {
            (alertAction: UIAlertAction) -> Void in
            
            let alertController = UIAlertController(title: "Mute", message: "Enter duration in days", preferredStyle: .Alert)
            
            alertController.addTextFieldWithConfigurationHandler(
                {(textField: UITextField!) in
                    textField.placeholder = "Enter duration in days"
                    textField.textColor = UIColor.blackColor()
                    textField.keyboardType = UIKeyboardType.NumberPad
                })
            
            let action = UIAlertAction(title: "Submit",
                style: UIAlertActionStyle.Default,
                handler: { [weak self] (paramAction: UIAlertAction!) in
                    
                    if let textField = alertController.textFields {
                        let durationTextField = textField as [UITextField]
                        
                        guard let controller = self,
                            let userProfile = self?.userProfile,
                            let durationText = durationTextField[0].text,
                            let duration = Double(durationText) else {
                            self?.presentAlertWithTitle("Woops", message: "Your mute duration is too long or you have entered characters.")
                            return
                        }
                        
                        let date = NSDate().dateByAddingTimeInterval(duration * 60.0 * 60.0 * 24.0)
                        userProfile.details.mutedUntil = date
                        userProfile.saveInBackground()
                        
                        controller.presentAlertWithTitle("Muted user", message: "You have muted " + userProfile.aozoraUsername)

                    }
                })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) {
                action -> Void in
            }
            
            alertController.addAction(action)
            alertController.addAction(cancelAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
            alert.view.tintColor = UIColor.redColor()
            
        }))
        
    }
    
    func addUnmuteUserAction(alert: UIAlertController) {
        alert.addAction(UIAlertAction(title: "Unmute", style: UIAlertActionStyle.Destructive, handler: { (alertAction: UIAlertAction) -> Void in
            
            guard let userProfile = self.userProfile, let username = userProfile.username else {
                return
            }
            userProfile.details.mutedUntil = nil
            userProfile.saveInBackground()
            
            self.presentAlertWithTitle("Unmuted user", message: "You have unmuted " + username)
        }))
    }
    
    // MARK: - IBActions
    

    
    @IBAction func showFollowingUsers(sender: AnyObject) {

        if User.currentUser() == nil {
            presentAlertWithTitle("Login first", message: "Select 'Me' tab")
            return
        }

        let userListController = Storyboard.userListViewController()
        let query = userProfile!.following().query()
        query.orderByAscending("aozoraUsername")
        userListController.initWithQuery(query, title: "Following", user: userProfile!, parentVC: self)
        presentSmallViewController(userListController, sender: sender)
    }
    
    @IBAction func showFollowers(sender: AnyObject) {

        if User.currentUser() == nil {
            presentAlertWithTitle("Login first", message: "Select 'Me' tab")
            return
        }

        let userListController = Storyboard.userListViewController()
        let query = User.query()!
        query.whereKey("following", equalTo: userProfile!)
        query.orderByAscending("aozoraUsername")
        userListController.initWithQuery(query, title: "Followers", user: userProfile!, parentVC: self)
        presentSmallViewController(userListController, sender: sender)
    }
    
    @IBAction func showSettings(sender: AnyObject) {

        guard let currentUser = User.currentUser(), let userProfile = userProfile else {
            return
        }

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        alert.popoverPresentationController?.sourceView = sender.superview
        alert.popoverPresentationController?.sourceRect = sender.frame

        if !userProfile.isTheCurrentUser() {
            alert.addAction(UIAlertAction(title: "View Library", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction) -> Void in
                guard let userProfile = self.userProfile else {
                    return
                }

                let libraryVC = UIStoryboard(name: "Library", bundle: nil).instantiateViewControllerWithIdentifier("AnimeLibraryViewController") as! AnimeLibraryViewController
                libraryVC.initWithUser(userProfile)
                libraryVC.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(libraryVC, animated: true)
            }))
        }

        let hasPermissionsToMute = currentUser.isAdmin() && !userProfile.isAdmin() || currentUser.isTopAdmin()
        if hasPermissionsToMute && currentUser != userProfile {
            if let _ = userProfile.details.mutedUntil {
                addUnmuteUserAction(alert)
            } else {
                addMuteUserAction(alert)
            }
        }
        
        if userProfile.isTheCurrentUser() {
            alert.addAction(UIAlertAction(title: "Edit Profile", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction) -> Void in
                let editProfileController =  Storyboard.editProfileViewController()
                editProfileController.delegate = self
                self.presentViewController(editProfileController, animated: true, completion: nil)
            }))

            alert.addAction(UIAlertAction(title: "Who to follow", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction) -> Void in


                guard let followingUsers = FriendsController.sharedInstance.following else {
                    return
                }

                var followingUsersIds = followingUsers.map{ $0.objectId! }
                followingUsersIds.append(userProfile.objectId!)

                let userListController = Storyboard.userListViewController()

                let postCountQuery = UserDetails.query()!
                postCountQuery.whereKey("posts", greaterThan: 400)

                let query = User.query()!
                query.whereKeyExists("aozoraUsername")
                query.whereKey("activeStart", greaterThan: NSDate().dateByAddingTimeInterval(-60*60*24))
                query.whereKey("objectId", notContainedIn: followingUsersIds)
                query.whereKey("details", matchesQuery: postCountQuery)
                query.orderByAscending("createdAt")
                query.limit = 500
                userListController.initWithQuery(query, title: "Who to follow", user: userProfile, parentVC: self)

                self.presentSmallViewController(userListController, sender: sender)
            }))

            alert.addAction(UIAlertAction(title: "Online Now", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction) -> Void in
                let userListController = Storyboard.userListViewController()
                let query = User.query()!
                query.whereKeyExists("aozoraUsername")
                query.whereKey("active", equalTo: true)
                query.limit = 1000
                userListController.initWithQuery(query, title: "Online Users", parentVC: self)
                
                self.presentSmallViewController(userListController, sender: sender)
            }))
            
            alert.addAction(UIAlertAction(title: "New Users", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction) -> Void in
                let userListController = Storyboard.userListViewController()
                let query = User.query()!
                query.orderByDescending("joinDate")
                query.whereKeyExists("aozoraUsername")
                query.limit = 500
                userListController.initWithQuery(query, title: "New Users", parentVC: self)
                self.presentSmallViewController(userListController, sender: sender)
            }))

            alert.addAction(UIAlertAction(title: "Aozora Staff", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction) -> Void in
                let userListController = Storyboard.userListViewController()
                let query = User.query()!
                query.whereKeyExists("aozoraUsername")
                query.whereKey("badges", containedIn: ["Admin", "Mod"])
                query.limit = 1000
                userListController.initWithQuery(query, title: "Aozora Staff", parentVC: self)

                self.presentSmallViewController(userListController, sender: sender)
            }))

            alert.addAction(UIAlertAction(title: "New PRO Members", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction) -> Void in


                guard let followingUsers = FriendsController.sharedInstance.following else {
                    return
                }

                var followingUsersIds = followingUsers.map{ $0.objectId! }
                followingUsersIds.append(userProfile.objectId!)

                let userListController = Storyboard.userListViewController()

                let query = User.query()!
                query.whereKeyExists("aozoraUsername")
                query.whereKey("badges", containedIn: ["PRO","PRO+"])
                query.orderByDescending("createdAt")
                query.limit = 200
                userListController.initWithQuery(query, title: "New PRO Members", user: userProfile, parentVC: self)

                self.presentSmallViewController(userListController, sender: sender)
            }))

            alert.addAction(UIAlertAction(title: "Oldest Active Users", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction) -> Void in
                guard let followingUsers = FriendsController.sharedInstance.following else {
                    return
                }

                var followingUsersIds = followingUsers.map{ $0.objectId! }
                followingUsersIds.append(userProfile.objectId!)

                let userListController = Storyboard.userListViewController()

                let query = User.query()!
                query.whereKeyExists("aozoraUsername")
                query.whereKey("activeStart", greaterThan: NSDate().dateByAddingTimeInterval(-60*60*24*2))
                query.orderByAscending("createdAt")
                query.limit = 1000
                userListController.initWithQuery(query, title: "Oldest Active Users", user: userProfile, parentVC: self)

                self.presentSmallViewController(userListController, sender: sender)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func showProfileImage(sender: AnyObject) {
        guard let userProfile = userProfile,
            let avatarURLString = userProfile.details.avatarRegular?.url,
            let avatarURL = NSURL(string: avatarURLString) else {
            return
        }
        let photosViewController = PhotosViewController(imageURL: avatarURL)
        presentViewController(photosViewController, animated: true, completion: nil)
    }

    @IBAction func showBannerImage(sender: AnyObject) {
        guard let userProfile = userProfile,
            let bannerURLString = userProfile.banner?.url,
            let bannerURL = NSURL(string: bannerURLString) else {
            return
        }

        let photosViewController = PhotosViewController(imageURL: bannerURL)
        presentViewController(photosViewController, animated: true, completion: nil)
    }

    // MARK: - Overrides
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        let topSpace = tableView.tableHeaderView!.bounds.size.height - 44 - 64 - scrollView.contentOffset.y
        if topSpace < 0 {
            segmentedControlTopSpaceConstraint.constant = 0
        } else {
            segmentedControlTopSpaceConstraint.constant = topSpace
        }
    }

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.min
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UIDevice.isPad() ? 8.0 : 6.0
    }
}

// MARK: - EditProfileViewControllerProtocol
extension ProfileViewController: EditProfileViewControllerProtocol {
    
    func editProfileViewControllerDidEditedUser(user: User) {
        userProfile = user
        fetchUserDetails(user.aozoraUsername)
    }
}


