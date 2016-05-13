//
//  Analytics.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 4/22/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation
import Flurry_iOS_SDK

class Analytics {

    // MARK: - Session

    class func setSessionDataforUser(currentUser: User) {
        Flurry.setUserID(currentUser.objectId!)
        let days = NSCalendar.currentCalendar().components([.Day], fromDate: currentUser.joinDate, toDate: NSDate(), options: []).day
        let months = NSCalendar.currentCalendar().components([.Month], fromDate: currentUser.joinDate, toDate: NSDate(), options: []).month
        let usingMAL = currentUser.myAnimeListUsername != nil ? "Yes" : "No"
        let trialExpired = NSDate().compare(currentUser.trialExpiration ?? NSDate()) == NSComparisonResult.OrderedAscending ? "No" : "Yes"

        Flurry.sessionProperties([
            "usingDays": String(days),
            "usingMonths": String(months),
            "usingMAL": usingMAL,
            "trialExpired": trialExpired,
        ])
    }

    // MARK: - RootTab

    class func viewedRootTabTab(number number: Int) {

        var tabName: String
        switch number {
        case 0: tabName = "Home"
        case 1: tabName = "Library"
        case 2: tabName = "Profile"
        case 3: tabName = "Notifications"
        case 4: tabName = "Forums"
        default: tabName = "Unknown"
        }

        let eventID = "View.RootTab.Tab"
        let parameters: [NSObject: AnyObject] = [
            "Tab": tabName
        ]

        Flurry.logEvent(eventID, withParameters: parameters)
    }

    // MARK: - Home

    class func viewedHome() {
        let eventID = "View.Home"
        let parameters: [NSObject: AnyObject] = [
            "Tab": 1
        ]
        Flurry.logEvent(eventID, withParameters: parameters)
    }

    class func viewedHomeCalendar() {
        let eventID = "View.Home.Calendar"
        Flurry.logEvent(eventID, withParameters: nil)
    }

    class func viewedHomeSeasons() {
        let eventID = "View.Home.Seasons"
        Flurry.logEvent(eventID, withParameters: nil)
    }

    class func viewedHomeTopLists() {
        let eventID = "View.Home.TopLists"
        Flurry.logEvent(eventID, withParameters: nil)
    }

    class func viewedHomeGenres() {
        let eventID = "View.Home.Genres"
        Flurry.logEvent(eventID, withParameters: nil)
    }

    class func viewedHomeYears() {
        let eventID = "View.Home.Years"
        Flurry.logEvent(eventID, withParameters: nil)
    }

    class func viewedHomeStudios() {
        let eventID = "View.Home.Studios"
        Flurry.logEvent(eventID, withParameters: nil)
    }

    class func viewedHomeClassifications() {
        let eventID = "View.Home.Classifications"
        Flurry.logEvent(eventID, withParameters: nil)
    }

    class func viewedHomeAdvancedFilter() {
        let eventID = "View.Home.AdvancedFilter"
        Flurry.logEvent(eventID, withParameters: nil)
    }

    // MARK: - Library

    class func viewedLibrary(list: String, layout: String, sort: String) {
        let eventID = "View.Library.List"
        let parameters: [NSObject: AnyObject] = [
            "list": list,
            "layout": layout,
            "sort": sort
        ]
        Flurry.logEvent(eventID, withParameters: parameters)
    }

    class func tappedLibraryFilter() {
        let eventID = "Tap.Library.Filter"
        Flurry.logEvent(eventID, withParameters: nil)
    }

    class func tappedLibrarySearch() {
        let eventID = "Tap.Library.Search"
        Flurry.logEvent(eventID, withParameters: nil)
    }

    class func tappedLibraryAnimeEpisodeComment(animeID: String, list: String, row: Int) {
        let eventID = "Tap.Library.Anime.EpisodeComment"
        let parameters: [NSObject: AnyObject] = [
            "animeID": animeID,
            "list": list,
            "row": row
        ]
        Flurry.logEvent(eventID, withParameters: parameters)
    }

    class func tappedLibraryAnimeEpisodeWatched(animeID: String, list: String, row: Int) {
        let eventID = "Tap.Library.Anime.EpisodeWatched"
        let parameters: [NSObject: AnyObject] = [
            "animeID": animeID,
            "list": list,
            "row": row
        ]
        Flurry.logEvent(eventID, withParameters: parameters)
    }


    // MARK: - AnimeDetails

    class func viewedAnimeDetail(title title: String, id: String, list: String) {
        let eventID = "View.AnimeDetail"
        let parameters: [NSObject: AnyObject] = [
            "title": title,
            "id": id,
            "list": list
        ]
        Flurry.logEvent(eventID, withParameters: parameters)
    }

    class func tappedAnimeDetailChangeList(list: String, saved: Bool) {
        let eventID = "Tap.AnimeDetail.ChangeList"
        let parameters: [NSObject: AnyObject] = [
            "list": list,
            "saved": saved ? "Yes" : "No"
        ]
        Flurry.logEvent(eventID, withParameters: parameters)
    }
}


