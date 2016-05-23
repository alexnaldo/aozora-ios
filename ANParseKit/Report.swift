//
//  Report.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 5/23/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

public class Report: PFObject, PFSubclassing {

    override public class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }

    public class func parseClassName() -> String {
        return "Report"
    }

    @NSManaged public var reportedClass: String
    @NSManaged public var reportedObjectId: String
    @NSManaged public var reportedBy: [User]
    @NSManaged public var reportCount: Int

    class func reportObjectID(objectID: String?, className: String, reportedBy: User) {

        guard let objectID = objectID else {
            return
        }

        let query = Report.query()!
        query.whereKey("reportedObjectId", equalTo: objectID)
        query.whereKey("reportedClass", equalTo: className)
        query.findObjectsInBackgroundWithBlock { (result, error) in
            if error != nil {
                return
            }

            var report: Report!

            if let lastReport = result?.last as? Report {
                report = lastReport
            } else {
                report = Report()
                report.reportedClass = className
                report.reportedObjectId = objectID
            }

            report.addUniqueObject(reportedBy, forKey: "reportedBy")
            report.incrementKey("reportCount")
            report.saveInBackground()

            reportedBy.details.incrementKey("reportCount")
            reportedBy.saveInBackground()
        }
    }

}
