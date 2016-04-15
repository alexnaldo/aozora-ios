//
//  UIImageView+SDWebImage.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/10/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import FLAnimatedImage
import PINRemoteImage

extension UIImageView {

    public func setImageFrom(urlString urlString:String!, animated:Bool = false)
    {
        guard let url = NSURL(string: urlString) else {
            return
        }

        layer.removeAllAnimations()
        pin_cancelImageDownload()
        image = nil
        (self as? FLAnimatedImageView)?.animatedImage = nil

        if !animated {
            pin_setImageFromURL(url)
        } else {
            pin_setImageFromURL(url, completion: { [weak self] result in
                guard let _self = self else { return }
                _self.alpha = 0
                UIView.transitionWithView(_self, duration: 0.5, options: [], animations: { () -> Void in
                    _self.image = result.image
                    _self.alpha = 1
                    }, completion: nil)
                })
        }
    }
}