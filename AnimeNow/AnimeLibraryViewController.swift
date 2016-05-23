//
//  AnimeLibraryViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/21/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit
import XLPagerTabStrip

enum AnimeList: String {
    case Planning = "Planning"
    case Watching = "Watching"
    case Completed = "Completed"
    case OnHold = "On-Hold"
    case Dropped = "Dropped"
}

enum LibraryLayout: String {
    case CheckIn = "Check-In"
    case CheckInCompact = "Check-In Compact"
    case Compact = "Compact"
    
    static func allRawValues() -> [String] {
        return [
            LibraryLayout.CheckIn.rawValue,
            LibraryLayout.CheckInCompact.rawValue,
            LibraryLayout.Compact.rawValue
        ]
    }
}

class AnimeLibraryViewController: ButtonBarPagerTabStripViewController {
    
    let SortTypeDefault = "Library.SortType."
    let LayoutTypeDefault = "Library.LayoutType."
    
    var allAnimeLists: [AnimeList] = [.Watching, .Planning, .OnHold, .Completed, .Dropped]
    var listControllers: [AnimeListViewController] = []
    
    lazy var loadingView: LoaderView = {
        return LoaderView(parentView: self.view)
    }()
    
    var libraryController = LibraryController.sharedInstance
    var animator: ZFModalTransitionAnimator!

    var libraryUser: User? = User.currentUser()

    var libraryIsFromCurrentUser: Bool {
        // Crash if currentUser is nil (logged in anonymously) then opened library again
        return (libraryUser ?? User.currentUser())?.isTheCurrentUser() ?? false
    }
    
    var currentConfiguration: Configuration {
        get {
            return configurations[Int(currentIndex)]
        }
        
        set (value) {
            configurations[Int(currentIndex)] = value
        }
    }
    var configurations: [Configuration] = []

    // Only used to show the public library
    var publicLibrary: [Anime] = []

    func initWithUser(user: User) {
        libraryUser = user
    }
    
    func sortTypeForList(list: AnimeList) -> SortType {
        let key = SortTypeDefault+list.rawValue
        if let sortType = NSUserDefaults.standardUserDefaults().objectForKey(key) as? String, let sortTypeEnum = SortType(rawValue: sortType) {
            return sortTypeEnum
        } else {
            return SortType.Title
        }
    }
    
    func setSortTypeForList(sort:SortType, list: AnimeList) {
        let key = SortTypeDefault+list.rawValue
        NSUserDefaults.standardUserDefaults().setObject(sort.rawValue, forKey: key)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func layoutTypeForList(list: AnimeList) -> LibraryLayout {
        let key = LayoutTypeDefault+list.rawValue
        if let layoutType = NSUserDefaults.standardUserDefaults().objectForKey(key) as? String, let layoutTypeEnum = LibraryLayout(rawValue: layoutType) {
            return layoutTypeEnum
        } else {
            return LibraryLayout.CheckIn
        }

    }
    
    func setLayoutTypeForList(layout:LibraryLayout, list: AnimeList) {
        let key = LayoutTypeDefault+list.rawValue
        NSUserDefaults.standardUserDefaults().setObject(layout.rawValue, forKey: key)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadingView.startAnimating()

        buttonBarView.selectedBar.backgroundColor = UIColor.watching()
        settings.style.buttonBarItemBackgroundColor = .clearColor()
        settings.style.buttonBarItemFont = .boldSystemFontOfSize(14)
        settings.style.buttonBarItemsShouldFillAvailiableWidth = false
        settings.style.buttonBarItemLeftRightMargin = 12
        
        changeCurrentIndexProgressive = { [weak self] (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard let vc = self, let oldCell = oldCell, let fromIndex = vc.buttonBarView.indexPathForCell(oldCell)?.row,
                let newCell = newCell, let toIndex = vc.buttonBarView.indexPathForCell(newCell)?.row
                where changeCurrentIndex == true else { return }

            if progressPercentage > 0.5 {
                vc.buttonBarView.selectedBar.backgroundColor = vc.colorForIndex(toIndex)
            } else {
                vc.buttonBarView.selectedBar.backgroundColor = vc.colorForIndex(fromIndex)
            }
        }

        guard libraryIsFromCurrentUser else {
            title = "\(libraryUser!.aozoraUsername) Library"
            navigationController?.tabBarItem.title = ""
            fetchPublicLibrary()
            return
        }

        // Add sort icon
        let sortIcon = UIBarButtonItem(image: UIImage(named: "icon-sort"), style: .Plain, target: self, action: #selector(showFilterPressed))
        navigationItem.leftBarButtonItem = sortIcon

        // Subscribe for notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AnimeLibraryViewController.updateLibrary), name: LibraryUpdatedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AnimeLibraryViewController.controllerRequestRefresh), name: LibraryCreatedNotification, object: nil)

        // Update data
        libraryController.delegate = self
        if let library = libraryController.library {
            updateListViewControllers(library)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        canDisplayBannerAds = InAppController.canDisplayAds()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func updateLibrary() {
        fetchAnimeList(false)
    }
    
    func fetchAnimeList(isRefreshing: Bool) -> BFTask {
        
        if libraryController.currentlySyncing {
            return BFTask(result: nil)
        }
        
        if !isRefreshing {
            loadingView.startAnimating()
        }
        
        return libraryController.fetchAnimeList(isRefreshing).continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task: BFTask!) -> AnyObject? in
            
            if let library = task.result as? [Anime] {
                self.updateListViewControllers(library)
            }
            
            return nil
        })
    }

    func fetchPublicLibrary() {

        let query = AnimeProgress.query()!
        query.includeKey("anime")
        query.whereKey("user", equalTo: libraryUser!)
        query.limit = 2000
        query.findObjectsInBackground()
            .continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task: BFTask!) -> AnyObject! in

                defer {
                    self.loadingView.stopAnimating()
                }

                guard let result = task.result as? [AnimeProgress] else {
                    return nil
                }

                let allAnime = result.map({ (animeProgress) -> Anime in
                    let anime = animeProgress.anime
                    anime.publicProgress = animeProgress
                    return anime
                })

                self.publicLibrary = allAnime
                self.updateListViewControllers(allAnime)
                return nil
            })
    }
    
    func updateListViewControllers(animeList: [Anime]) {
        
        var lists: [[Anime]] = [[],[],[],[],[]]
        
        for anime in animeList {
            let progress = libraryIsFromCurrentUser ? anime.progress : anime.publicProgress

            guard let animeProgress = progress else {
                continue
            }

            switch animeProgress.myAnimeListList() {
            case .Watching:
                lists[0].append(anime)
            case .Planning:
                lists[1].append(anime)
            case .OnHold:
                lists[2].append(anime)
            case .Completed:
                lists[3].append(anime)
            case .Dropped:
                lists[4].append(anime)
            }
        }
        
        for index in 0...4 {
            let aList = lists[index]
            if aList.count > 0 {
                let controller = self.listControllers[index]
                controller.animeList = aList
                controller.updateSortType(controller.currentSortType)
            }
        }
        
        loadingView.stopAnimating()
    }
    
    // MARK: - XLPagerTabStripViewControllerDataSource

    override func viewControllersForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {

        // Initialize configurations
        for list in allAnimeLists {
            configurations.append(
                [
                    (FilterSection.View, layoutTypeForList(list).rawValue, LibraryLayout.allRawValues()),
                    (FilterSection.Sort, sortTypeForList(list).rawValue, [SortType.Title.rawValue, SortType.NextEpisodeToWatch.rawValue, SortType.NextAiringEpisode.rawValue, SortType.MyRating.rawValue, SortType.Rating.rawValue, SortType.Popularity.rawValue, SortType.Newest.rawValue, SortType.Oldest.rawValue]),
                ]
            )
        }
        
        // Initialize controllers
        let storyboard = UIStoryboard(name: "Library", bundle: nil)
        
        var lists: [AnimeListViewController] = []
        
        for index in 0...4 {
            if let controller = storyboard.instantiateViewControllerWithIdentifier("AnimeListViewController") as? AnimeListViewController {
                let animeList = allAnimeLists[index]
                
                controller.initWithList(animeList, configuration: configurations[index], isCurrentUser: libraryIsFromCurrentUser)
                controller.delegate = self
                
                lists.append(controller)
            }
        }
        
        listControllers = lists
        
        return lists
    }
    


    func colorForIndex(index: Int) -> UIColor {
        var color: UIColor?
        switch index {
        case 0:
            color = UIColor.watching()
        case 1:
            color = UIColor.planning()
        case 2:
            color = UIColor.onHold()
        case 3:
            color = UIColor.completed()
        case 4:
            color = UIColor.dropped()
        default: break
        }
        return color ?? UIColor.completed()
    }
    
    // MARK: - IBActions
    
    @IBAction func presentSearchPressed(sender: AnyObject) {
        
        guard let tabBar = tabBarController else {
            return
        }

        tabBar.presentSearchViewController(.MyLibrary)
        Analytics.tappedLibrarySearch()
    }
    
    @IBAction func showFilterPressed(sender: AnyObject) {
        
        guard let tabBar = tabBarController else {
            return
        }

        let controller = Storyboard.filterViewController()
        controller.delegate = self
        controller.initWith(configuration: currentConfiguration)
        animator = tabBar.presentViewControllerModal(controller)
        Analytics.tappedLibraryFilter()
    }

    @IBAction func showFavoritesPressed(sender: AnyObject) {
        guard let libraryUser = libraryUser else {
            return
        }

        if !InAppController.hasAnyPro() {
            PurchaseViewController.showInAppPurchaseWith(self.tabBarController!)
            return
        }

        let publicList = Storyboard.publicListViewController()
        if libraryIsFromCurrentUser {
            let library = LibraryController.sharedInstance.library ?? []
            for anime in library {
                anime.publicProgress = anime.progress
            }
            publicList.initWithUser(libraryUser, library: library)
        } else {
            publicList.initWithUser(libraryUser, library: publicLibrary)
        }

        publicList.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(publicList, animated: true)
    }
}


extension AnimeLibraryViewController: FilterViewControllerDelegate {
    func finishedWith(configuration configuration: Configuration, selectedGenres: [String]) {

        let currentListIndex = Int(currentIndex)
        currentConfiguration = configuration
        listControllers[currentListIndex].currentConfiguration = currentConfiguration
        
        if let value = currentConfiguration[0].value,
            let layoutType = LibraryLayout(rawValue: value) {
                setLayoutTypeForList(layoutType, list: allAnimeLists[currentListIndex])
        }
        
        if let value = currentConfiguration[1].value,
            let sortType = SortType(rawValue: value) {
                setSortTypeForList(sortType, list: allAnimeLists[currentListIndex])
        }
    }
}

extension AnimeLibraryViewController: AnimeListControllerDelegate {
    func controllerRequestRefresh() -> BFTask {
        return fetchAnimeList(true)
    }
}

extension AnimeLibraryViewController: LibraryControllerDelegate {
    func libraryControllerFinishedFetchingLibrary(library: [Anime]) {
        updateListViewControllers(library)
    }
}