//
//  AnimeBrowserViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 2/9/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import UIKit

import ANCommonKit

typealias BrowseData = (title: String, subtitle: String?, detailTitle: String, anime: [Anime], query: PFQuery?, fetching: Bool)

class AnimeBrowserViewController: UIViewController {

    enum HeaderHeight: CGFloat {
        case Short = 30
        case Regular = 40
    }

    @IBOutlet weak var tableView: UITableView!

    var animator: ZFModalTransitionAnimator!
    var dataSource: [BrowseData] = []
    var controllerTitle: String!
    var headerHeight: HeaderHeight!

    func initWithBrowseData(dataSource: [BrowseData], controllerTitle: String, headerHeight: HeaderHeight) {
        self.dataSource = dataSource
        self.controllerTitle = controllerTitle
        self.headerHeight = headerHeight
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = controllerTitle

        tableView.registerNibWithClass(TitleHeaderView)
        tableView.registerNibWithClass(TableCellWithCollection)
    }

    func fetchForSection(section: Int) {
        let data = dataSource[section]

        if data.fetching {
            return
        }

        dataSource[section].fetching = true

        let query = data.query
        query?.findObjectsInBackgroundWithBlock { (result, error) in
            if let _ = error {

            } else if let anime = result as? [Anime] {
                self.dataSource[section].anime = anime
                self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 1, inSection: section)], withRowAnimation: .None)
            }
        }
    }

    func seeAllPressedForSection(section: Int) {

        let browseData = dataSource[section]

        let chartViewController = UIStoryboard(name: "Season", bundle: nil).instantiateViewControllerWithIdentifier("ChartViewController") as! ChartViewController

        let title = browseData.title
        if let query = browseData.query {
            chartViewController.initWithQuery(title, query: query)
        } else {
            chartViewController.initWithDataSource(title, dataSource: browseData.anime)
        }

        navigationController?.pushViewController(chartViewController, animated: true)
    }

    @IBAction func searchPressed(sender: AnyObject) {
        if let tabBar = tabBarController {
            tabBar.presentSearchViewController(.Forum)
        }
    }
}

extension AnimeBrowserViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        switch indexPath.row {
        case 0:
            guard let cell = tableView.dequeueReusableCellWithIdentifier("TitleHeaderView") as? TitleHeaderView else {
                return UITableViewCell()
            }
            let sectionData = dataSource[indexPath.section]

            cell.titleLabel.text = sectionData.title
            cell.subtitleLabel.text = sectionData.subtitle
            cell.section = indexPath.section

            cell.actionButton.setTitle(sectionData.detailTitle, forState: .Normal)

            cell.actionButtonCallback = { section in
                self.seeAllPressedForSection(section)
            }
            
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCellWithIdentifier("TableCellWithCollection") as? TableCellWithCollection else {
                return UITableViewCell()
            }

            cell.dataSource = dataSource[indexPath.section].anime

            cell.selectedAnimeCallBack = { anime in
                self.animator = self.presentAnimeModal(anime)
            }

            cell.collectionView.contentOffset = CGPoint.zero
            cell.collectionView.reloadData()
            
            return cell
        default:
            break
        }

        return UITableViewCell()
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        let data = dataSource[indexPath.section]

        if data.fetching {
            return
        }

        print("fetching section \(indexPath.section)")
        fetchForSection(indexPath.section)
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return headerHeight.rawValue
        case 1:
            return 167
        default:
            return CGFloat.min
        }
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.min
    }

}
