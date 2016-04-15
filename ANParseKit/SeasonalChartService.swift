//
//  SeasonalChartWorker.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 5/23/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation

public enum SeasonalChartType: String {
    case Winter
    case Summer
    case Spring
    case Fall
}

public class SeasonalChartService {

    public class func seasonalChartString(seasonsAhead: Int) -> (iconName: String, title: String) {

        let calendar = NSCalendar.currentCalendar()
        
        let seasonDate = calendar.dateByAddingUnit(NSCalendarUnit.Month, value: seasonsAhead * 3, toDate: NSDate(), options: [])
        
        let components = calendar.components([NSCalendarUnit.Month, NSCalendarUnit.Year], fromDate: seasonDate!)
        var seasonString = ""
        
        var monthNumber = components.month + 1
        let yearNumber = components.year
        if monthNumber > 12 {
            monthNumber -= 12
        }
        
        switch monthNumber {
        case 2...4 : seasonString = "Winter"
        case 5...7 : seasonString = "Spring"
        case 8...10 : seasonString = "Summer"
        case 1 : fallthrough
        case 11...12 : seasonString = "Fall"
        default: break
        }
        
        var iconName = ""
        
        switch SeasonalChartType(rawValue: seasonString)! {
        case .Winter: iconName = "icon-winter"
        case .Spring: iconName = "icon-spring"
        case .Summer: iconName = "icon-summer"
        case .Fall: iconName = "icon-fall"
        }
        
        return (iconName , seasonString + " \(yearNumber)")
    }
}
