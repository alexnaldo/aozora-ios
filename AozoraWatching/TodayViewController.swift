//
//  TodayViewController.swift
//  AozoraWatching
//
//  Created by Paul Chavarria Podoliako on 1/30/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import UIKit
import NotificationCenter
import MMWormhole
import ANCommonKit

class TodayViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyMessage: UILabel!

    var dataSource: [AnimeData] = [] {
        didSet {
            var height: CGFloat = 0
            let dataSourceIsEmpty = dataSource.isEmpty
            if !dataSourceIsEmpty {
                height = CGFloat(dataSource.count * 55)
            } else {
                height = 44
            }

            preferredContentSize = CGSizeMake(view.bounds.width, height)

            tableView.hidden = dataSourceIsEmpty
            emptyMessage.hidden = !dataSourceIsEmpty

            tableView.reloadData()
        }
    }
    
    var wormhole: MMWormhole!
    var contentIsHidden = false

    override func viewDidLoad() {
        super.viewDidLoad()

        wormhole = instantiateWormhole()

        // Initializind dataSource and content size
        let data = wormhole.messageWatchingList() ?? []
        updateDataSource(data)

        // Listening for updates
        wormhole.listenForWatchingListUpdates { list in
            if let newDataSource = list as? [AnimeData] {
                self.updateDataSource(newDataSource)
            }
        }
    }

    func instantiateWormhole() -> MMWormhole {
        let appName = NSBundle.mainBundle().objectForInfoDictionaryKey("APP_NAME") as! String
        var groupIdentifier: String

        if AppEnvironment.Application(rawValue: appName)! == .Aozora {
            groupIdentifier = "group.anytap.Aozora"
        } else {
            groupIdentifier = "group.EverFox.AnimeTrakr.TodayExtension"
        }

        return MMWormhole(applicationGroupIdentifier: groupIdentifier, optionalDirectory: "wormwhole")
    }

    func updateDataSource(dataSource: [AnimeData]) {
        contentIsHidden = dataSource.count > 10
        self.dataSource = Array(dataSource.prefix(10))
        self.dataSource.sortInPlace({ $0.title < $1.title })
    }

    // MARK: - IBActions
    
    @IBAction func openApp(sender: AnyObject) {
        if let url = NSURL(string: "aozoraapp:///") {
            extensionContext?.openURL(url, completionHandler: nil)
        }
    }
}

extension TodayViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count + (contentIsHidden ? 1 : 0)
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCellWithIdentifier("TodayCell") as? TodayCell else {
            return UITableViewCell()
        }

        // View all case
        if indexPath.row == dataSource.count {
            cell.animeTitleLabel.text = ""
            cell.episodeNumberLabel.text = "View all watching list"
            cell.badgeImageView.image = nil
            cell.badgeLabel.text = ""
            return cell
        }

        let animeData = dataSource[indexPath.row]
        cell.animeTitleLabel.text = animeData.title
        cell.episodeNumberLabel.text = "Next to watch: Ep \(animeData.currentEpisode + 1)"

        let (etaString, status) = AiringController
            .airingStatusForFirstAired(
                animeData.firstAired,
                currentEpisode: animeData.currentEpisode,
                totalEpisodes: animeData.episodes,
                airingStatus: animeData.status)
        
        cell.badgeLabel.text = etaString
        switch status {
        case .Behind:
            cell.badgeImageView.image = UIImage(named: "badge-red")
        case .Future:
            cell.badgeImageView.image = UIImage(named: "badge-green")
        }

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        openApp(self)
    }
}

extension TodayViewController: NCWidgetProviding {
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })

        completionHandler(NCUpdateResult.NewData)
    }

    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        var edgeInsets = defaultMarginInsets
        edgeInsets.left = 0
        return edgeInsets
    }
}
