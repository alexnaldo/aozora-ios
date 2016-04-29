//
//  ChartViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/4/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import Alamofire
import ANCommonKit

class ChartController {
    class func seasonalChartAnimeQuery(seasonalChart: SeasonalChart) -> PFQuery {
        let query = Anime.query()!
        query.whereKey("startDate", greaterThanOrEqualTo: seasonalChart.startDate)
        query.whereKey("startDate", lessThanOrEqualTo: seasonalChart.endDate)

        let query2 = Anime.query()!

        let laterDate = seasonalChart.startDate.compare(NSDate()) == NSComparisonResult.OrderedAscending ? NSDate() : seasonalChart.startDate
        query2.whereKey("endDate", greaterThanOrEqualTo: laterDate)
        query2.whereKey("endDate", lessThanOrEqualTo: seasonalChart.endDate)

        let orQuery = PFQuery.orQueryWithSubqueries([query, query2])
        orQuery.orderByDescending("membersCount")

        return orQuery
    }

    class func allSeasonsQuery() -> PFQuery {
        let query = SeasonalChart.query()!
        query.orderByDescending("startDate")
        query.limit = 1000
        return query
    }
}


class ChartViewController: UIViewController {
    
    let SortTypeDefault = "Season.SortType"
    let LayoutTypeDefault = "Season.LayoutType"
    let FirstHeaderCellHeight: CGFloat = 88.0
    let HeaderCellHeight: CGFloat = 44.0
    
    var canFadeImages = true
    var showTableView = true
    
    var currentConfiguration: Configuration!

    var timer: NSTimer!
    var animator: ZFModalTransitionAnimator!
    
    var dataSource: [[Anime]] = [] {
        didSet {
            filteredDataSource = dataSource
        }
    }
    
    var filteredDataSource: [[Anime]] = [] {
        didSet {
            if isViewLoaded() {
                canFadeImages = false
                self.collectionView.reloadData()
                canFadeImages = true
            }
        }
    }
    
    var currentSortType: SortType {
        get {
            guard let sortType = NSUserDefaults.standardUserDefaults().objectForKey(SortTypeDefault) as? String,
                let sortTypeEnum = SortType(rawValue: sortType) else {
                return SortType.Popularity
            }
            return sortTypeEnum
        }
        set ( value ) {
            NSUserDefaults.standardUserDefaults().setObject(value.rawValue, forKey: SortTypeDefault)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }

    var loadingView: LoaderView!
    var query: PFQuery?
    var controllerTitle: String!

    func initWithQuery(title: String, query: PFQuery) {
        self.query = query
        controllerTitle = title
    }

    func initWithDataSource(title: String, dataSource: [Anime]) {
        self.dataSource = dataSourceSplittedByType(dataSource)
        controllerTitle = title
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var navigationBarTitle: UILabel!
    @IBOutlet weak var filterBar: UIView!
    @IBOutlet weak var navigationItemView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = controllerTitle

        DialogController.sharedInstance.canShowFBAppInvite(self)

        collectionView.registerNibWithClass(AnimeCell.self)
        
        // Update configuration
        currentConfiguration = [
            (FilterSection.Sort, currentSortType.rawValue, [SortType.Rating.rawValue, SortType.Popularity.rawValue, SortType.Title.rawValue, SortType.NextAiringEpisode.rawValue])
        ]

        timer = NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: #selector(ChartViewController.updateETACells), userInfo: nil, repeats: true)
        
        loadingView = LoaderView(parentView: view)

        if let query = query {
            fetchQuery(query)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChartViewController.updateETACells), name: LibraryUpdatedNotification, object: nil)

        updateLayoutWithSize(view.bounds.size)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        updateLayoutWithSize(size)
    }
    
    // MARK: - UI Functions
    
    func updateETACells() {
        canFadeImages = false
        let indexPaths = collectionView.indexPathsForVisibleItems()
        collectionView.reloadItemsAtIndexPaths(indexPaths)
        canFadeImages = true
    }
    
    func fetchQuery(query: PFQuery) {

        collectionView.animateFadeOut()
        loadingView.startAnimating()

        query.findObjectsInBackground().continueWithSuccessBlock { (task: BFTask!) -> AnyObject! in
            
            guard let result = task.result as? [Anime] else {
                return nil
            }
            LibrarySyncController.matchAnimeWithProgress(result)
            return BFTask(result: result)
            
        }.continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task: BFTask!) -> AnyObject! in

            if let result = task.result as? [Anime] {
                self.dataSource = self.dataSourceSplittedByType(result)
                self.updateSortType(self.currentSortType)
            }
            
            self.loadingView.stopAnimating()
            self.collectionView.animateFadeIn()
            return nil
        })
    }

    func dataSourceSplittedByType(dataSource: [Anime]) -> [[Anime]] {
        let tvAnime = dataSource.filter({$0.type == "TV"})
        let tv = tvAnime.filter({$0.duration == 0 || $0.duration > 15})
        let tvShort = tvAnime.filter({$0.duration > 0 && $0.duration <= 15})
        let movieAnime = dataSource.filter({$0.type == "Movie"})
        let ovaAnime = dataSource.filter({$0.type == "OVA"})
        let onaAnime = dataSource.filter({$0.type == "ONA"})
        let specialAnime = dataSource.filter({$0.type == "Special"})

        return [tv, tvShort, movieAnime, ovaAnime, onaAnime, specialAnime]
    }


    // MARK: - Utility Functions

    func updateSortType(sortType: SortType) {
        
        currentSortType = sortType
        
        dataSource = dataSource.map() { animeArray -> [Anime] in
            var result: [Anime] = []
            switch self.currentSortType {
            case .Rating:
                result = animeArray.sort({ $0.rank < $1.rank && $0.rank != 0 })
            case .Popularity:
                result = animeArray.sort({ $0.popularityRank < $1.popularityRank})
            case .Title:
                result = animeArray.sort({ $0.title < $1.title})
            case .NextAiringEpisode:
                result = animeArray.sort({ (anime1: Anime, anime2: Anime) in
                    
                    let startDate1 = anime1.nextEpisodeDate ?? NSDate(timeIntervalSinceNow: 60*60*24*100)
                    let startDate2 = anime2.nextEpisodeDate ?? NSDate(timeIntervalSinceNow: 60*60*24*100)
                    return startDate1.compare(startDate2) == .OrderedAscending
                })
            default:
                break;
            }
            return result
        }
        
        // Filter
        searchBar(searchBar, textDidChange: searchBar.text!)
    }
    
    func updateLayoutWithSize(viewSize: CGSize) {
        
        guard let collectionView = collectionView,
            let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
                return
        }

        AnimeCell.updateLayoutItemSizeWithLayout(layout, viewSize: viewSize)

        canFadeImages = false
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
        canFadeImages = true
    }
    
    // MARK: - IBActions
    
    @IBAction func showFilterPressed(sender: AnyObject) {
        
        if let tabBar = tabBarController {
            let controller = Storyboard.filterViewController()
            
            controller.delegate = self
            controller.initWith(configuration: currentConfiguration)
            animator = tabBar.presentViewControllerModal(controller)
        }
        
    }
}

extension ChartViewController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return filteredDataSource.count
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredDataSource[section].count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCellWithClass(AnimeCell.self, indexPath: indexPath) else {
            return UICollectionViewCell()
        }

        let anime = filteredDataSource[indexPath.section][indexPath.row]
        cell.configureWithAnime(anime, canFadeImages: canFadeImages, showEtaAsAired: false)
        cell.layoutIfNeeded()
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        var reusableView: UICollectionReusableView!
        
        if kind == UICollectionElementKindSectionHeader {
            
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "HeaderView", forIndexPath: indexPath) as! BasicCollectionReusableView
    
                var title = ""
                switch indexPath.section {
                case 0: title = "TV"
                case 1: title = "TV Short"
                case 2: title = "Movie"
                case 3: title = "OVA"
                case 4: title = "ONA"
                case 5: title = "Special"
                default: break
                }
                
                headerView.titleLabel.text = title
            
            
            reusableView = headerView;
        }
        
        return reusableView
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if filteredDataSource[section].count == 0 {
                return CGSize.zero
        } else {
            let height = (section == 0) ? FirstHeaderCellHeight : HeaderCellHeight
            return CGSize(width: view.bounds.size.width, height: height)
        }
    }
    
}

extension ChartViewController: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        view.endEditing(true)

        let anime = filteredDataSource[indexPath.section][indexPath.row]
        animator = presentAnimeModal(anime)
    }
}

extension ChartViewController: UISearchBarDelegate {
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchBar.text == "" {
            filteredDataSource = dataSource
            return
        }
        
        filteredDataSource = dataSource.map { animeTypeArray -> [Anime] in
            func filterText(anime: Anime) -> Bool {
                return (anime.title!.rangeOfString(searchBar.text!) != nil) ||
                    (anime.genres.joinWithSeparator(" ").rangeOfString(searchBar.text!) != nil)
                
            }
            return animeTypeArray.filter(filterText)
        }
        
    }
}

extension ChartViewController: FilterViewControllerDelegate {
    func finishedWith(configuration configuration: Configuration, selectedGenres: [String]) {
        
        currentConfiguration = configuration
        
        for (filterSection, value, _) in configuration {
            if let value = value {
                switch filterSection {
                case .Sort:
                    updateSortType(SortType(rawValue: value)!)
                case .View:
                    updateLayoutWithSize(view.bounds.size)
                default: break
                }
            }
        }
    
    }
    
}