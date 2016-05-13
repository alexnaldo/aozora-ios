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

class PublicListViewController: UIViewController {
    
    let FirstHeaderCellHeight: CGFloat = 64.0
    
    var canFadeImages = true
    var showTableView = true

    var animator: ZFModalTransitionAnimator!

    var library: [Anime] = []
    var dataSource: [[Anime]] = [[]]
    
    var filteredDataSource: [[Anime]] = [[]] {
        didSet {
            canFadeImages = false
            self.collectionView.reloadData()
            canFadeImages = true
        }
    }
    
    var chartsDataSource: [SeasonalChart] = [] {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    var loadingView: LoaderView!
    var userProfile: User!
    var sectionTitles: [String] = ["Favorites"]
    var sectionSubtitles: [String] = [""]
    var totalSubtitle: String = ""
    var totalWatchedMinutes: Int = 0
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var navigationBarTitle: UILabel!
    @IBOutlet weak var filterBar: UIView!
    
    func initWithUser(user: User, library: [Anime]) {
        userProfile = user
        self.library = library
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.registerNibWithClass(AnimeCell)
        loadingView = LoaderView(parentView: view)

        updateLayout(withSize: view.bounds.size)

        if userProfile.isTheCurrentUser() {
            title = "Favorite List"
        } else {
            title = "\(userProfile.aozoraUsername) Favorite List"
        }

        updateSections(library)
        calculateLibraryStats(library)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        updateLayout(withSize: size)
        
    }

    func updateSections(result: [Anime]) {
        let result = result.sort{ (progress1: Anime, progress2: Anime) -> Bool in
            if progress1.type == progress2.type {
                return progress1.title! < progress2.title
            } else {
                return progress1.type > progress2.type
            }
        }

        for anime in result {
            // HandleDifferent lists
            if anime.publicProgress!.isFavorite {
                dataSource[0].append(anime)
            }
        }
        filteredDataSource = dataSource

        for i in 0 ..< dataSource.count  {
            let animeList = dataSource[i]

            var tvCount = 0
            var moviesCount = 0
            var restCount = 0
            for anime in animeList {
                switch anime.type {
                case "TV":
                    tvCount += 1
                case "Movie":
                    moviesCount += 1
                default:
                    restCount += 1
                }
            }

            sectionSubtitles[i] = "\(tvCount) TV · \(moviesCount) Movie · \(restCount) OVA/ONA/Specials"
        }
    }

    func calculateLibraryStats(library: [Anime]) {
        var tvTotalCount = 0
        var moviesTotalCount = 0
        var restTotalCount = 0

        totalWatchedMinutes = 0

        for anime in library {
            switch anime.type {
            case "TV":
                tvTotalCount += 1
            case "Movie":
                moviesTotalCount += 1
            default:
                restTotalCount += 1
            }

            // Calculate watched minutes
            totalWatchedMinutes += (anime.duration * anime.publicProgress!.watchedEpisodes)
        }

        self.totalSubtitle = "\(tvTotalCount) TV · \(moviesTotalCount) Movie · \(restTotalCount) OVA/ONA/Specials"
    }

    var animeCellSize: CGSize!

    // MARK: - Utility Functions
    func updateLayout(withSize viewSize: CGSize) {
        
        guard let collectionView = collectionView,
            let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
                return
        }
        
        animeCellSize = AnimeCell.updateLayoutItemSizeWithLayout(layout, viewSize: viewSize)
        
        canFadeImages = false
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
        canFadeImages = true
    }

    // MARK: - IBActions
    
    @IBAction func dismissViewControllerPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension PublicListViewController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {

        return filteredDataSource.count + 1
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        if section == 0 {
            return 1
        } else {
            return filteredDataSource[section-1].count + 1
        }

    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("LibraryStatisticsCell", forIndexPath: indexPath) as! LibraryStatisticsCell
            let days = totalWatchedMinutes / (60*24)
            let hours = (totalWatchedMinutes - (days*60*24)) / 60
            let minutes = totalWatchedMinutes - (days*60*24) - (hours*60)
            cell.watchedTimeLabel.text = "I've watched \(days) days, \(hours) hours and \(minutes) minutes of anime."
            cell.subtitleLabel.text = totalSubtitle
            return cell
        }

        switch indexPath.row {
        case 0:
            // Title
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("LibrarySectionCell", forIndexPath: indexPath) as! LibrarySectionCell

            cell.titleLabel.text = sectionTitles[indexPath.section - 1]
            cell.subtitleLabel.text = sectionSubtitles[indexPath.section - 1]

            return cell
        default:
            //
            let cell = collectionView.dequeueReusableCellWithClass(AnimeCell.self, indexPath: indexPath)
            let anime = filteredDataSource[indexPath.section - 1][indexPath.row - 1]
            cell.configureWithAnime(anime, canFadeImages: canFadeImages, showEtaAsAired: false, publicAnime: true)
            cell.layoutIfNeeded()
            return cell
        }

    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        let height = (section == 0) ? FirstHeaderCellHeight : 0
        return CGSize(width: view.bounds.size.width, height: height)
    }
}

extension PublicListViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        view.endEditing(true)
        let section = indexPath.section - 1
        let row = indexPath.row - 1
        if section < 0 || row < 0 {
            return
        }
        let anime = filteredDataSource[section][row]
        animator = presentAnimeModal(anime)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: view.bounds.width, height: 68)
        } else {
            switch indexPath.row {
            case 0:
                return CGSize(width: view.bounds.width, height: 76)
            default:
                return animeCellSize
            }
        }

    }
}


extension PublicListViewController: UISearchBarDelegate {
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchBar.text == "" {
            filteredDataSource = dataSource
            return
        }

        updateFilteredDataSource()
    }

    func updateFilteredDataSource() {
        filteredDataSource = dataSource.map { ( animeTypeArray) -> [Anime] in
            return animeTypeArray.filter{
                ($0.title!.rangeOfString(searchBar.text!) != nil) ||
                ($0.genres.joinWithSeparator(" ").rangeOfString(searchBar.text!) != nil)
            }
        }
    }
}

extension PublicListViewController: ModalTransitionScrollable {
    var transitionScrollView: UIScrollView? {
        return collectionView
    }
}