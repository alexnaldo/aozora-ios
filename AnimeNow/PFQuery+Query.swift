//
//  PFQuery+Query.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 4/12/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

extension PFQuery {

    public func findAllObjectsInBackground(with skip: Int = 0) -> BFTask {

        limit = 1000
        self.skip = skip

        return findObjectsInBackground()
            .continueWithSuccessBlock { (task: BFTask!) -> BFTask! in

                guard let result = task.result as? [PFObject] else {
                    return BFTask(result: [])
                }

                // Parse has a limit of 10000 for maximum skip
                if result.count == self.limit && skip < 10000 {
                    return self.findAllObjectsInBackground(with: self.skip + self.limit)
                        .continueWithSuccessBlock({ (previousTask: BFTask!) -> AnyObject! in
                            guard let newResults = previousTask.result as? [PFObject] else {
                                return BFTask(result: result)
                            }
                            return BFTask(result: result+newResults)
                        })
                } else {
                    return task
                }
        }
    }
}