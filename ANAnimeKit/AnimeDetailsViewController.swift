//
//  AnimeDetailsViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/9/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import Shimmer
import ANCommonKit
import XCDYouTubeKit
import FBSDKShareKit
import TTTAttributedLabel
import NYTPhotoViewer

enum AnimeSection: Int {
    case Information = 0
    case ExternalLinks
    case Relations
    case Synopsis
    case Character
    case Cast
    
    static var allSections: [AnimeSection] = [.Synopsis,.Relations,.Information,.ExternalLinks, .Character, .Cast]
}

extension AnimeDetailsViewController: StatusBarVisibilityProtocol {
    func shouldHideStatusBar() -> Bool {
        return hideStatusBar()
    }
    func updateCanHideStatusBar(canHide: Bool) {
        canHideStatusBar = canHide
    }
}

extension AnimeDetailsViewController: CustomAnimatorProtocol {
    func scrollView() -> UIScrollView? {
        return tableView
    }
}

public class AnimeDetailsViewController: AnimeBaseViewController {
    
    let HeaderCellHeight: CGFloat = 39
    var HeaderViewHeight: CGFloat = 0
    let TopBarHeight: CGFloat = 44
    let StatusBarHeight: CGFloat = 22
    
    var canHideStatusBar = true
    var subAnimator: ZFModalTransitionAnimator!
    var playerController: XCDYouTubeVideoPlayerViewController?

    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var rateButton: SpacerButton!
    @IBOutlet weak var reminderButton: SpacerButton!
    @IBOutlet weak var favoriteButton: SpacerButton!

    var loadingView: LoaderView!
    
    @IBOutlet weak var trailerButton: UIButton!
    @IBOutlet weak var shimeringView: FBShimmeringView!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var navigationBarTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var navigationBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var etaLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var ranksView: UIView!
    
    @IBOutlet weak var animeTitle: UILabel!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var membersCountLabel: UILabel!
    @IBOutlet weak var scoreRankLabel: UILabel!
    @IBOutlet weak var popularityRankLabel: UILabel!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var fanartImageView: UIImageView!


    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.estimatedRowHeight = 44.0
            tableView.rowHeight = UITableViewAutomaticDimension
            if UIDevice.isPad() {
                let header = tableView.tableHeaderView!
                var frame = header.frame
                frame.size.height = 580 - 44 - 30
                tableView.tableHeaderView?.frame = frame
            }
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        HeaderViewHeight = UIDevice.isPad() ? 400 : 274
        
        shimeringView.contentView = animeTitle
        shimeringView.shimmering = true

        loadingView = LoaderView(parentView: view)
        
        ranksView.hidden = true
        fetchCurrentAnime()
        updateInformationWithAnime()

        // Video notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AnimeDetailsViewController.moviePlayerPlaybackDidFinish(_:)), name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)

    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        canHideStatusBar = true
        self.scrollViewDidScroll(tableView)
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        customTabBar.setCurrentViewController(self)
    }
    
    func fetchCurrentAnime() {
        loadingView.startAnimating()
        
        let query = Anime.queryWith(objectID: anime.objectId!)
        query.includeKey("details")
        query.includeKey("relations")
        query.includeKey("characters")
        query.includeKey("cast")
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in

            if let anime = objects?.first as? Anime {

                anime.progress = self.anime.progress

                Analytics.viewedAnimeDetail(
                    title: anime.title ?? "Unknown",
                    id: anime.objectId!,
                    list: self.anime.progress?.list ?? "Non-saved"
                )
                self.customTabBar.anime = anime
                self.updateInformationWithAnime()
            }
        }
    }
    
    func updateInformationWithAnime() {
        if !anime.details.dataAvailable || !isViewLoaded() {
            return
        }

        ranksView.hidden = false
        
        if let progress = anime.progress {
            updateListButtonTitle(progress.list)
            updateRateButtonWithScore(progress.score)
            updateFavoriteButton(progress.isFavorite)
        } else {
            updateListButtonTitle("ADD TO LIST ")
            updateRateButtonWithScore(0)
        }

        let reminderIsScheduled = ReminderController.scheduledReminderFor(anime) != nil
        ReminderController.updateScheduledLocalNotifications()
        updateReminderButtonEnabled(reminderIsScheduled)

        reminderButton.enabled = ReminderController.canScheduleReminderForAnime(anime)
        
        animeTitle.text = anime.title
        tagsLabel.text = anime.informationString()
        
        if let status = AnimeStatus(rawValue: anime.status) {
            switch status {
            case .CurrentlyAiring:
                etaLabel.text = "Airing    "
                etaLabel.backgroundColor = UIColor.watching()
            case .FinishedAiring:
                etaLabel.text = "Aired    "
                etaLabel.backgroundColor = UIColor.completed()
            case .NotYetAired:
                etaLabel.text = "Not Aired    "
                etaLabel.backgroundColor = UIColor.planning()
            }
        }
        
        ratingLabel.text = String(format:"%.2f", anime.membersScore)
        membersCountLabel.text = "\(NumberFormatter.number(anime.membersCount))\nusers"
        scoreRankLabel.text = "#\(anime.rank)"
        popularityRankLabel.text = "#\(anime.popularityRank)"
        
        posterImageView.setImageFrom(urlString: anime.imageUrl)
        fanartImageView.setImageFrom(urlString: anime.fanartURLString())
        
        if let youtubeID = anime.details.youtubeID where youtubeID.characters.count > 0 {
            trailerButton.hidden = false
            trailerButton.layer.borderWidth = 1.0;
            trailerButton.layer.borderColor = UIColor(white: 1.0, alpha: 0.5).CGColor;
        } else {
            trailerButton.hidden = true
        }
        
        loadingView.stopAnimating()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }

    func updateRateButtonWithScore(score: Int) {
        var title = ""
        switch score {
            case 0: title = " RATE"
            case 1: title = ""
            case 2: title = ""
            case 3: title = ""
            case 4: title = ""
            case 5: title = ""
            case 6: title = ""
            case 7: title = ""
            case 8: title = ""
            case 9: title = ""
            case 10: title = ""
        default:
            break
        }

        rateButton.setTitle(title, forState: .Normal)
    }

    func updateReminderButtonEnabled(enabled: Bool) {
        let buttonTitle = enabled ? " ON" : " OFF"
        reminderButton.setTitle(buttonTitle, forState: .Normal)
    }

    func updateFavoriteButton(favorited: Bool) {
        if favorited {
            favoriteButton.setImage(UIImage(named: "icon-like-filled-small"), forState: .Normal)
        } else {
            favoriteButton.setImage(UIImage(named: "icon-like-empty-small"), forState: .Normal)
        }

    }
    
    // MARK: - IBActions
    
    @IBAction func showFanart(sender: AnyObject) {
        
        var imageString = ""
        
        if let fanartUrl = anime.fanart where fanartUrl.characters.count != 0 {
            imageString = fanartUrl
        } else {
            imageString = anime.imageUrl
        }
        
        guard let imageURL = NSURL(string: imageString) else {
            return
        }

        let photosViewController = PhotosViewController(imageURL: imageURL)
        presentViewController(photosViewController, animated: true, completion: nil)
    }
    
    @IBAction func showPoster(sender: AnyObject) {
        
        let hdImage = anime.imageUrl.stringByReplacingOccurrencesOfString(".jpg", withString: "l.jpg")
        guard let imageURL = NSURL(string: hdImage) else {
            return
        }

        let photosViewController = PhotosViewController(imageURL: imageURL)
        presentViewController(photosViewController, animated: true, completion: nil)
    }
   
    
    @IBAction func dismissViewController(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func playTrailerPressed(sender: AnyObject) {
        
        if let trailerURL = anime.details.youtubeID {
            playerController = XCDYouTubeVideoPlayerViewController(videoIdentifier: trailerURL)
            presentMoviePlayerViewControllerAnimated(playerController)
        }
    }
    
    @IBAction func addToListPressed(sender: AnyObject) {
        
        let progress = anime.progress
        
        var title: String = ""
        if progress == nil {
            title = "ADD TO LIST"
        } else {
            title = "MOVE TO LIST"
        }
        
        let alert = UIAlertController(title: title, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        alert.popoverPresentationController?.sourceView = listButton.superview
        alert.popoverPresentationController?.sourceRect = listButton.frame
        
        alert.addAction(UIAlertAction(title: "Watching", style: UIAlertActionStyle.Default, handler: { [weak self] (alertAction: UIAlertAction!) -> Void in
            self?.updateProgressWithList(.Watching)
        }))
        alert.addAction(UIAlertAction(title: "Planning", style: UIAlertActionStyle.Default, handler: { [weak self] (alertAction: UIAlertAction!) -> Void in
            self?.updateProgressWithList(.Planning)
        }))
        alert.addAction(UIAlertAction(title: "On-Hold", style: UIAlertActionStyle.Default, handler: { [weak self] (alertAction: UIAlertAction!) -> Void in
            self?.updateProgressWithList(.OnHold)
        }))
        alert.addAction(UIAlertAction(title: "Completed", style: UIAlertActionStyle.Default, handler: { [weak self] (alertAction: UIAlertAction!) -> Void in
            self?.updateProgressWithList(.Completed)
        }))
        alert.addAction(UIAlertAction(title: "Dropped", style: UIAlertActionStyle.Default, handler: { [weak self] (alertAction: UIAlertAction!) -> Void in
            self?.updateProgressWithList(.Dropped)
        }))
        
        if let progress = progress {
            alert.addAction(UIAlertAction(title: "Remove from Library", style: UIAlertActionStyle.Destructive, handler: { [weak self] (alertAction: UIAlertAction!) -> Void in
                
                self?.loadingView.startAnimating()
                let deleteFromMALTask = LibrarySyncController.deleteAnime(progress)
                let deleteFromParseTask = progress.deleteInBackground()
                    
                BFTask(forCompletionOfAllTasks: [deleteFromMALTask, deleteFromParseTask]).continueWithExecutor(BFExecutor.mainThreadExecutor(), withSuccessBlock: { (task: BFTask!) -> AnyObject! in
                
                    self?.loadingView.stopAnimating()
                    self?.anime.progress = nil
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(LibraryUpdatedNotification, object: nil)
                
                    self?.dismissViewControllerAnimated(true, completion: nil)
                    
                    return nil
                })
                
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:nil))
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func updateProgressWithList(list: MALList) {

        if let progress = anime.progress {
            progress.updateList(list)
            LibrarySyncController.updateAnime(progress)
            progress.saveInBackgroundWithBlock({ (result, error) -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(LibraryUpdatedNotification, object: nil)
            })
            updateListButtonTitle(progress.list)
            Analytics.tappedAnimeDetailChangeList(list.rawValue, saved: false)
        } else {
            
            // Create!
            let progress = AnimeProgress()
            progress.anime = anime
            progress.user = User.currentUser()!
            progress.startDate = NSDate()
            progress.updateList(list)
            progress.watchedEpisodes = 0
            progress.collectedEpisodes = 0
            progress.score = 0
            
            let query = AnimeProgress.query()!
            query.whereKey("anime", equalTo: anime)
            query.whereKey("user", equalTo: User.currentUser()!)
            query.findObjectsInBackgroundWithBlock({ (result, error) -> Void in
                if let _ = error {
                    // Handle error
                } else if let result = result as? [AnimeProgress] where result.count == 0 {
                    // Create AnimeProgress, if it's not on Parse
                    LibrarySyncController.addAnime(progress)
                    self.anime.progress = progress
                    
                    progress.saveInBackground().continueWithExecutor(BFExecutor.mainThreadExecutor(), withSuccessBlock: { (task: BFTask!) -> AnyObject! in
                        
                        NSNotificationCenter.defaultCenter().postNotificationName(LibraryUpdatedNotification, object: nil)
                        return nil
                    })
                    self.updateListButtonTitle(progress.list)
                } else {
                    self.presentAlertWithTitle("Anime already in Library", message: "You might need to sync your library first, select 'Library' tab")
                }
            })
            Analytics.tappedAnimeDetailChangeList(list.rawValue, saved: true)
        }
    }
    
    func updateListButtonTitle(string: String) {
        listButton.setTitle(string.uppercaseString + " " + FontAwesome.AngleDown.rawValue, forState: .Normal)
    }

    @IBAction func rateAnimePressed(sender: AnyObject) {
        if let progress = anime.progress, let tabBarController = tabBarController, let title = anime.title {
            RateViewController.showRateDialogWith(tabBarController, title: "Rate \(title)", initialRating: Float(progress.score)/2.0, anime: anime, delegate: self)
        } else {
            presentAlertWithTitle("Not saved", message: "Add the anime to your library first")
        }

    }

    @IBAction func reminderPressed(sender: AnyObject) {
        guard let _ = anime.nextEpisode else {

            return
        }

        let scheduledReminder = ReminderController.scheduledReminderFor(anime)

        if let _ = anime.progress, let _ = tabBarController, let _ = anime.title {
            if let _ = scheduledReminder {
                ReminderController.disableReminderForAnime(anime)
                updateReminderButtonEnabled(false)
            } else {
                let success = ReminderController.scheduleReminderForAnime(anime)
                updateReminderButtonEnabled(success)
            }
        } else {
            presentAlertWithTitle("Not saved", message: "Add the anime to your library first")
        }
    }
    
    @IBAction func favoritePressed(sender: AnyObject) {

        guard let progress = anime.progress else {
            return
        }

        if !didOnce("AnimeDetails.ExplainFavoriteButton") {
            presentAlertWithTitle("Favorite Anime", message: "Add or remove anime from your public favorite anime list, see the list in profile.")
        }

        favoriteButton.animateBounce()
        progress.isFavorite = !progress.isFavorite
        progress.saveInBackground()
        updateFavoriteButton(progress.isFavorite)
    }

    @IBAction func moreOptionsPressed(sender: AnyObject) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        alert.popoverPresentationController?.sourceView = sender.superview
        alert.popoverPresentationController?.sourceRect = sender.frame

        alert.addAction(UIAlertAction(title: "Send on Messenger", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction) -> Void in
            
            let photo = FBSDKSharePhoto()
            photo.image = self.fanartImageView.image
            
            let content = FBSDKSharePhotoContent()
            content.photos = [photo]
            
            FBSDKMessageDialog.showWithContent(content, delegate: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Share on Facebook", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction) -> Void in
            
            let photo = FBSDKSharePhoto()
            photo.image = self.fanartImageView.image
            
            let content = FBSDKSharePhotoContent()
            content.photos = [photo]
            
            FBSDKShareDialog.showFromViewController(self, withContent: content, delegate: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Share", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction) -> Void in
            
            var textToShare = ""
            
            if let progress = self.anime.progress {
                
                switch progress.myAnimeListList() {
                case .Planning:
                   textToShare += "I'm planning to watch"
                case .Watching:
                    textToShare += "I'm watching"
                case .Completed:
                    textToShare += "I've completed"
                case .Dropped:
                    textToShare += "I've dropped"
                case .OnHold:
                    textToShare += "I'm watching"
                }
                textToShare += " \(self.anime.title!) via #AozoraApp"
            } else {
                textToShare = "Check out \(self.anime.title!) via #AozoraApp"
            }
            
            
            var objectsToShare: [AnyObject] = [textToShare]
            if let image = self.fanartImageView.image {
                objectsToShare.append( image )
            }
            
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList,UIActivityTypePrint];
            self.presentViewController(activityVC, animated: true, completion: nil)
            
        }))

        alert.addAction(UIAlertAction(title: "Refresh Images", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction!) -> Void in
            let params = ["malID": self.anime.myAnimeListID]
            PFCloud.callFunctionInBackground("updateAnimeInformation", withParameters: params, block: { (result, error) -> Void in
                self.presentAlertWithTitle("Refreshing..", message: "Data will be refreshed soon")
                print("Refreshed!!")
            })
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    // MARK: - Helper Functions
    
    func hideStatusBar() -> Bool {
        guard let scroll = scrollView() else {
            return false
        }
        let offset = HeaderViewHeight - scroll.contentOffset.y - TopBarHeight
        return offset > StatusBarHeight ? true : false
    }
    
    // MARK: - Notifications
    
    func moviePlayerPlaybackDidFinish(notification: NSNotification) {
        playerController = nil;
    }
    

}

extension AnimeDetailsViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        
        let newOffset = HeaderViewHeight-scrollView.contentOffset.y
        let topBarOffset = newOffset - TopBarHeight
        
        if topBarOffset > StatusBarHeight {
            if !UIApplication.sharedApplication().statusBarHidden {
                if canHideStatusBar {
                    UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.None)
                    separatorView.hidden = true
                    closeButton.hidden = true
                    navigationBarHeightConstraint.constant = TopBarHeight
                }
            }
            navigationBarTopConstraint.constant = topBarOffset
            
        } else {
            if UIApplication.sharedApplication().statusBarHidden {
                UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Fade)
            }
            separatorView.hidden = false
            closeButton.hidden = false
            let totalHeight = TopBarHeight + StatusBarHeight
            if totalHeight - topBarOffset <= totalHeight {
                navigationBarHeightConstraint.constant = totalHeight - topBarOffset
                navigationBarTopConstraint.constant = topBarOffset
            } else {
                navigationBarHeightConstraint.constant = totalHeight
                navigationBarTopConstraint.constant = 0
            }
        }
    }
}

extension AnimeDetailsViewController: UITableViewDataSource {
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return anime.dataAvailable ? AnimeSection.allSections.count : 0
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var numberOfRows = 0
        switch AnimeSection(rawValue: section)! {
        case .Synopsis: numberOfRows = 1
        case .Relations: numberOfRows = anime.relations.totalRelations
        case .Information: numberOfRows = 11
        case .ExternalLinks: numberOfRows = anime.externalLinks.isEmpty ? 0 : 1
        case .Character: numberOfRows = anime.characters.characters.count
        case .Cast: numberOfRows = anime.cast.cast.count
        }
        
        return numberOfRows
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {


        func formatInformationCellWithLabel(attributedLabel: TTTAttributedLabel, title: String, detail: String) {
            attributedLabel.setText("\(title) \(detail)", afterInheritingLabelAttributesAndConfiguringWithBlock: { (mutableAttributedString) -> NSMutableAttributedString! in

                let mediumFont = UIFont.systemFontOfSize(13)
                let mediumFontRef = CTFontCreateWithName(mediumFont.fontName, mediumFont.pointSize, nil)
                let colorRef = UIColor.textBlue().CGColor

                let textRange = mutableAttributedString.nsRangeOfString(title)

                mutableAttributedString.setFont(mediumFontRef, inRange: textRange)
                mutableAttributedString.setColor(colorRef, inRange: textRange)

                return mutableAttributedString

            })
        }
        switch AnimeSection(rawValue: indexPath.section)! {
        case .Synopsis:
            let cell = tableView.dequeueReusableCellWithIdentifier("SynopsisCell") as! SynopsisCell
            cell.synopsisLabel.attributedText = anime.details.attributedSynopsis()
            cell.layoutIfNeeded()
            return cell
        case .Relations:
            let cell = tableView.dequeueReusableCellWithIdentifier("InformationCell2") as! InformationCell
            let relation = anime.relations.relationAtIndex(indexPath.row)
            formatInformationCellWithLabel(
                cell.attributedLabel,
                title: relation.relationType.rawValue+":",
                detail: relation.title)
            cell.accessoryType = .DisclosureIndicator
            cell.layoutIfNeeded()
            return cell
        case .Information:
            let cell = tableView.dequeueReusableCellWithIdentifier("InformationCell") as! InformationCell
            cell.accessoryType = .None

            var title = ""
            var detail = ""
            switch indexPath.row {
            case 0:
                title = "Type"
                detail = anime.type
            case 1:
                title = "Episodes"
                detail = (anime.episodes != 0) ? anime.episodes.description : "?"
            case 2:
                title = "Status"
                detail = anime.status.capitalizedString
            case 3:
                title = "Aired"
                let startDate = anime.startDate != nil && anime.startDate?.compare(NSDate(timeIntervalSince1970: 0)) != NSComparisonResult.OrderedAscending ? anime.startDate!.mediumDate() : "?"
                let endDate = anime.endDate != nil && anime.endDate?.compare(NSDate(timeIntervalSince1970: 0)) != NSComparisonResult.OrderedAscending ? anime.endDate!.mediumDate() : "?"
                detail = "\(startDate) - \(endDate)"
            case 4:
                title = "Producers"
                detail = anime.producers.joinWithSeparator(", ")
            case 5:
                title = "Genres"
                detail = anime.genres.joinWithSeparator(", ")
            case 6:
                title = "Duration"
                let duration = (anime.duration != 0) ? anime.duration.description : "?"
                detail = "\(duration) min"
            case 7:
                title = "Classification"
                detail = anime.details.classification
            case 8:
                title = "English Titles"
                detail = anime.details.englishTitles.count != 0 ? anime.details.englishTitles.joinWithSeparator("\n") : "-"
            case 9:
                title = "Japanese Titles"
                detail = anime.details.japaneseTitles.count != 0 ? anime.details.japaneseTitles.joinWithSeparator("\n") : "-"
            case 10:
                title = "Synonyms"
                detail = anime.details.synonyms.count != 0 ? anime.details.synonyms.joinWithSeparator("\n") : "-"
            default:
                break
            }

            formatInformationCellWithLabel(
                cell.attributedLabel,
                title: title+":",
                detail: detail)


            cell.layoutIfNeeded()
            return cell
        
        case .ExternalLinks:

            let cell = tableView.dequeueReusableCellWithIdentifier("LinksCollectionTableCell") as! LinksCollectionTableCell
            
            cell.dataSource = anime.links()
            cell.selectedLinkCallBack = { [weak self] link in

                let webController = Storyboard.webBrowserViewController()
                let initialUrl = NSURL(string: link.url)
                webController.initWithInitialUrl(initialUrl)
                webController.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(webController, animated: true)
            }

            cell.collectionView.reloadData()
            return cell
        case .Character:
            let cell = tableView.dequeueReusableCellWithIdentifier("CharacterCell") as! CharacterCell

            let character = anime.characters.characterAtIndex(indexPath.row)

            cell.characterImageView.setImageFrom(urlString: character.image, animated:true)
            cell.characterName.text = character.name
            cell.characterRole.text = character.role
            if let japaneseVoiceActor = character.japaneseActor {
                cell.personImageView.setImageFrom(urlString: japaneseVoiceActor.image, animated:true)
                cell.personName.text = japaneseVoiceActor.name
                cell.personJob.text = japaneseVoiceActor.job
            } else {
                cell.personImageView.image = nil
                cell.personName.text = ""
                cell.personJob.text = ""
            }

            cell.layoutIfNeeded()
            return cell
        case .Cast:
            let cell = tableView.dequeueReusableCellWithIdentifier("CastCell") as! CharacterCell

            let cast = anime.cast.castAtIndex(indexPath.row)

            cell.personImageView.setImageFrom(urlString: cast.image)
            cell.personName.text = cast.name
            cell.personJob.text = cast.job
            cell.layoutIfNeeded()
            return cell
        }
    }
    
    public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("TitleCell") as! TitleCell
        var title = ""
        
        switch AnimeSection(rawValue: section)! {
        case .Synopsis:
            title = "Synopsis"
        case .Relations:
            title = "Relations"
        case .Information:
            title = "Information"
        case .ExternalLinks:
            title = "External Links"
        case .Character:
            title = "Characters"
        case .Cast:
            title = "Cast"
        }
        
        cell.titleLabel.text = title
        return cell.contentView
    }
    
    public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.tableView(tableView, numberOfRowsInSection: section) > 0 ? HeaderCellHeight : CGFloat.min
    }

}

extension AnimeDetailsViewController: UITableViewDelegate {
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let section = AnimeSection(rawValue: indexPath.section)!
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        switch section {
            
        case .Synopsis:
                break
        case .Relations:
            
            let relation = anime.relations.relationAtIndex(indexPath.row)
            // TODO: Parse is fetching again inside presenting AnimeInformationVC
            let query = Anime.queryWith(malID: relation.animeID)
            query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
                if let anime = objects?.first as? Anime {
                    self.subAnimator = self.presentAnimeModal(anime)
                }
            }

        case .Information:
            break
        case .ExternalLinks:
            break
        case .Character:
            let character = anime.characters.characterAtIndex(indexPath.row)
            let imageURL = NSURL(string: character.image)!
            let photosViewController = PhotosViewController(imageURL: imageURL)
            presentViewController(photosViewController, animated: true, completion: nil)
        case .Cast:
            let cast = anime.cast.castAtIndex(indexPath.row)
            let imageURL = NSURL(string: cast.image)!
            let photosViewController = PhotosViewController(imageURL: imageURL)
            presentViewController(photosViewController, animated: true, completion: nil)
        }

    }
}

extension AnimeDetailsViewController: RateViewControllerProtocol {
    
    public func rateControllerDidFinishedWith(anime anime: Anime, rating: Float) {
        
        RateViewController.updateAnime(anime, withRating: rating*2.0)
        updateInformationWithAnime()
    }
}
