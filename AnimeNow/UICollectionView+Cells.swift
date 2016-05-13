//
//  UICollectionView+Cells.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 2/12/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import UIKit

extension UICollectionView {
    func registerNibWithClass(cell: UICollectionViewCell.Type) {
        let className = String(cell)
        registerNib(UINib(nibName: className, bundle: nil), forCellWithReuseIdentifier: className)
    }

    func dequeueReusableCellWithClass<T>(cell: T.Type, indexPath: NSIndexPath) -> T! {
        let className = String(cell)
        return dequeueReusableCellWithReuseIdentifier(className, forIndexPath: indexPath) as! T
    }
}