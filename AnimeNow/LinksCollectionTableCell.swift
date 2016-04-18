//
//  LinksCollectionTable.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 4/17/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

class SimpleLinkCell: UICollectionViewCell {
    @IBOutlet weak var linkLabel: UILabel!
}


class LinksCollectionTableCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!

    var dataSource: [AnimeLink] = []
    var selectedLinkCallBack: (AnimeLink -> Void)?
}

// MARK: - CollectionViewDataSource, Delegate
extension LinksCollectionTableCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SimpleLinkCell", forIndexPath: indexPath) as! SimpleLinkCell

        let link = dataSource[indexPath.row]
        var color: UIColor!

        switch link.site {
        case .Crunchyroll:
            color = UIColor.crunchyroll()
        case .OfficialSite:
            color = UIColor.officialSite()
        case .Daisuki:
            color = UIColor.daisuki()
        case .Funimation:
            color = UIColor.funimation()
        case .MyAnimeList:
            color = UIColor.myAnimeList()
        case .Hummingbird:
            color = UIColor.hummingbird()
        case .Anilist:
            color = UIColor.anilist()
        case .Other:
            color = UIColor.other()
        }

        cell.linkLabel.text = link.site.rawValue
        cell.linkLabel.textColor = .whiteColor()
        cell.linkLabel.backgroundColor = color

        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let link = dataSource[indexPath.row]
        selectedLinkCallBack?(link)
    }
}