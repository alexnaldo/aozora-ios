//
//  UITableView+Cells.swift
//  Maroup
//
//  Created by Paul Chavarria Podoliako on 1/21/16.
//  Copyright © 2016 PropellerLabs. All rights reserved.
//

import UIKit

extension UITableView {
    func registerNibWithClass(cell: UITableViewCell.Type) {
        let className = String(cell)
        registerNib(UINib(nibName: className, bundle: nil), forCellReuseIdentifier: className)
    }

    func dequeueReusableCellWithClass<T>(cell: T.Type) -> T? {
        let className = String(cell)
        return dequeueReusableCellWithIdentifier(className) as? T
    }

    func rowHeightAutomaticDimensionWithEstimatedRowHeight(estimatedRowHeight: CGFloat) {
        self.estimatedRowHeight = estimatedRowHeight
        rowHeight = UITableViewAutomaticDimension
    }
}
