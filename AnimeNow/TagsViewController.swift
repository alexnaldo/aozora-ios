//
//  ImagesViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/5/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANCommonKit

protocol TagsViewControllerDelegate: class {
    func tagsViewControllerSelected(tag tag: PFObject?)
}

public let AllThreadTagsPin = "Pin.ThreadTag"
public let PinnedThreadsPin = "Pin.PinnedThreads"

public class TagsViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    weak var delegate: TagsViewControllerDelegate?
    var dataSource: [PFObject] = []
    var selectedTag: PFObject?
    
    var cachedGeneralTags: [ThreadTag] = []

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let searchBarTextField = searchBar.valueForKey("searchField") as? UITextField
        searchBarTextField?.textColor = UIColor.blackColor()
        
        guard let collectionView = collectionView,
            let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
                return
        }
        let size = CGSize(width: view.bounds.size.width, height: 44)
        layout.itemSize = size
        
        let uiButton = searchBar.valueForKey("cancelButton") as! UIButton
        uiButton.setTitle("Done", forState: UIControlState.Normal)
        
        fetchGeneralTags()
        searchBar.enableCancelButton()
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.tagsViewControllerSelected(tag: selectedTag)
        view.endEditing(true)
    }
    
    func fetchGeneralTags() {
        if cachedGeneralTags.count != 0 {
            dataSource = cachedGeneralTags
            collectionView.reloadData()
            return
        }
        
        let query = ThreadTag.query()!
        
        if !User.currentUser()!.isAdmin() {
            query.whereKey("privateTag", equalTo: false)
        }

        query.whereKey("visible", equalTo: true)
        query.orderByAscending("order")
        query.findObjectsInBackground().continueWithExecutor(BFExecutor.mainThreadExecutor(),
            withSuccessBlock: { (task: BFTask!) -> AnyObject! in
                
                self.dataSource = task.result as! [ThreadTag]
                self.collectionView.reloadData()
                
            return nil
        })
    }
    
    func fetchAnimeTags(text: String) {
        
        let query = Anime.query()!
        query.includeKey("details")
        if text.characters.count == 0 {
            query.whereKey("startDate", greaterThanOrEqualTo: NSDate().dateByAddingTimeInterval(-3*30*24*60*60))
            query.whereKey("status", equalTo: "currently airing")
            query.orderByAscending("rank")
        } else {
            query.whereKey("title", matchesRegex: text, modifiers: "i")
        }
        
        query.limit = 100
        query.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if let _ = error {
                // Show error
            } else {
                self.dataSource = result as! [Anime]
                self.collectionView.reloadData()
            }
        }
    }
    
    // MARK: - IBAction
    
    @IBAction func segmentedControlValueChanged(sender: AnyObject) {
        dataSource = []
        collectionView.reloadData()
        let searchingGeneral = segmentedControl.selectedSegmentIndex == 0 ? true : false
        if searchingGeneral {
            fetchGeneralTags()
        } else {
            fetchAnimeTags(searchBar.text!)
        }
    }
    
}

extension TagsViewController: UICollectionViewDataSource {
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TagCell", forIndexPath: indexPath) as! BasicCollectionCell
        
        let tag = dataSource[indexPath.row]
        
        if let tag = tag as? ThreadTag {
            cell.titleLabel.text = "#"+tag.name
            cell.subtitleLabel.text = tag.detail ?? " "
        } else if let anime = tag as? Anime {
            cell.titleLabel.text = "#"+anime.title!
            cell.subtitleLabel.text = anime.informationString()
        }
        
        if selectedTag == tag {
            cell.backgroundColor = UIColor.backgroundDarker()
        } else {
            cell.backgroundColor = UIColor.backgroundWhite()
        }
        
        cell.layoutIfNeeded()

        return cell
    }
}

extension TagsViewController: UICollectionViewDelegate {
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedTag = dataSource[indexPath.row]
        collectionView.reloadData()
    }
}

extension TagsViewController: UISearchBarDelegate {
    
    public func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        segmentedControl.selectedSegmentIndex = 1
        fetchAnimeTags(searchBar.text!)
        view.endEditing(true)
        searchBar.enableCancelButton()
    }
    
    public func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

extension TagsViewController: ModalTransitionScrollable {
    public var transitionScrollView: UIScrollView? {
        return collectionView
    }
}