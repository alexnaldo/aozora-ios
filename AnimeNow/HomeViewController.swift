//
//  HomeViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 1/30/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

import ANCommonKit

class HomeViewController: UIViewController {

    enum HomeSection: Int {
        case AiringToday, CurrentSeason, ExploreAll, Genres, Years, Studios, Classifications
    }

    @IBOutlet weak var headerViewController: UICollectionView?
    @IBOutlet weak var tableView: UITableView!

    var sections: [String] = ["Airing Today", "Current Season", "Explore all anime", "Explore by Genre", "Explore by Year", "Explore by Studio", "Explore by Classification"]
    var sectionDetails: [String] = ["", "", "", "", "", "", ""]
    var rightButtonTitle: [String] = ["Calendar", "Seasons", "Discover", "Genres", "Years", "Studios", "Classifications"]

    var airingDataSource: [[Anime]] = [[]] {
        didSet {
            tableView.reloadData()
        }
    }

    var currentSeasonalChartDataSource: [Anime] = [] {
        didSet {
            headerViewController?.reloadData()
            tableView.reloadData()
        }
    }

    var exploreAllAnimeDataSource: [Anime] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    var airingToday: [Anime] {
        return airingDataSource[0]
    }

    var currentSeasonalChartWithFanart: [Anime] = []

    var chartsDataSource: [SeasonalChart] = []

    var headerTimer: NSTimer!
    var animator: ZFModalTransitionAnimator!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerNibWithClass(TitleHeaderView.self)
        tableView.registerNibWithClass(TableCellWithCollection.self)

        fetchCurrentSeasonalChart()
        fetchAiringToday()
        fetchExploreAnime()

        sectionDetails[0] = getDayOfWeek()
        sectionDetails[1] = SeasonalChartService.seasonalChartString(0).title
        sectionDetails[2] = "Top anime lists"

        // Updating tableHeaderView depending on if it is iPad or iPhone
        var frame = tableView.tableHeaderView!.frame
        frame.size.height = UIDevice.isPad() ? 250 : 185
        tableView.tableHeaderView!.frame = frame

        updateHeaderViewControllerLayout(CGSize(width: view.bounds.width, height: frame.size.height))
    }

    func getDayOfWeek() -> String {
        let dateFormatter = NSDateFormatter()
        let todayDate = NSDate()
        let weekdayIndex = NSCalendar.currentCalendar().component(.Weekday, fromDate: todayDate) - 1

        return dateFormatter.weekdaySymbols[weekdayIndex]
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        canDisplayBannerAds = InAppController.canDisplayAds()
        
        headerTimer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: #selector(HomeViewController.moveHeaderView(_:)), userInfo: nil, repeats: true)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let timer = headerTimer {
            timer.invalidate()
        }
        headerTimer = nil
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {

        defer {
            super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        }

        if !UIDevice.isPad() {
            return
        }

        guard let headerViewController = headerViewController else {
            return
        }

        let nextIndexPath = headerCellIndexPath(next: false)
        let headerSize = CGSize(width: size.width, height: headerViewController.bounds.size.height)

        coordinator.animateAlongsideTransition({ (context) in

            self.updateHeaderViewControllerLayout(headerSize)
            headerViewController.reloadData()

        }) { (context) in
            if let nextIndexPath = nextIndexPath {
                let rect = CGRect(x: CGFloat(nextIndexPath.row) * headerSize.width, y: 0, width: headerSize.width, height: headerSize.height)
                headerViewController.scrollRectToVisible(rect, animated: false)
            }
        }
    }

    func updateHeaderViewControllerLayout(withSize: CGSize) {
        guard let layout = headerViewController?.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        layout.itemSize = withSize
    }

    func fetchCurrentSeasonalChart() {

        let seasonalChart = SeasonalChartService.seasonalChartString(0).title

        let startDate = NSDate()
        var seasonsTask: BFTask!

        if currentSeasonalChartDataSource.isEmpty {
            seasonsTask = ChartController.allSeasonsQuery().findObjectsInBackground().continueWithSuccessBlock { (task: BFTask!) -> AnyObject! in

                let result = task.result as! [SeasonalChart]
                self.chartsDataSource = result
                let selectedSeasonalChart = result.filter({$0.title == seasonalChart})
                return BFTask(result: selectedSeasonalChart)
            }
        } else {
            let selectedSeasonalChart = chartsDataSource.filter({$0.title == seasonalChart})
            seasonsTask = BFTask(result: selectedSeasonalChart)
        }

        seasonsTask.continueWithSuccessBlock { (task: BFTask!) -> AnyObject! in

            guard let result = task.result as? [SeasonalChart], let selectedSeason = result.last else {
                return nil
            }
            return ChartController.seasonalChartAnimeQuery(selectedSeason).findObjectsInBackground()

            }.continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task: BFTask!) -> AnyObject! in

                print("Load seasons = \(NSDate().timeIntervalSinceDate(startDate))s")
                if let result = task.result as? [Anime] {
                    // Seasonal Chart datasource
                    self.currentSeasonalChartDataSource = result
                        .filter({$0.type == "TV"})

                    // Top Banner DataSource
                    self.currentSeasonalChartWithFanart = self.currentSeasonalChartDataSource
                        .filter({ $0.fanart != nil })

                    // Shuffle the data
                    for _ in 0..<10 {
                        self.currentSeasonalChartWithFanart.sortInPlace { (_,_) in arc4random() < arc4random() }
                    }
                }

                return nil
            })
    }

    func fetchAiringToday() {

        let query = Anime.query()!
        query.whereKeyExists("startDateTime")
        query.whereKey("status", equalTo: "currently airing")
        query.orderByDescending("membersScore")
        query.findObjectsInBackgroundWithBlock({ (result, error) -> Void in

            if let result = result as? [Anime] {

                var animeByWeekday: [[Anime]] = [[],[],[],[],[],[],[]]

                let calendar = NSCalendar.currentCalendar()
                let unitFlags: NSCalendarUnit = .Weekday

                for anime in result {
                    let startDateTime = anime.nextEpisodeDate ?? NSDate()
                    let dateComponents = calendar.components(unitFlags, fromDate: startDateTime)
                    let weekday = dateComponents.weekday-1
                    animeByWeekday[weekday].append(anime)

                }

                var todayWeekday = calendar.components(unitFlags, fromDate: NSDate()).weekday - 1
                while (todayWeekday > 0) {
                    let currentFirstWeekdays = animeByWeekday[0]
                    animeByWeekday.removeAtIndex(0)
                    animeByWeekday.append(currentFirstWeekdays)
                    todayWeekday -= 1
                }

                self.airingDataSource = animeByWeekday
            }

        })

    }

    func fetchExploreAnime() {
        // Fetch
        let browseTypes: [BrowseType] = [.TopAnime, .TopUpcoming, .TopTVSeries, .TopMovies, .MostPopular]
        let selectedBrowseType = Int(arc4random() % 5)

        let query = BrowseViewController.queryForBrowseType(browseTypes[selectedBrowseType])

        query.findObjectsInBackgroundWithBlock { (result, error) in
            guard let animeList = result as? [Anime] else {
                return
            }

            self.exploreAllAnimeDataSource = animeList
        }
    }

    func moveHeaderView(timer: NSTimer) {
        if let nextIndexPath = headerCellIndexPath(next: true) {
            headerViewController?.scrollToItemAtIndexPath(nextIndexPath, atScrollPosition: .CenteredHorizontally, animated: true)
        }
    }

    func headerCellIndexPath(next next: Bool) -> NSIndexPath? {
        let lastIndex = currentSeasonalChartWithFanart.count - 1

        guard let visibleCellIdx = headerViewController?.indexPathsForVisibleItems().last where lastIndex > 0 else {
            return nil
        }

        if !next {
            return visibleCellIdx
        }

        let nextCellIndexPath: NSIndexPath!

        if visibleCellIdx.row == lastIndex {
            nextCellIndexPath = NSIndexPath(forRow: 0, inSection: 0)
        } else {
            nextCellIndexPath = NSIndexPath(forRow: visibleCellIdx.row + 1, inSection: 0)
        }
        return nextCellIndexPath
    }

    // MARK: - IBActions

    @IBAction func searchPressed(sender: AnyObject) {
        if let tabBar = tabBarController {
            tabBar.presentSearchViewController(.MyLibrary)
        }
    }
}

private extension HomeViewController {

    func instantiateAnimeBrowserViewController() -> AnimeBrowserViewController {
        let browserViewController = UIStoryboard(name: "Browser", bundle: nil).instantiateViewControllerWithIdentifier("AnimeBrowserViewController") as! AnimeBrowserViewController
        browserViewController.hidesBottomBarWhenPushed = true
        return browserViewController
    }

    func showCalendar() {

        if airingDataSource.count != 7 {
            return
        }

        let browserViewController = instantiateAnimeBrowserViewController()

        var dataSource: [BrowseData] = []

        // Set weekday strings
        let calendar = NSCalendar.currentCalendar()
        let today = NSDate()
        let weekDayFormat = NSDateFormatter()
        weekDayFormat.dateFormat = "eeee"

        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "MMMM dd"

        for daysAhead in 0..<7 {
            let date = calendar.dateByAddingUnit(NSCalendarUnit.Day, value: daysAhead, toDate: today, options: [])
            let weekdayString = weekDayFormat.stringFromDate(date!)
            let dateString = dateFormat.stringFromDate(date!)

            let data: BrowseData = (title: weekdayString, subtitle: dateString, detailTitle: "See All", anime: airingDataSource[daysAhead], query: nil, fetching: true)

            dataSource.append(data)
        }

        browserViewController.initWithBrowseData(dataSource, controllerTitle: "Calendar", headerHeight: .Regular)

        navigationController?.pushViewController(browserViewController, animated: true)
    }

    func showSeasonalCharts() {

        let browserViewController = instantiateAnimeBrowserViewController()

        var dataSource: [BrowseData] = []

        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "MMM yyyy"

        for seasonalChart in chartsDataSource {

            let query = ChartController.seasonalChartAnimeQuery(seasonalChart)

            let subtitle = "\(dateFormat.stringFromDate(seasonalChart.startDate)) - \(dateFormat.stringFromDate(seasonalChart.endDate))"
            let data: BrowseData = (title: seasonalChart.title, subtitle: subtitle, detailTitle: "See All", anime: [], query: query, fetching: false)

            dataSource.append(data)
        }

        browserViewController.initWithBrowseData(dataSource, controllerTitle: "Seasonal Charts", headerHeight: .Regular)

        navigationController?.pushViewController(browserViewController, animated: true)
    }

    func showBrowse() {

        let browserViewController = instantiateAnimeBrowserViewController()

        let allBrowseTypes = BrowseType.allItems()
        var dataSource: [BrowseData] = []


        for browseType in allBrowseTypes {

            let browseEnum = BrowseType(rawValue: browseType)!

            let query = BrowseViewController.queryForBrowseType(browseEnum)

            let data: BrowseData = (title: browseType, subtitle: nil, detailTitle: "See All", anime: [], query: query, fetching: false)

            dataSource.append(data)
        }

        browserViewController.initWithBrowseData(dataSource, controllerTitle: "Discover", headerHeight: .Short)

        navigationController?.pushViewController(browserViewController, animated: true)
    }

    func showGenres() {

        let browserViewController = instantiateAnimeBrowserViewController()

        let allGenres = AnimeGenre.allRawValues()
        var dataSource: [BrowseData] = []

        for genre in allGenres {
            let query = Anime.query()!
            query.whereKey("genres", containedIn: [genre])
            query.whereKey("type", equalTo: "TV")
            query.orderByDescending("membersCount")
            let data: BrowseData = (title: genre, subtitle: nil, detailTitle: "See All", anime: [], query: query, fetching: false)

            dataSource.append(data)
        }

        browserViewController.initWithBrowseData(dataSource, controllerTitle: "Explore by Genres", headerHeight: .Short)

        navigationController?.pushViewController(browserViewController, animated: true)
    }

    func showYears() {

        let browserViewController = instantiateAnimeBrowserViewController()

        var dataSource: [BrowseData] = []

        for year in allYears {

            let query = Anime.query()!
            query.whereKey("year", equalTo: Int(year)!)
            query.whereKey("type", equalTo: "TV")
            query.orderByDescending("membersCount")
            let data: BrowseData = (title: year, subtitle: nil, detailTitle: "See All", anime: [], query: query, fetching: false)

            dataSource.append(data)
        }

        browserViewController.initWithBrowseData(dataSource, controllerTitle: "Explore by Year", headerHeight: .Short)

        navigationController?.pushViewController(browserViewController, animated: true)

    }

    func showStudios() {

        let browserViewController = instantiateAnimeBrowserViewController()

        var dataSource: [BrowseData] = []
        let sortedStudios = allStudios.sort()
        for studio in sortedStudios {

            let query = Anime.query()!
            query.whereKey("producers", containedIn: [studio])
            query.orderByDescending("membersCount")
            let data: BrowseData = (title: studio, subtitle: nil, detailTitle: "See All", anime: [], query: query, fetching: false)

            dataSource.append(data)
        }

        browserViewController.initWithBrowseData(dataSource, controllerTitle: "Explore by Studios", headerHeight: .Short)

        navigationController?.pushViewController(browserViewController, animated: true)

    }

    func showClassifications() {

        let browserViewController = instantiateAnimeBrowserViewController()

        let allClassifications = AnimeClassification.allRawValues()
        var dataSource: [BrowseData] = []

        for classification in allClassifications {
            let innerQuery = AnimeDetail.query()!
            innerQuery.whereKey("classification", equalTo: classification)

            let query = Anime.query()!
            query.whereKey("details", matchesQuery: innerQuery)
            query.whereKey("type", equalTo: "TV")
            query.orderByDescending("membersCount")
            let data: BrowseData = (title: classification, subtitle: nil, detailTitle: "See All", anime: [], query: query, fetching: false)

            dataSource.append(data)
        }

        browserViewController.initWithBrowseData(dataSource, controllerTitle: "Explore by Classification", headerHeight: .Short)

        navigationController?.pushViewController(browserViewController, animated: true)
    }
}

// MARK: - TableViewDataSource, Delegate
extension HomeViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        switch (indexPath.section, indexPath.row) {
        case (_, 0):
            guard let cell = tableView.dequeueReusableCellWithIdentifier("TitleHeaderView") as? TitleHeaderView else {
                return UITableViewCell()
            }
            cell.titleLabel.text = sections[indexPath.section]
            cell.subtitleLabel.text = sectionDetails[indexPath.section]
            cell.section = indexPath.section

            cell.actionButton.setTitle(rightButtonTitle[indexPath.section], forState: .Normal)
            cell.actionButtonCallback = { section in

                func showInAppPurchasesIfNeeded(function: ()->Void) {
                    if InAppController.hasAnyPro() {
                        function()
                    } else {
                        InAppPurchaseViewController.showInAppPurchaseWith(self)
                    }
                }

                switch HomeSection(rawValue: section)! {
                case .AiringToday:
                    self.showCalendar()
                case .CurrentSeason:
                    self.showSeasonalCharts()
                case .ExploreAll:
                    self.showBrowse()
                case .Genres:
                    self.showGenres()
                case .Years:
                    self.showYears()
                    //showInAppPurchasesIfNeeded()
                case .Studios:
                    self.showStudios()
                    //showInAppPurchasesIfNeeded()
                case .Classifications:
                    self.showClassifications()
                    //showInAppPurchasesIfNeeded()
                }
            }
            
            return cell
        case (0...2, 1):

            guard let cell = tableView.dequeueReusableCellWithIdentifier("TableCellWithCollection") as? TableCellWithCollection else {
                return UITableViewCell()
            }

            switch HomeSection(rawValue: indexPath.section)! {
            case .AiringToday:
                cell.dataSource = airingToday
            case .CurrentSeason:
                cell.dataSource = currentSeasonalChartDataSource
            case .ExploreAll:
                cell.dataSource = exploreAllAnimeDataSource
            default:
                break
            }

            cell.selectedAnimeCallBack = { anime in
                self.animator = self.presentAnimeModal(anime)
            }
            
            cell.collectionView.reloadData()
            
            return cell
        default:
            return UITableViewCell()
        }
    }


    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.min
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        switch (indexPath.section, indexPath.row) {
        case (_, 0):
            return 40
        case (0...2, 1):
            return 167
        default:
            return CGFloat.min
        }
    }
}

// MARK: - HeaderViewController DataSource, Delegate

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentSeasonalChartWithFanart.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("BasicCollectionCell", forIndexPath: indexPath) as? BasicCollectionCell else {
            return UICollectionViewCell()
        }

        let anime = currentSeasonalChartWithFanart[indexPath.row]

        if let fanart = anime.fanart {
            cell.titleimageView.setImageFrom(urlString: fanart)
        }

        AnimeCell.updateInformationLabel(anime, informationLabel: cell.subtitleLabel)
        cell.titleLabel.text = anime.title ?? ""

        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let anime = currentSeasonalChartWithFanart[indexPath.row]
        animator = presentAnimeModal(anime)
    }
}