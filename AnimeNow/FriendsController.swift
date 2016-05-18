//
//  FriendsController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 4/28/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

class FriendsController {
    static let sharedInstance = FriendsController()

    var following: [User]?

    func fetchFollowing() {
        guard let userProfile = User.currentUser() else {
            return
        }

        following = []

        let query = userProfile.following().query()
        query.whereKey("following", equalTo: userProfile)
        query.selectKeys(["objectId", "aozoraUsername"])
        query.limit = 10000
        query.findObjectsInBackgroundWithBlock { (users, error) in
            if let users = users as? [User] {
                self.following = users
            } else {
                self.following = nil
            }
        }
    }
}