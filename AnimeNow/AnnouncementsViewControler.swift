//
//  AnnouncementsViewControler.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 5/7/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit
import XLPagerTabStrip

class AnnouncementsViewController: BaseThreadViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        threadType = .Threads

        loadingView = LoaderView(parentView: view)
        loadingView.startAnimating()

        fetchAnnouncements()
    }

    var threadTags: [ThreadTag] = []

    func fetchAnnouncements() {

        let threadTagsQuery = ThreadTag.query()!
        threadTagsQuery.whereKey("type", equalTo: "announcement")
        threadTagsQuery
            .findObjectsInBackground()
            .continueWithExecutor(BFExecutor.mainThreadExecutor(), withSuccessBlock:  { (task) -> AnyObject? in

                guard let tags = task.result as? [ThreadTag] else {
                    return nil
                }

                self.threadTags = tags

                return nil
            })
            .continueWithExecutor(BFExecutor.mainThreadExecutor(), withSuccessBlock:  { (task) -> AnyObject? in

                let query = Thread.query()!
                query.whereKey("tags", containedIn: self.threadTags)
                query.includeKey("tags")
                query.includeKey("anime")
                query.includeKey("episode")
                query.includeKey("startedBy")
                query.includeKey("postedBy")
                query.includeKey("lastPostedBy")
                query.orderByDescending("createdAt")
                self.fetchController.configureWith(self, query: query, tableView: self.tableView, limit: 100)
                return nil
            })
    }
}

// MARK: - IndicatorInfoProvider
extension AnnouncementsViewController: IndicatorInfoProvider {

    func indicatorInfoForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Announcements")
    }
}

