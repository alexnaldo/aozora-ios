//
//  PurchaseViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 5/10/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit
import RMStore

class PurchaseViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var proButton: UIButton!
    @IBOutlet weak var proPlusButton: UIButton!

    var loadingView: LoaderView!

    class func showInAppPurchaseWith(
        viewController: UIViewController) {
        let controller = UIStoryboard(name: "InApp", bundle: nil).instantiateViewControllerWithIdentifier("PurchaseViewController") as! PurchaseViewController
        controller.modalTransitionStyle = .CrossDissolve
        controller.modalPresentationStyle = .OverCurrentContext
        viewController.presentViewController(controller, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        switch AppEnvironment.application() {
        case .Aozora:
            titleLabel.text = "Aozora PRO"
        case .AnimeTrakr:
            titleLabel.text = "AnimeTrakr PRO"
        }

        loadingView = LoaderView(parentView: view)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateViewForPurchaseState), name: PurchasedProNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(setPrices), name: PurchasedProNotification, object: nil)

        if let navController = parentViewController as? UINavigationController {
            if let firstController = navController.viewControllers.first where !firstController.isKindOfClass(SettingsViewController) {
                navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Stop, target: self, action: #selector(dismissViewControllerPressed))
            }
        }

        updateViewForPurchaseState()
        fetchProducts()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func updateViewForPurchaseState() {
        if InAppController.hasAnyPro() {
            let animeApp = AppEnvironment.application().rawValue
            descriptionLabel.text = "Thanks for supporting \(animeApp)! You're an exclusive PRO member that is helping us create an even better app"
        } else {
            //descriptionLabel.text = "Browse all seasonal charts, unlock calendar view, discover more anime, remove all ads forever, and more importantly helps us take Aozora to the next level"
        }
    }

    func fetchProducts() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        loadingView.startAnimating()
        let products: Set = [InAppController.ProIdentifier, InAppController.ProPlusIdentifier]
        RMStore.defaultStore().requestProducts(products, success: { (products, invalidProducts) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            self.setPrices()
            self.loadingView.stopAnimating()
        }) { (error) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false

            let alert = UIAlertController(title: "Products Request Failed", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))

            self.presentViewController(alert, animated: true, completion: nil)
            self.loadingView.stopAnimating()
        }
    }

    // MARK: - Internal Functions

    func setPrices() {

        if InAppController.purchasedPro() {
            proButton.setTitle("Unlocked", forState: .Normal)
        } else {
            let product = RMStore.defaultStore().productForIdentifier(InAppController.ProIdentifier)
            let localizedPrice = RMStore.localizedPriceOfProduct(product)
            proButton.setTitle(localizedPrice, forState: .Normal)
        }

        if InAppController.purchasedProPlus() {
            proPlusButton.setTitle("Unlocked", forState: .Normal)
        } else {
            let product = RMStore.defaultStore().productForIdentifier(InAppController.ProPlusIdentifier)
            let localizedPrice = RMStore.localizedPriceOfProduct(product)
            proPlusButton.setTitle(localizedPrice, forState: .Normal)
        }
    }

    func purchaseProductWithID(productID: String) {
        InAppPurchaseController.purchaseProductWithID(productID).continueWithSuccessBlock { (task: BFTask!) -> AnyObject! in

            return nil
        }
    }

    func dismissViewControllerPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - IBActions

    @IBAction func dismissPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func getPROPressed(sender: AnyObject) {
        purchaseProductWithID(InAppController.ProIdentifier)
    }
    @IBAction func getPROPlusPressed(sender: AnyObject) {
        purchaseProductWithID(InAppController.ProPlusIdentifier)
    }
}

extension PurchaseViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.size.width
        let currentPage = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1
        pageControl.currentPage = Int(currentPage)
    }
}