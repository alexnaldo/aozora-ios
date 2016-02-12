//
//  DataRefresherController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 2/9/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation


// TODO: Currently not used
class DataRefresherController: NSObject {

    typealias RefreshCallback = () -> Bool

    enum RefreshTimeInterval: NSTimeInterval {
        case LowTraffic = 1920.0
        case MediumTraffic = 480.0
        case HighTraffic = 120.0
    }

    var refreshCallback: RefreshCallback!
    var refreshTimeInterval: RefreshTimeInterval!
    var timer: NSTimer!
    var lastUpdated: NSDate!

    init(timeInterval: RefreshTimeInterval, refreshControl: UIRefreshControl? = nil, refreshCallback callback: RefreshCallback) {

        refreshCallback = callback
        refreshTimeInterval = timeInterval
        lastUpdated = NSDate()

        super.init()

        refreshControl?.addTarget(self, action: "refreshData", forControlEvents: .ValueChanged)

        timer = scheduleTimerWithTimeInterval(refreshTimeInterval)

        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didEnterBackground", name:
            UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:
            UIApplicationDidBecomeActiveNotification, object: nil)
    }

    deinit {

        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func scheduleTimerWithTimeInterval(timeInterval: RefreshTimeInterval) -> NSTimer {
        return NSTimer.scheduledTimerWithTimeInterval(
            timeInterval.rawValue,
            target: self,
            selector: "refreshData",
            userInfo: nil,
            repeats: true)
    }

    func didEnterBackground() {
        timer?.invalidate()
        timer = nil
    }

    func didBecomeActive() {
        timer = scheduleTimerWithTimeInterval(refreshTimeInterval)
        if NSDate().timeIntervalSinceDate(lastUpdated) > refreshTimeInterval.rawValue {
            refreshData()
        }
    }

    func refreshData() {
        if let refreshCallback = refreshCallback where refreshCallback() {
            lastUpdated = NSDate()
        }
    }

}