//
//  UserFriendsViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/22/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import Alamofire
import ANCommonKit

class UserListViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var loadingView: LoaderView!
    
    var dataSource: [User] = []
    var user: User?
    var query: PFQuery?
    var titleToSet = ""
    var animator: ZFModalTransitionAnimator!
    
    func initWithQuery(query: PFQuery, title: String, user: User? = nil) {
        self.user = user
        self.query = query
        titleToSet = title
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = titleToSet
        
        loadingView = LoaderView(parentView: view)

        if let query = query {
            fetchUserFriends(query)
        }

        guard let collectionView = collectionView,
            let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
                return
        }

        var width: CGFloat = 0
        if UIDevice.isPad() {
            width = 320 - 44
        } else {
            width = view.bounds.width - 44
        }

        layout.itemSize = CGSize(width: width/3, height: 134)
    }
    
    func fetchUserFriends(query: PFQuery) {
        
        loadingView.startAnimating()
        query.limit = 1000
        query.findObjectsInBackground().continueWithSuccessBlock { (task: BFTask!) -> AnyObject? in
            let result = task.result as! [User]
            
            self.dataSource = result
            
            let userIDs = result.flatMap{ $0.objectId }

            // Find all relations
            let relationQuery = User.currentUser()!.following().query()
            relationQuery.whereKey("objectId", containedIn: userIDs)
            relationQuery.limit = 2000
            return relationQuery.findObjectsInBackground()
            
        }.continueWithExecutor(BFExecutor.mainThreadExecutor(), withSuccessBlock:  { (task: BFTask!) -> AnyObject? in
            
            if let result = task.result as? [User] {
                for user in result {
                    user.followingThisUser = true
                }
            }
            
            self.loadingView.stopAnimating()
            self.collectionView.reloadData()
            self.collectionView.animateFadeIn()
            
            return nil
        })
    }
}


extension UserListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("UserCollectionCell", forIndexPath: indexPath) as! UserCollectionCell

        let profile = dataSource[indexPath.row]
        if let avatarFile = profile.avatarThumb {
            cell.avatar.setImageWithPFFile(avatarFile)
        } else {
            cell.avatar.image = UIImage(named: "default-avatar")
        }
        cell.username.text = profile.aozoraUsername
        cell.delegate = self

        let isCurrentUserList = user?.isTheCurrentUser() ?? false
        if profile.isTheCurrentUser() || !isCurrentUserList {
            cell.followButton.hidden = true
        } else {
            cell.followButton.hidden = false
            cell.configureFollowButtonWithState(profile.followingThisUser ?? false)
        }

        cell.layoutIfNeeded()

        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let profile = dataSource[indexPath.row]
        let profileController = Storyboard.profileViewController()

        profileController.initWithUser(profile)
        navigationController?.pushViewController(profileController, animated: true)
    }
}

extension UserListViewController: UserCellDelegate {
    func userCellPressedFollow(userCell: UserCollectionCell) {
        if let currentUser = User.currentUser(),
            let indexPath = collectionView.indexPathForCell(userCell) {

            let user = dataSource[indexPath.row]
            let follow = !(user.followingThisUser ?? false)
            currentUser.followUser(user, follow: follow)
            collectionView.reloadData()
        }
    }
}
