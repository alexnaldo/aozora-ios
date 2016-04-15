//
//  FilterViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/25/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit


enum FilterSection: String {
    case View
    case Sort
    case FilterTitle = "Filter"
    case AnimeType = "Type"
    case Year
    case Status
    case Studio
    case Classification
    case Genres
    
}

enum SortType: String {
    case Rating = "Rating"
    case Popularity = "Popularity"
    case Title = "Title"
    case NextAiringEpisode = "Next Episode to Air"
    case NextEpisodeToWatch = "Next Episode to Watch"
    case Newest = "Newest"
    case Oldest = "Oldest"
    case None = "None"
    case MyRating = "My Rating"
}

typealias Configuration = [(section: FilterSection, value: String?, dataSource: [String])]

protocol FilterViewControllerDelegate: class {
    func finishedWith(configuration configuration: Configuration, selectedGenres: [String])
}

class FilterViewController: UIViewController {
    
    let sectionHeaderHeight: CGFloat = 44
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    weak var delegate: FilterViewControllerDelegate?
    
    var expandedSection: Int?
    var selectedGenres: [String] = []
    var filteredDataSource: [[String]] = []
    var sectionsDataSource: Configuration = []

    var shouldContractSections: Bool = false
    
    var filteringSomething: Bool {
        get {
            for (section, value, _) in sectionsDataSource where section != .View && section != .Sort && section != .FilterTitle && value != nil {
                return true
            }
            return false
        }
    }
    
    func initWith(configuration configuration: Configuration, selectedGenres: [String] = [], shouldContractSections: Bool = false) {
        sectionsDataSource = configuration
        self.selectedGenres = selectedGenres
        self.shouldContractSections = shouldContractSections
        for (_, _, dataSource) in sectionsDataSource {
            if shouldContractSections {
                filteredDataSource.append([])
            } else {
                filteredDataSource.append(dataSource)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func dimissViewControllerPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func applyFilterPressed(sender: AnyObject) {
        
        if InAppController.hasAnyPro() {
            delegate?.finishedWith(configuration: sectionsDataSource, selectedGenres: selectedGenres)
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            InAppPurchaseViewController.showInAppPurchaseWith(self)
        }
        
    }
}

extension FilterViewController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return filteredDataSource.count
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredDataSource[section].count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("BasicCollectionCell", forIndexPath: indexPath) as! BasicCollectionCell
        
        let (filterSection, sectionValue, _) = sectionsDataSource[indexPath.section]
        let value = filteredDataSource[indexPath.section][indexPath.row]

        cell.titleLabel.text = value
        
        if filterSection == FilterSection.Genres {
            if let _ = selectedGenres.indexOf(value) {
                cell.backgroundColor = UIColor.backgroundEvenDarker()
            } else {
                cell.backgroundColor = UIColor.backgroundDarker()
            }
        } else if let sectionValue = sectionValue where sectionValue == value {
            cell.backgroundColor = UIColor.backgroundEvenDarker()
        } else {
            cell.backgroundColor = UIColor.backgroundDarker()
        }
    
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        var reusableView: UICollectionReusableView!
        
        if kind == UICollectionElementKindSectionHeader {
            
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "HeaderView", forIndexPath: indexPath) as! BasicCollectionReusableView
            
            let (filterSection, value, _) = sectionsDataSource[indexPath.section]
            
            headerView.titleImageView.image = nil
            headerView.titleLabel.text = filterSection.rawValue
            headerView.delegate = self
            headerView.section = indexPath.section
            
            
            // Image
            switch filterSection {
            case .View:
                if let image = UIImage(named: "icon-view") {
                    headerView.titleImageView.image = image.imageWithRenderingMode(.AlwaysTemplate)
                }
            case .Sort:
                if let image = UIImage(named: "icon-sort") {
                    headerView.titleImageView.image = image.imageWithRenderingMode(.AlwaysTemplate)
                }
            case .FilterTitle:
                if let image = UIImage(named: "icon-filter") {
                    headerView.titleImageView.image = image.imageWithRenderingMode(.AlwaysTemplate)
                }
            default:
                break
            }
            
            // Value
            switch filterSection {
            case .View: fallthrough
            case .Sort:
                if let value = value {
                    headerView.subtitleLabel.text = value + " " + FontAwesome.AngleDown.rawValue
                }
            case .FilterTitle:
                headerView.subtitleLabel.text = filteringSomething ? "Clear all" : ""
            case .AnimeType: fallthrough
            case .Year: fallthrough
            case .Status: fallthrough
            case .Studio: fallthrough
            case .Classification: fallthrough
            case .Genres:
                if let value = value {
                    headerView.subtitleLabel.text = value + " " + FontAwesome.TimesCircle.rawValue
                } else {
                    headerView.subtitleLabel.text = FontAwesome.AngleDown.rawValue
                }
            }
            
            reusableView = headerView;
        }
        
        return reusableView
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        return CGSize(width: view.bounds.size.width, height: sectionHeaderHeight)
    }
}

extension FilterViewController: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let (filterSection, _, _) = sectionsDataSource[indexPath.section]
        let string = filteredDataSource[indexPath.section][indexPath.row]
        
        switch filterSection {
        case .View: fallthrough
        case .Sort: fallthrough
        case .AnimeType: fallthrough
        case .Status: fallthrough
        case .Classification: fallthrough
        case .Studio: fallthrough
        case .Year:
            sectionsDataSource[indexPath.section].value = string
            if shouldContractSections {
                filteredDataSource[indexPath.section] = []
                expandedSection = nil
            }

            collectionView.reloadData()
        case .Genres:
            if let index = selectedGenres.indexOf(string) {
                selectedGenres.removeAtIndex(index)
            } else {
                selectedGenres.append(string)
            }
            sectionsDataSource[indexPath.section].value = selectedGenres.count != 0 ? "\(selectedGenres.count) genres" : nil
            collectionView.reloadData()
        case .FilterTitle: break
        }
        
        
    }
}

extension FilterViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let (filterSection, _, _) = sectionsDataSource[indexPath.section]
        
        switch filterSection {
        case .View: fallthrough
        case .Sort: fallthrough
        case .FilterTitle: fallthrough
        case .AnimeType: fallthrough
        case .Status: fallthrough
        case .Classification:
            return CGSize(width: (view.bounds.size.width-23), height: sectionHeaderHeight)
        case .Studio:
            return CGSize(width: (view.bounds.size.width-23-1)/2, height: sectionHeaderHeight)
        case .Year:
            return CGSize(width: (view.bounds.size.width-23-4)/5, height: sectionHeaderHeight)
        case .Genres:
            return CGSize(width: (view.bounds.size.width-23-2)/3, height: sectionHeaderHeight)
        }
    }
}


extension FilterViewController: BasicCollectionReusableViewDelegate {
    func headerSelectedActionButton(cell: BasicCollectionReusableView) {
        
        let section = cell.section!
        let filterSection = sectionsDataSource[section].section
        
        if filterSection == .FilterTitle {
            // Do nothing
            return;
        }

        if shouldContractSections {
            if let expandedSection = expandedSection {
                filteredDataSource[expandedSection] = []
            }

            if section != expandedSection {
                expandedSection = section
                filteredDataSource[section] = sectionsDataSource[section].dataSource
            } else {
                expandedSection = nil
            }
        }
        
        collectionView.reloadData()
    }
    
    func headerSelectedActionButton2(cell: BasicCollectionReusableView) {
        let section = cell.section!
        let filterSection = sectionsDataSource[section].section
        switch filterSection {
        case .View: fallthrough
        case .Sort:
            // Show down-down
            headerSelectedActionButton(cell)
        case .FilterTitle:
            // Clear all filters
            let firstFilterIndex = section+1
            let lastFilterIndex = sectionsDataSource.count - 1
            for index in firstFilterIndex...lastFilterIndex {
                sectionsDataSource[index].value = nil
            }
            selectedGenres.removeAll(keepCapacity: false)
            expandedSection = nil
            collectionView.reloadData()
            return
        case .AnimeType: fallthrough
        case .Year: fallthrough
        case .Status: fallthrough
        case .Studio: fallthrough
        case .Classification: fallthrough
        case .Genres:
            // Clear a filter or open drop-down
            if let _ = sectionsDataSource[section].value {
                if filterSection == .Genres {
                    selectedGenres.removeAll(keepCapacity: false)
                }
                
                sectionsDataSource[section].value = nil
                collectionView.reloadData()
            } else {
                headerSelectedActionButton(cell)
            }
        }
        
    }
}

extension FilterViewController: UINavigationBarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
}

extension FilterViewController: ModalTransitionScrollable {
    var transitionScrollView: UIScrollView? {
        return collectionView
    }
}
