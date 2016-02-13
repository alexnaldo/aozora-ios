//
//  TableCellWithCollection.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 1/30/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit


class TableCellWithCollection: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!

    var dataSource: [Anime] = []
    var selectedAnimeCallBack: (Anime -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.registerNibWithClass(AnimePosterCell)
    }
}

extension TableCellWithCollection: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AnimePosterCell", forIndexPath: indexPath) as? AnimePosterCell else {
            return UICollectionViewCell()
        }

        let anime = dataSource[indexPath.row]

        cell.imageView.setImageFrom(urlString: anime.imageUrl)
        cell.titleLabel.text = anime.title ?? ""

        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let anime = dataSource[indexPath.row]
        selectedAnimeCallBack?(anime)
    }
}



