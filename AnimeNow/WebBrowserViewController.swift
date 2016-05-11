//
//  WebBrowserViewController.swift
//  Seedonk
//
//  Created by Larry Damman on 3/19/15.
//  Copyright (c) 2015 Seedonk. All rights reserved.
//

import WebKit

public class WebBrowserViewController: UIViewController {

    var initialStatusBarStyle: UIStatusBarStyle!
    var initialNavigationBarHidden: Bool!
    public var webView: WKWebView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    
    public var initialUrl: NSURL? {
        didSet {
            if let initialUrl = initialUrl {
                lastRequest = NSURLRequest(URL: initialUrl)
            }
        }
    }
    
    var lastRequest : NSURLRequest?
    
    public var overrideTitle: String?
    
    public func initWithInitialUrl(initialUrl: NSURL?, overrideTitle: String? = nil) {
        self.initialUrl = initialUrl
        if let overrideTitle = overrideTitle {
            self.overrideTitle = overrideTitle
            self.title = overrideTitle
        } else {
            self.title = "Loading..."
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        var frame = view.bounds
        frame.origin.y = 0
        frame.size.height = frame.size.height - 44
        webView = WKWebView(frame: frame)
        webView.navigationDelegate = self
        view.insertSubview(webView, atIndex: 0)
        
        navigationController?.navigationBar.barTintColor = UIColor.darkBlue()
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()

        backButton.enabled = false
        forwardButton.enabled = false

        if let request = lastRequest {
            webView.addObserver(self, forKeyPath: "title", options: .New, context: nil)
            webView.loadRequest(request)
        }
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initialStatusBarStyle = UIApplication.sharedApplication().statusBarStyle
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)

        initialNavigationBarHidden = navigationController?.navigationBarHidden ?? false
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.sharedApplication().setStatusBarStyle(initialStatusBarStyle, animated: true)
        navigationController?.setNavigationBarHidden(initialNavigationBarHidden, animated: true)
    }
    
    // MARK: - KVO
    
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let change = change else {
            return
        }
        
        if overrideTitle != nil {
            return
        }
        
        if keyPath == "title" {
            if let title = change["new"] as? String {
                self.title = title
            }
        }
    }
    
    // MARK: - IBActions

    @IBAction func openInSafari(sender: AnyObject) {
        if let url = initialUrl {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    @IBAction func navigateBack(sender: AnyObject) {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @IBAction func navigateForward(sender: AnyObject) {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    @IBAction func pressedShare(sender: AnyObject) {
        guard let currentURL = webView.URL else {
            return
        }

        let objectsToShare: [AnyObject] = [currentURL]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = (sender as! UIBarButtonItem)
        activityVC.excludedActivityTypes = [UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypePrint];
        self.presentViewController(activityVC, animated: true, completion: nil)
    }

    deinit {
        webView.removeObserver(self, forKeyPath: "title")
        webView = nil
    }

}


// MARK: <UIWebViewDelegate>

extension WebBrowserViewController : WKNavigationDelegate {
    public func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
    }

    public func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {

        backButton.enabled = webView.canGoBack
        forwardButton.enabled = webView.canGoForward
    }
}