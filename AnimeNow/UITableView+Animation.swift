//
//  UITableView+Animation.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 4/24/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

extension UITableView {
    func updateTableViewCellsHeight() {
        layoutIfNeeded()
        UIView.setAnimationsEnabled(false)
        beginUpdates()
        endUpdates()
        UIView.setAnimationsEnabled(true)
    }
}