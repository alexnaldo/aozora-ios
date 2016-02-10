//
//  AnimeBrowserViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 2/9/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import UIKit
import ANParseKit
import ANCommonKit

typealias BrowseData = (title: String, subtitle: String?, detailTitle: String, anime: [Anime], query: PFQuery?, fetching: Bool)

class AnimeBrowserViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var animator: ZFModalTransitionAnimator!
    var dataSource: [BrowseData] = []
    var controllerTitle: String!

    func initWithBrowseData(dataSource: [BrowseData], title: String) {
        self.dataSource = dataSource
        controllerTitle = title
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = controllerTitle
//        dataSource = [
//            (title: "Spring 2015", subtitle: "Mar 2015 - May 2015", detailTitle: "See all", anime: [], query: nil, fetching: false)
//        ]

        TitleHeaderView.registerNibFor(tableView: tableView)
        TableCellWithCollection.registerNibFor(tableView: tableView)
        
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
        UIAlertView(title: "TODO", message: "Not implemented", delegate: nil, cancelButtonTitle: "Ok").show()
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
            return 40
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
