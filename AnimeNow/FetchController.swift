//
//  DataFetchController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/27/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation

public protocol FetchControllerDelegate: class {
    func didFetchFor(skip skip: Int)
}

public protocol FetchControllerQueryDelegate: class {
    func resultsForSkip(skip skip: Int) -> BFTask? // [PFObject]
    func processResult(result result: [PFObject], dataSource: [PFObject]) -> [PFObject]
}

public class FetchController {

    public weak var delegate: FetchControllerDelegate?
    public weak var queryDelegate: FetchControllerQueryDelegate?
    
    var isFetching = true
    var canFetchMore = true
    var dataSourceCount = 0
    var page = 0
    var limit = 100
    
    var defaultIsFetching = true
    var defaultCanFetchMore = true
    var defaultDataSourceCount = 0
    var defaultPage = 0
    var defaultLimit = 100

    public var tableView: UITableView?
    public var collectionView: UICollectionView?
    public var dataSource: [PFObject] = []
    var query: PFQuery?
    
    var isFirstFetch = true
    var datasourceUsesSections = false
    var pinnedData: [PFObject] = []
    
    public init() {
        
    }
    
    public func configureWith(
        delegate: FetchControllerDelegate,
        query: PFQuery? = nil,
        queryDelegate: FetchControllerQueryDelegate? = nil,
        collectionView: UICollectionView? = nil,
        tableView: UITableView? = nil,
        limit: Int = 100,
        datasourceUsesSections: Bool = false,
        pinnedData: [PFObject] = []) {
        
            self.queryDelegate = queryDelegate
            self.delegate = delegate
            self.tableView = tableView
            self.collectionView = collectionView
            query?.limit = limit
            self.query = query
            self.datasourceUsesSections = datasourceUsesSections
            self.pinnedData = pinnedData
            defaultLimit = limit
            resetToDefaults()
            if let tableView = tableView {
                tableView.reloadData()
            }
            fetchWith(skip: 0)
    }
    
    public func resetToDefaults() {
        dataSource = []
        isFetching = defaultIsFetching
        canFetchMore = defaultCanFetchMore
        dataSourceCount = defaultDataSourceCount
        page = defaultPage
        limit = defaultLimit
        query?.skip = 0
    }
    
    public func dataCount() -> Int {
        return dataSource.count
    }
    
    public func objectAtIndex(index: Int, viewed: Bool = true) -> PFObject {
        if viewed {
            didDisplayItemAt(index: index)
        }
        return dataSource[index]
    }
    
    public func objectInSection(section: Int) -> PFObject {
        return dataSource[section]
    }
    
    public func didDisplayItemAt(index index: Int) {
        
        if isFetching || !canFetchMore {
            return
        }
        
        if Float(index) > Float(dataSourceCount) - Float(limit) * 0.2 {
            isFetching = true
            page += 1
            print("Fetching page \(page)")
            fetchWith(skip: page*limit)
        }
    }
    
    public func didFetch(newDataSourceCount: Int) {
        
        if !isFetching && newDataSourceCount == limit {
            resetToDefaults()
        }
        
        if isFetching {
            
            isFetching = false
            canFetchMore = newDataSourceCount < dataSourceCount + limit ? false : true
            dataSourceCount = newDataSourceCount
            
            print("Fetched page \(page)")
        }
    }
    
    public var canFetchMoreData: Bool {
        get {
            return canFetchMore
        }
    }
    
    func fetchWith(skip skip: Int) -> BFTask {

        var allData:[PFObject] = []

        var task: BFTask!

        if let resultsTask = queryDelegate?.resultsForSkip(skip: skip) {
            task = resultsTask
        } else if let query = query {
            query.skip = skip
            task = query.findObjectsInBackground()
        } else {
            return BFTask(result: nil)
        }
        
        return task.continueWithSuccessBlock({ (task: BFTask!) -> AnyObject! in

            let posts = task.result as! [PFObject]
            allData += posts
            return nil

        }).continueWithExecutor(BFExecutor.mainThreadExecutor(), withSuccessBlock: { (task: BFTask!) -> AnyObject! in
            
            if let processedResult = self.queryDelegate?.processResult(result: allData, dataSource: self.dataSource) {
                allData = processedResult
            }
            
            if skip == 0 {
                self.dataSource = self.pinnedData + allData
            } else {
                self.dataSource += allData
            }

            // Should be called before reloading tableview
            self.didFetch(self.dataSource.count)

            if let collectionView = self.collectionView {
                if skip == 0 {
                    // Reload data
                    collectionView.reloadData()
                    if self.isFirstFetch || collectionView.alpha == 0 {
                        self.isFirstFetch = false
                        collectionView.animateFadeIn()
                    }
                } else {
                    // Insert rows
                    // Implement a better way of adding new rows
                    collectionView.reloadData()
                }
            } else if let tableView = self.tableView {
                if skip == 0 {
                    tableView.reloadData()
                    tableView.updateTableViewCellsHeight()
                    if self.isFirstFetch {
                        self.isFirstFetch = false
                        tableView.animateFadeIn()
                    }
                } else {
                    tableView.reloadData()
                }
            }

            // Should be called after reloading tableview
            self.delegate?.didFetchFor(skip: skip)
            
            return nil
        }).continueWithBlock({ (task: BFTask!) -> AnyObject! in
            if let exception = task.exception {
                print(exception)
            }
            return nil
        })
    }
}
