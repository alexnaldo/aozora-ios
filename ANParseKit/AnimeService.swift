//
//  AnimeService.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 5/23/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANCommonKit

public class AnimeService {

    /// Finds all dangling pointers for anime
    func findLibraryDanglingPointers(date: NSDate = NSDate()) {
        print("Fetching earlier than: \(date)")
        let query = AnimeProgress.query()!
        query.orderByDescending("createdAt")
        query.selectKeys(["anime"])
        query.includeKey("anime")
        query.whereKey("createdAt", lessThan: date)
        query.limit = 10000
        query.findObjectsInBackground().continueWithBlock { (task) -> AnyObject? in
            guard let result = task.result as? [AnimeProgress] else {
                return nil
            }

            var progressToDelete: [AnimeProgress] = []
            for progress in result {
                if progress.anime.objectId == nil {
                    print("\(progress.objectId): \(progress.anime.objectId)")
                    progressToDelete.append(progress)
                }
            }

            print("Deleting \(progressToDelete.count)")
            PFObject.deleteAllInBackground(progressToDelete).continueWithBlock({ (task) -> AnyObject? in
                print(task.error)
                if result.count == 11000 {
                    self.findLibraryDanglingPointers(result.last!.createdAt!)
                }
                return nil
            })

            return nil
        }
    }


    /// Finds MAL imported duplicates.
    func findDuplicates() {
        let query = Anime.query()!
        query.selectKeys(["myAnimeListID", "characters" ,"cast", "relations", "details"])
        query.addAscendingOrder("createdAt")
        query.limit = 10000
        query.findObjectsInBackground().continueWithSuccessBlock({ (task: BFTask!) -> AnyObject! in
            let allanime = task.result as! [Anime]

            print("Got \(allanime.count)")

            var dict: [Int:[Anime]] = [:]

            for anime in allanime {

                if dict[anime.myAnimeListID] != nil {
                    dict[anime.myAnimeListID]!.append(anime)
                } else {
                    dict[anime.myAnimeListID] = [anime]
                }
            }

            var duplicatedIDs: [Anime] = []
            for (anime, value) in dict {
                if value.count > 1 {
                    print("MAL:\(anime) \(value.count)")
                    duplicatedIDs.append(value.first!)
                }
            }

            //self.safelyRemoveDuplicates(duplicatedIDs)

            return nil
        }).continueWithBlock { (task) -> AnyObject? in
            print(task.exception)
            print(task.error)
            return nil
        }
    }

    /// Removes all anime that is duplicated
    /// duplicatedAnime: ONLY the duplicated anime objects
    func removeDuplicates(duplicatedAnime: [Anime]) {

        // Delete animeProgress
        let query = AnimeProgress.query()!
        query.whereKey("anime", containedIn: duplicatedAnime)
        query.limit = 10000
        query.findObjectsInBackground().continueWithSuccessBlock({ (task: BFTask!) -> AnyObject! in

            let animeProgress = task.result as! [AnimeProgress]

            PFObject.deleteAllInBackground(animeProgress).continueWithBlock({ (task) -> AnyObject? in
                print(task.result)
                print(task.exception)
                print(task.error)
                let query = Episode.query()!
                query.whereKey("anime", containedIn: duplicatedAnime)
                query.limit = 11000
                query.findObjectsInBackground().continueWithSuccessBlock({ (task: BFTask!) -> AnyObject! in

                    let animeProgress = task.result as! [Episode]

                    PFObject.deleteAllInBackground(animeProgress).continueWithBlock({ (task) -> AnyObject? in
                        print(task.result)
                        print(task.exception)
                        print(task.error)
                        var toDelete: [PFObject] = []
                        var animeToDelete: [PFObject] = []
                        for anime in duplicatedAnime {
                            toDelete.appendContentsOf([anime.characters, anime.cast, anime.relations, anime.details])
                            animeToDelete.append(anime)

                        }

                        PFObject.deleteAllInBackground(toDelete).continueWithBlock({ (task) -> AnyObject? in
                            print(task.result)
                            print(task.exception)
                            print(task.error)
                            PFObject.deleteAllInBackground(animeToDelete).continueWithBlock({ (task) -> AnyObject? in
                                print(task.result)
                                print(task.exception)
                                print(task.error)
                                return nil
                            })
                            return nil
                        })
                        return nil
                    })
                    
                    return nil
                })
                return nil
            })

            return nil
        }).continueWithBlock { (task) -> AnyObject? in
            print(task.exception)
            print(task.error)
            return nil
        }
  }


}