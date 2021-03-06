//
//  QueryBuilder.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 4/9/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

private class QueryBuilder {
    typealias Dependency = (query: PFQuery, key: String)

    var query: PFQuery
    var dependencies: [Dependency] = []

    init(query: PFQuery) {
        self.query = query
    }

    func addDependency(query: PFQuery, matchingKey: String) {
        let dependency: Dependency = (query: query, key: matchingKey)
        dependencies.append(dependency)
    }
}

class QueryBatch {

    private var queryBuilds: [QueryBuilder] = []

    private func addQuery(query: PFQuery) -> QueryBuilder {
        var queryBuilder: QueryBuilder!
        for builder in queryBuilds {
            if builder.query == query {
                queryBuilder = builder
            }
        }
        if queryBuilder == nil {
            queryBuilder = QueryBuilder(query: query)
            queryBuilds.append(queryBuilder)
        }

        return queryBuilder
    }

    func whereQuery(query1: PFQuery, matchesKey key: String, onQuery query2: PFQuery) {
        let queryBuilder = addQuery(query1)
        let _ = addQuery(query2)

        queryBuilder.addDependency(query2, matchingKey: key)
    }

    // The idea is that this function executes the queries asynchronously and returns a BFTask of all the results, it also should handle the case that one query depends on other and execute it only once

    var task: BFTask!
    var result: [PFQuery: [PFObject]] = [:]
    private var leftQueries: [QueryBuilder] = []

    func executeQueries(queries: [PFQuery], fetchedObjects: [PFObject] = []) -> BFTask {

        for query in queries {
            addQuery(query)
        }

        task = BFTask(result: nil)
        result = [:]
        leftQueries = queryBuilds

        return enqueueQueries().continueWithSuccessBlock({ task -> AnyObject? in
            let result = queries.flatMap{ query -> [PFObject] in
                return self.result[query] ?? []
            }
            return BFTask(result: result + fetchedObjects)
        })
    }

    private func enqueueQueries() -> BFTask! {

        guard let builder = findBuilderWithNoDependencies() else {
            return BFTask(result: nil)
        }

        return task.continueWithSuccessBlock({ result -> AnyObject? in
            return builder.query.findObjectsInBackground()
        }).continueWithSuccessBlock({ objects -> AnyObject? in
            let result = objects.result as! [PFObject]
            self.result[builder.query] = result
            if !self.leftQueries.isEmpty {
                return self.enqueueQueries()
            } else {
                return BFTask(result: nil)
            }
        })
    }

    private func findBuilderWithNoDependencies() -> QueryBuilder? {
        for (idx, builder) in leftQueries.enumerate() {
            var allQueriesExecuted = true

            for (query, key) in builder.dependencies {
                if let result = result[query] {
                    builder.query.whereKey(key, containedIn: result)
                } else {
                    allQueriesExecuted = false
                    continue
                }
            }

            // All dependencies executed, perform this query
            if allQueriesExecuted {
                leftQueries.removeAtIndex(idx)
                return builder
            }
        }
        return nil
    }
}