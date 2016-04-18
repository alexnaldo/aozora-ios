//
//  RecommendationsViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 4/17/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import UIKit

class RecommendationsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var dataSource: [Int] = []
}

extension RecommendationsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        return UITableViewCell()
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    }
}
