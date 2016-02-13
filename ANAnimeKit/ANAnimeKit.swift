//
//  ANAnimeKit.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/9/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

public class ANAnimeKit {
    
    public class func shortClassification(classification: String) -> String {

        switch classification {
        case "None":
            return "?"
        case "G - All Ages":
            return "G"
        case "PG-13 - Teens 13 or older":
            return "PG-13"
        case "R - 17+ (violence & profanity)":
            return "R17+"
        case "Rx - Hentai":
            return "Rx"
        default:
            return "?"
        }

    }
}