//
//  PhotoViewer.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 4/28/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation
import NYTPhotoViewer
import PINRemoteImage

class PhotosViewController: NYTPhotosViewController {

    convenience init(allPhotos: [NYTPhoto]) {
        self.init(photos: allPhotos)

        delegate = self

        if let firstPhoto = allPhotos.first {
            updateImageForPhoto(firstPhoto, photosViewController: self)
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }
}

extension PhotosViewController: NYTPhotosViewControllerDelegate {
    func photosViewController(photosViewController: NYTPhotosViewController, didNavigateToPhoto photo: NYTPhoto, atIndex photoIndex: UInt) {
        updateImageForPhoto(photo, photosViewController: photosViewController)
    }

    func photosViewController(photosViewController: NYTPhotosViewController, handleActionButtonTappedForPhoto photo: NYTPhoto) -> Bool {

        var objectsToShare: [AnyObject] = []

        if let image = photo.image {
            objectsToShare = [image]
        } else if let gif = photo.imageData {
            objectsToShare = [gif]
        }

        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.excludedActivityTypes = [UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList,UIActivityTypePrint]
        presentViewController(activityVC, animated: true, completion: nil)

        return true
    }
    func updateImageForPhoto(photo: NYTPhoto, photosViewController: NYTPhotosViewController) {
        if let imageItem = photo as? ImageData,
            let url = NSURL(string: imageItem.url) {

            PINRemoteImageManager.sharedImageManager().downloadImageWithURL(url, completion: { result in
                if let image = result.image {
                    imageItem.image = image
                }
                if let image = result.animatedImage {
                    imageItem.imageData = image.data
                }
                photosViewController.updateImageForPhoto(photo)
            })
        }
    }
}