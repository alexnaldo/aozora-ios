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
    
    var dataSource: [[Anime]] = [[],[],[],[],[]] {
        didSet {
            filteredDataSource = dataSource
        }
    }
    
    var filteredDataSource: [[Anime]] = [] {
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
    var sectionTitles: [String] = ["Watching", "Planning", "Completed", "On-Hold", "Dropped"]
    var sectionSubtitles: [String] = ["","","","","",""]
    var totalSubtitle: String = ""
    var totalWatchedMinutes: Int = 0
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var navigationBarTitle: UILabel!
    @IBOutlet weak var filterBar: UIView!
    
    func initWithUser(user: User) {
        userProfile = user
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.registerNibWithClass(AnimeCell)
        
        collectionView.alpha = 0.0
        
        loadingView = LoaderView(parentView: view)
        loadingView.startAnimating()
        
        title = "\(userProfile.aozoraUsername) Library"
        
        fetchUserLibrary()
        updateLayout(withSize: view.bounds.size)
    }
    
    deinit {
        for typeList in dataSource {
            for anime in typeList {
                anime.publicProgress = nil
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if loadingView.animating == false {
            loadingView.stopAnimating()
            collectionView.animateFadeIn()
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        updateLayout(withSize: size)
        
    }
    
    func fetchUserLibrary() {
        
        let query = AnimeProgress.query()!
        query.includeKey("anime")
        query.whereKey("user", equalTo: userProfile)
        query.limit = 2000
        query.findObjectsInBackground()
            .continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task: BFTask!) -> AnyObject! in

                defer {
                    self.loadingView.stopAnimating()
                    self.collectionView.animateFadeIn()
                }

                guard var result = task.result as? [AnimeProgress] else {
                    return nil
                }

                result.sortInPlace({ (progress1: AnimeProgress, progress2: AnimeProgress) -> Bool in
                    if progress1.anime.type == progress2.anime.type {
                        return progress1.anime.title! < progress2.anime.title
                    } else {
                        return progress1.anime.type > progress2.anime.type
                    }
                })
                

                self.totalWatchedMinutes = 0
                for animeProgress in result {
                    var list = 0
                    switch animeProgress.list {
                    case "Watching":
                        list = 0
                    case "Planning":
                        list = 1
                    case "Completed":
                        list = 2
                    case "On-Hold":
                        list = 3
                    case "Dropped":
                        list = 4
                    default:
                        break
                    }

                    let anime = animeProgress.anime
                    anime.publicProgress = animeProgress

                    self.dataSource[list].append(anime)

                    // Calculate watched minutes
                    self.totalWatchedMinutes += (anime.duration * animeProgress.watchedEpisodes)
                }
                
                var tvTotalCount = 0
                var moviesTotalCount = 0
                var restTotalCount = 0
                // Set stats
                for i in 0 ..< self.dataSource.count-1  {
                    let animeList = self.dataSource[i]
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
                    tvTotalCount += tvCount
                    moviesTotalCount += moviesCount
                    restTotalCount += restCount
                    self.sectionSubtitles[i] = "\(tvCount) TV · \(moviesCount) Movie · \(restCount) OVA/ONA/Specials"
                }

                self.totalSubtitle = "\(tvTotalCount) TV · \(moviesTotalCount) Movie · \(restTotalCount) OVA/ONA/Specials"

                return nil
        })
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
            return filteredDataSource[section-1].count
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

        let section = indexPath.section - 1

        switch (section, indexPath.row) {
        case (_,0):
            // Title
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("LibrarySectionCell", forIndexPath: indexPath) as! LibrarySectionCell

            cell.titleLabel.text = sectionTitles[section]
            cell.subtitleLabel.text = sectionSubtitles[section]

            return cell
        case (_,_):
            //
            let cell = collectionView.dequeueReusableCellWithClass(AnimeCell.self, indexPath: indexPath)

            let anime = filteredDataSource[section][indexPath.row]
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
        let anime = filteredDataSource[section][indexPath.row]
        animator = presentAnimeModal(anime)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: view.bounds.width, height: 68)
        } else {
            switch (indexPath.section - 1, indexPath.row) {
            case (_,0):
                return CGSize(width: view.bounds.width, height: 76)
            case (_,_):
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