//
//  ViewController.swift
//  Stainless II
//
//  Created by Grant Goodman on 8/25/15.
//  Copyright (c) 2015 Macster Software Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
    var progressBarIsFinishedAnimating: Bool!
    var progressBarTimer: NSTimer!
    var progressBarDidFinishAnimatingTimer: NSTimer!
    
    var webViewLoads = 0
    var webViewDidStart: Int = 0
    var webViewDidFinish: Int = 0
    
    var notConnected: Bool!
    var isSecure: Bool!
    
    var historyArray = [HistoryObject]()
    var selectedLink: HistoryObject!
    var previousURL: NSURL!
    
    var autoCompleteArray = [String]()
    var topHit: HistoryObject!
    
    @IBOutlet weak var reloadButton: AHB!
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var linkProgressView: UIProgressView!
    
    @IBOutlet weak var bottomToolbar: UIToolbar!
    @IBOutlet weak var backBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var forwardBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var historyBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var bookmarksBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var shareBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var webView: UIWebView!
    
    @IBOutlet weak var noticeMessageLabel: UILabel!
    
    @IBOutlet var swipeRightGestureRecognizer: UISwipeGestureRecognizer!
    @IBOutlet var swipeLeftGestureRecognizer: UISwipeGestureRecognizer!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var searchImage: UIImageView!
    
    @IBOutlet weak var stopLoadingButton: AHB!
    
    @IBOutlet weak var autoCompleteTableView: UITableView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        cancelButton.hidden = true
        cancelButton.userInteractionEnabled = false
        
        if linkTextField.text == nil || linkTextField.text == ""
        {
            UIView.animateWithDuration(0.2, delay: 0, options:UIViewAnimationOptions.CurveEaseOut, animations:
                {() in
                    self.reloadButton.alpha = 0.0
                    self.reloadButton.userInteractionEnabled = false
                },
                completion: nil)
        }
        
        linkProgressView.hidden = true
        noticeMessageLabel.hidden = true
        
        swipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Right
        swipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Left
        
        var reachabilityStatus = IJReachability.isConnectedToNetwork()
        
        if reachabilityStatus == false
        {
            notConnected = true
        }
        else
        {
            if examineReachabilityOfHost("google.com") == false
            {
                notConnected = true
            }
            else
            {
                notConnected = false
            }
        }
        
        if selectedLink != nil
        {
            var networkRequest = NSURLRequest(URL: selectedLink.pageURL)
            dispatch_async(dispatch_get_main_queue())
                {
                    self.webView.loadRequest(networkRequest)
            }
        }
        else if previousURL != nil
        {
            var networkRequest = NSURLRequest(URL: previousURL)
            dispatch_async(dispatch_get_main_queue())
                {
                    self.webView.loadRequest(networkRequest)
            }
        }
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.objectForKey("historyArray") != nil && userDefaults.objectForKey("previousURL") != nil
        {
            historyArray = userDefaults.objectForKey("historyArray") as! [HistoryObject]
            previousURL = userDefaults.objectForKey("previousURL") as! NSURL
        }
    }
    
    override func viewDidAppear(animated: Bool)
    {
        linkTextField.frame = CGRectMake(linkTextField.frame.origin.x, linkTextField.frame.origin.y, linkTextField.frame.size.width, linkTextField.frame.size.height - 2)
        
        if historyArray.count == 0
        {
            historyBarButtonItem.enabled = false
        }
        
        if webView.request == nil
        {
            shareBarButtonItem.enabled = false
        }
    }
    
    @IBAction func backBarButtonItem(sender: AnyObject)
    {
        if webView.canGoBack
        {
            webView.goBack()
        }
    }
    
    @IBAction func forwardBarButtonItem(sender: AnyObject)
    {
        if webView.canGoForward
        {
            webView.goForward()
        }
    }
    
    @IBAction func swipeRightGestureRecognizer(sender: AnyObject)
    {
        if webView.canGoBack
        {
            PKHUD.sharedHUD.contentView = PKHUDImageView(image: PKHUDAssets.backImage)
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: 0.2)
            
            webView.goBack()
        }
    }
    
    @IBAction func swipeLeftGestureRecognizer(sender: AnyObject)
    {
        if webView.canGoForward
        {
            PKHUD.sharedHUD.contentView = PKHUDImageView(image: PKHUDAssets.forwardImage)
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.hide(afterDelay: 0.2)
            
            webView.goForward()
        }
    }
    
    @IBAction func cancelButton(sender: AnyObject)
    {
        linkTextField.resignFirstResponder()
        autoCompleteTableView.alpha = 0.0
        
        if webView.request != nil
        {
            var shortenedLinkArray = webView.request!.URL!.absoluteString!.componentsSeparatedByString("/")
            
            if shortenedLinkArray[2] != "www.google.com" && !shortenedLinkArray[3].hasPrefix("search")
            {
                if shortenedLinkArray[2].hasPrefix("www.")
                {
                    var linkWithoutWPrefixArray = shortenedLinkArray[2].componentsSeparatedByString("www.")
                    
                    linkTextField.text = linkWithoutWPrefixArray[1]
                }
                else
                {
                    linkTextField.text = shortenedLinkArray[2]
                }
            }
            else if shortenedLinkArray[2] == "www.google.com" && shortenedLinkArray[3].hasPrefix("search")
            {
                linkTextField.text = webView.stringByEvaluatingJavaScriptFromString("document.getElementById('lst-ib').value")
            }
            else if shortenedLinkArray[2] == "www.google.com" && !shortenedLinkArray[3].hasPrefix("search")
            {
                linkTextField.text = "google.com"
            }
            else
            {
                linkTextField.text = webView.request!.URL!.absoluteString!
            }
            
            if isSecure == true
            {
                searchImage.hidden = false
                searchImage.frame = CGRectMake(15, 35.0, 8.67, 11.92125)
                searchImage.image = UIImage(named: "NavigationBarLock@2x.png")
            }
            
            if linkTextField.text == nil || linkTextField.text == ""
            {
                searchImage.hidden = false
                searchImage.frame = CGRectMake(72, 33, 14, 14)
                searchImage.image = UIImage(named: "URLMenuSearchMagnifier@2x.png")
                
                UIView.animateWithDuration(0.2, delay: 0, options:UIViewAnimationOptions.CurveEaseOut, animations:
                    {() in
                        self.reloadButton.alpha = 0.0
                        self.reloadButton.userInteractionEnabled = false
                    },
                    completion: nil)
            }
            
            if notConnected == true
            {
                configureView("message", messageText: "Stainless cannot open the page because your device is not connected to the Internet.")
                linkTextField.resignFirstResponder()
                self.webView.stopLoading()
                
                UIView.animateWithDuration(0.2, animations:
                    {
                        self.linkTextField.frame = CGRectMake(self.linkTextField.frame.origin.x, self.linkTextField.frame.origin.y, self.linkTextField.frame.size.width + 64, self.linkTextField.frame.size.height)
                        
                        self.linkTextField.textAlignment = NSTextAlignment.Center
                        
                        if self.linkTextField.text != nil && self.linkTextField.text != ""
                        {
                            UIView.animateWithDuration(0.2, delay: 0, options:UIViewAnimationOptions.CurveEaseOut, animations:
                                {() in
                                    self.reloadButton.alpha = 1.0
                                    self.reloadButton.userInteractionEnabled = true
                                },
                                completion: nil)
                        }
                        
                        self.cancelButton.hidden = true
                        self.cancelButton.userInteractionEnabled = false
                })
            }
        }
        
        if self.linkTextField.text != nil && self.linkTextField.text != ""
        {
            UIView.animateWithDuration(0.2, delay: 0, options:UIViewAnimationOptions.CurveEaseOut, animations:
                {() in
                    self.reloadButton.alpha = 1.0
                    self.reloadButton.userInteractionEnabled = true
                },
                completion: nil)
        }
        
        if linkTextField.text == nil || linkTextField.text == "" || webView.request == nil
        {
            searchImage.hidden = false
            searchImage.frame = CGRectMake(72, 33, 14, 14)
            searchImage.image = UIImage(named: "URLMenuSearchMagnifier@2x.png")
            
            UIView.animateWithDuration(0.2, delay: 0, options:UIViewAnimationOptions.CurveEaseOut, animations:
                {() in
                    self.reloadButton.alpha = 0.0
                    self.reloadButton.userInteractionEnabled = false
                },
                completion: nil)
            
            linkTextField.text = ""
        }
    }
    
    @IBAction func reloadButton(sender: AnyObject)
    {
        webView.reload()
    }
    
    @IBAction func stopLoadingButton(sender: AnyObject)
    {
        webView.stopLoading()
        linkProgressView.progress = 100.0
        
        UIView.animateWithDuration(0.2, delay: 0, options:UIViewAnimationOptions.CurveEaseOut, animations:
            {() in
                self.stopLoadingButton.alpha = 0.0
                self.stopLoadingButton.userInteractionEnabled = false
                self.reloadButton.alpha = 1.0
                self.reloadButton.userInteractionEnabled = true
            },
            completion: nil)
    }
    
    required init(coder aDecoder: NSCoder)
    {
        progressBarIsFinishedAnimating = false
        progressBarTimer = NSTimer()
        progressBarDidFinishAnimatingTimer = NSTimer()
        
        super.init(coder: aDecoder)
    }
    
    func startAnimatingProgressBar()
    {
        progressBarIsFinishedAnimating = false
        linkProgressView.hidden = false
        linkProgressView.alpha = 0
        
        UIView.animateWithDuration(0.2, animations:
            { () -> Void in
                self.linkProgressView.alpha = 0.6
        })
        
        linkProgressView.progress = 0.0
        
        var animationSpeed = drand48() / 80;
        
        progressBarTimer = NSTimer.scheduledTimerWithTimeInterval(animationSpeed, target: self, selector: "advanceProgressBar", userInfo: nil, repeats: true)
    }
    
    func finishAnimatingProgressBar()
    {
        progressBarIsFinishedAnimating = true
    }
    
    func advanceProgressBar()
    {
        if (progressBarIsFinishedAnimating != nil)
        {
            if linkProgressView.progress >= 1
            {
                UIView.animateWithDuration(0.2, animations:
                    { () -> Void in
                        self.linkProgressView.alpha = 0
                })
                
                progressBarTimer.invalidate()
            }
            else
            {
                var animationSpeed = drand48() / 40
                
                linkProgressView.progress += Float(animationSpeed)
            }
        }
        else
        {
            if linkProgressView.progress >= 0.00 && linkProgressView.progress <= 0.10
            {
                var animationSpeed = drand48() / 8000;
                
                linkProgressView.progress += Float(animationSpeed)
            }
            else if linkProgressView.progress >= 0.10 && linkProgressView.progress <= 0.42
            {
                var smallerNumber = drand48() / 2000;
                
                linkProgressView.progress += Float(smallerNumber)
            }
            else if linkProgressView.progress >= 0.42 && linkProgressView.progress <= 0.80
            {
                var superSmallNumber = drand48() / 8000;
                
                linkProgressView.progress += Float(superSmallNumber)
            }
            else if linkProgressView.progress == 0.80
            {
                linkProgressView.progress = 0.80
            }
        }
    }
    
    func configureView(forType: String, messageText: String?)
    {
        let charactersInForType = forType.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).filter({!isEmpty($0)})
        
        var formattedForTypeString: String = join("", charactersInForType)
        
        if formattedForTypeString.lowercaseString == "internet"
        {
            webView.hidden = false
            webView.userInteractionEnabled = true
            
            noticeMessageLabel.hidden = true
            noticeMessageLabel.text = "Notice message."
        }
        
        if formattedForTypeString.lowercaseString == "message"
        {
            webView.hidden = true
            webView.userInteractionEnabled = false
            webView.stopLoading()
            
            noticeMessageLabel.hidden = false
            
            if messageText == "" || messageText == nil
            {
                noticeMessageLabel.text = "An unknown error occured."
            }
            else
            {
                noticeMessageLabel.text = messageText
            }
        }
    }
    
    func configureNavigationButtons()
    {
        if webView.canGoBack
        {
            backBarButtonItem.enabled = true
        }
        else
        {
            backBarButtonItem.enabled = false
        }
        
        if webView.canGoForward
        {
            forwardBarButtonItem.enabled = true
        }
        else
        {
            forwardBarButtonItem.enabled = false
        }
    }
}

func examineReachabilityOfHost(hostName: String) -> Bool
{
    var reachabilityStatus = Reachability(hostname: hostName).currentReachabilityStatus.description
    
    if reachabilityStatus == "No Connection"
    {
        return false
    }
    
    return true
}

extension ViewController : UIWebViewDelegate
{
    func webView(webView: UIWebView, didFailLoadWithError error: NSError)
    {
        progressBarIsFinishedAnimating = true
        
        webViewLoads = 0
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool
    {
        return true
    }
    
    func webViewDidStartLoad(webView: UIWebView)
    {
        if historyArray.count == 0
        {
            historyBarButtonItem.enabled = false
        }
        
        if webView.request == nil
        {
            shareBarButtonItem.enabled = false
        }
        
        webViewDidStart++
        webViewLoads++
        
        if webViewLoads <= 1
        {
            startAnimatingProgressBar()
        }
        
        if !self.linkTextField.isFirstResponder()
        {
            UIView.animateWithDuration(0.2, delay: 0, options:UIViewAnimationOptions.CurveEaseOut, animations:
                {() in
                    self.stopLoadingButton.alpha = 1.0
                    self.stopLoadingButton.userInteractionEnabled = true
                },
                completion: nil)
        }
        
        UIView.animateWithDuration(0.2, delay: 0, options:UIViewAnimationOptions.CurveEaseOut, animations:
            {() in
                self.reloadButton.alpha = 0.0
                self.reloadButton.userInteractionEnabled = false
            },
            completion: nil)
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func webViewDidFinishLoad(webView: UIWebView)
    {
        webViewLoads--
        webViewDidFinish++
        
        if webViewLoads == 0
        {
            finishAnimatingProgressBar()
            configureView("internet", messageText: nil)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            configureNavigationButtons()
            
            var newHistoryObject = HistoryObject(pageTitle: webView.stringByEvaluatingJavaScriptFromString("document.title")!, pageURL: webView.request!.URL!.absoluteURL!)
            
            if webView.request!.URL!.absoluteURL! != previousURL || !contains(historyArray, newHistoryObject)
            {
                var newHistoryArray: [HistoryObject]
                newHistoryArray = historyArray
                
                for var i = 0; i < historyArray.count; i++
                {
                    if historyArray[i].pageTitle == newHistoryObject.pageTitle
                    {
                        newHistoryArray.removeAtIndex(i)
                    }
                }
                
                historyArray = newHistoryArray
                
                if newHistoryObject.pageURL != NSURL(string: "about:blank") && newHistoryObject.pageTitle != "" && newHistoryObject.pageTitle != nil && newHistoryObject.pageURL != nil
                {
                    historyArray.append(newHistoryObject)
                    println(historyArray.endIndex.littleEndian.littleEndian)
                    previousURL = webView.request!.URL!.absoluteURL!
                    historyBarButtonItem.enabled = true
                    shareBarButtonItem.enabled = true
                    
                    //                    let userDefaults = NSUserDefaults.standardUserDefaults()
                    //                    userDefaults.setObject(historyArray, forKey: "historyArray")
                    //                    userDefaults.setObject(previousURL, forKey: "previousURL")
                }
            }
            
            var shortenedLinkArray = webView.request!.URL!.absoluteString!.componentsSeparatedByString("/")
            
            if !linkTextField.isFirstResponder()
            {
                if shortenedLinkArray.count > 3
                {
                    if shortenedLinkArray[2] != "www.google.com" && !shortenedLinkArray[3].hasPrefix("search")
                    {
                        if shortenedLinkArray[2].hasPrefix("www.")
                        {
                            var linkWithoutWPrefixArray = shortenedLinkArray[2].componentsSeparatedByString("www.")
                            
                            linkTextField.text = linkWithoutWPrefixArray[1]
                        }
                        else
                        {
                            linkTextField.text = shortenedLinkArray[2]
                        }
                    }
                    else if shortenedLinkArray[2] == "www.google.com" && shortenedLinkArray[3].hasPrefix("search")
                    {
                        linkTextField.text = webView.stringByEvaluatingJavaScriptFromString("document.getElementById('lst-ib').value")
                    }
                    else if shortenedLinkArray[2] == "www.google.com" && !shortenedLinkArray[3].hasPrefix("search")
                    {
                        linkTextField.text = "google.com"
                    }
                }
                else
                {
                    linkTextField.text = webView.request!.URL!.absoluteString!
                }
            }
            
            if linkTextField.text != nil && linkTextField != "" && !linkTextField.isFirstResponder()
            {
                UIView.animateWithDuration(0.2, delay: 0, options:UIViewAnimationOptions.CurveEaseOut, animations:
                    {() in
                        self.reloadButton.alpha = 1.0
                        self.reloadButton.userInteractionEnabled = true
                    },
                    completion: nil)
            }
            
            if shortenedLinkArray[0].hasPrefix("https")
            {
                if !linkTextField.isFirstResponder()
                {
                    searchImage.hidden = false
                    searchImage.frame = CGRectMake(15, 35.0, 8.67, 11.92125)
                    searchImage.image = UIImage(named: "NavigationBarLock@2x.png")
                }
                
                isSecure = true
            }
            else
            {
                searchImage.hidden = true
                isSecure = false
            }
            
            UIView.animateWithDuration(0.2, delay: 0, options:UIViewAnimationOptions.CurveEaseOut, animations:
                {() in
                    self.stopLoadingButton.alpha = 0.0
                    self.stopLoadingButton.userInteractionEnabled = false
                },
                completion: nil)
            
            if historyArray.count > 0
            {
                historyBarButtonItem.enabled = true
            }
            
            if webView.request != nil
            {
                shareBarButtonItem.enabled = true
            }
            return
        }
        
        configureView("internet", messageText: nil)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        configureNavigationButtons()
        
        var shortenedLinkArray = webView.request!.URL!.absoluteString!.componentsSeparatedByString("/")
        
        if !linkTextField.isFirstResponder()
        {
            if shortenedLinkArray.count > 3
            {
                if shortenedLinkArray[2] != "www.google.com" && !shortenedLinkArray[3].hasPrefix("search")
                {
                    if shortenedLinkArray[2].hasPrefix("www.")
                    {
                        var linkWithoutWPrefixArray = shortenedLinkArray[2].componentsSeparatedByString("www.")
                        
                        linkTextField.text = linkWithoutWPrefixArray[1]
                    }
                    else
                    {
                        linkTextField.text = shortenedLinkArray[2]
                    }
                }
                else if shortenedLinkArray[2] == "www.google.com" && shortenedLinkArray[3].hasPrefix("search")
                {
                    linkTextField.text = webView.stringByEvaluatingJavaScriptFromString("document.getElementById('lst-ib').value")
                }
                else if shortenedLinkArray[2] == "www.google.com" && !shortenedLinkArray[3].hasPrefix("search")
                {
                    linkTextField.text = "google.com"
                }
            }
            else
            {
                linkTextField.text = webView.request!.URL!.absoluteString!
            }
        }
        
        if linkTextField.text != nil && linkTextField != "" && !linkTextField.isFirstResponder()
        {
            UIView.animateWithDuration(0.2, delay: 0, options:UIViewAnimationOptions.CurveEaseOut, animations:
                {() in
                    self.reloadButton.alpha = 1.0
                    self.reloadButton.userInteractionEnabled = true
                },
                completion: nil)
        }
        
        if shortenedLinkArray[0].hasPrefix("https")
        {
            if !linkTextField.isFirstResponder()
            {
                searchImage.hidden = false
                searchImage.frame = CGRectMake(15, 35.0, 8.67, 11.92125)
                searchImage.image = UIImage(named: "NavigationBarLock@2x.png")
            }
            
            isSecure = true
        }
        else
        {
            searchImage.hidden = true
            isSecure = false
        }
        
        UIView.animateWithDuration(0.2, delay: 0, options:UIViewAnimationOptions.CurveEaseOut, animations:
            {() in
                self.stopLoadingButton.alpha = 0.0
                self.stopLoadingButton.userInteractionEnabled = false
            },
            completion: nil)
        
        if historyArray.count > 0
        {
            historyBarButtonItem.enabled = true
        }
        
        if webView.request != nil
        {
            shareBarButtonItem.enabled = true
        }
    }
    
    func getJSON(urlToRequest: String) -> NSData
    {
        return NSData(contentsOfURL: NSURL(string: urlToRequest)!)!
    }
    
    func parseJSON(inputData: NSData) -> NSArray
    {
        var occuredError: NSError?
        var returnedArray: NSArray = NSJSONSerialization.JSONObjectWithData(inputData, options: NSJSONReadingOptions.MutableContainers, error: &occuredError) as! NSArray
        return returnedArray
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "historySegue"
        {
            var destinationController = segue.destinationViewController as! HC
            
            if historyArray.count > 0
            {
                destinationController.historyArray = historyArray
            }
            
            if webView.request != nil
            {
                destinationController.previouslySelectedLink = webView.request!.URL!.absoluteURL!
            }
        }
    }
    
    @IBAction func historyBarButtonItem(sender: AnyObject)
    {
        performSegueWithIdentifier("historySegue", sender: self)
    }
    
    @IBAction func shareBarButtonItem(sender: AnyObject)
    {
        let objectsToShare = [webView.request!.URL!.absoluteString!]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        
        self.presentViewController(activityVC, animated: true, completion: nil)
    }
}

extension ViewController : UITextFieldDelegate
{
    func textFieldShouldClear(textField: UITextField) -> Bool
    {
        autoCompleteArray.removeAll(keepCapacity: false)
        autoCompleteTableView.reloadData()
        dispatch_async(dispatch_get_main_queue(),
            {
                self.autoCompleteTableView.reloadData()
        })
        autoCompleteTableView.alpha = 0.0
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool
    {
        autoCompleteArray.removeAll(keepCapacity: false)
        autoCompleteTableView.reloadData()
        
        for countedObject in historyArray
        {
            if countedObject.pageTitle.lowercaseString.hasPrefix((textField.text as NSString).stringByReplacingCharactersInRange(range, withString: string))
            {
                topHit = countedObject
                autoCompleteTableView.reloadData()
            }
        }
        
        if (textField.text as NSString).stringByReplacingCharactersInRange(range, withString: string) != ""
        {
            autoCompleteTableView.sectionHeaderHeight = 24
            
            autoCompleteArray.append((textField.text as NSString).stringByReplacingCharactersInRange(range, withString: string))
            
            dispatch_async(dispatch_get_main_queue())
                {
                    var jsonLink = "http://api.bing.com/osjson.aspx?query=\((textField.text as NSString).stringByReplacingCharactersInRange(range, withString: string))".stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
                    
                    var parsedJSON = self.parseJSON(self.getJSON(jsonLink))
                    
                    if parsedJSON[1].count > 0
                    {
                        println(parsedJSON[1][0])
                        self.autoCompleteTableView.alpha = 1.0
                        
                        for countedSuggestion in parsedJSON[1] as! NSArray
                        {
                            if self.autoCompleteArray.count < 4
                            {
                                self.autoCompleteArray.append(countedSuggestion as! String)
                                self.autoCompleteTableView.reloadData()
                            }
                        }
                    }
            else
            {
                self.autoCompleteArray.removeAll(keepCapacity: false)
                self.autoCompleteTableView.reloadData()
                self.autoCompleteTableView.alpha = 0.0
        
        }
            }}
        
        return true
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool
    {
        autoCompleteArray.removeAll(keepCapacity: false)
        autoCompleteTableView.reloadData()
        
        for countedObject in historyArray
        {
            if countedObject.pageTitle.hasPrefix(textField.text)
            {
                topHit = countedObject
                autoCompleteTableView.reloadData()
            }
            else
            {
                topHit = nil
                autoCompleteTableView.reloadData()
            }
        }
        
        if textField.text != nil && textField.text != ""
        {
            autoCompleteTableView.sectionHeaderHeight = 24
            
            autoCompleteArray.append(textField.text)
            
            var jsonLink = "http://api.bing.com/osjson.aspx?query=\(textField.text)".stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            
            var parsedJSON = parseJSON(getJSON(jsonLink))
            
            if parsedJSON[1].count > 0
            {
                println(parsedJSON[1][0])
                autoCompleteTableView.alpha = 1.0
                
                for countedSuggestion in parsedJSON[1] as! NSArray
                {
                    if autoCompleteArray.count < 4
                    {
                        autoCompleteArray.append(countedSuggestion as! String)
                        autoCompleteTableView.reloadData()
                    }
                }
            }
        }
        else
        {
            autoCompleteTableView.alpha = 0.0
        }
        
        
        UIView.animateWithDuration(0.2, animations:
            {
                textField.frame = CGRectMake(textField.frame.origin.x, textField.frame.origin.y, textField.frame.size.width - 64, textField.frame.size.height)
                
                textField.textAlignment = NSTextAlignment.Left
                
                self.searchImage.hidden = true
                
                if self.webView.request != nil
                {
                    var shortenedLinkArray = self.webView.request!.URL!.absoluteString!.componentsSeparatedByString("/")
                    
                    if shortenedLinkArray.count > 3
                    {
                        if shortenedLinkArray[2] != "www.google.com" && !shortenedLinkArray[3].hasPrefix("search")
                        {
                            textField.text = self.webView.request!.URL!.absoluteString!
                        }
                    }
                }
                
                UIView.animateWithDuration(0.2, delay: 0, options:UIViewAnimationOptions.CurveEaseOut, animations:
                    {() in
                        self.reloadButton.alpha = 0.0
                        self.reloadButton.userInteractionEnabled = false
                        self.stopLoadingButton.alpha = 0.0
                        self.stopLoadingButton.userInteractionEnabled = false
                    },
                    completion: nil)
                
                self.cancelButton.hidden = false
                self.cancelButton.userInteractionEnabled = true
        })
        
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField)
    {
        NSTimer.scheduledTimerWithTimeInterval(0.0, target: self, selector: "selectAll", userInfo: nil, repeats: false)
    }
    
    func selectAll()
    {
        self.linkTextField.becomeFirstResponder()
        self.linkTextField.selectedTextRange = self.linkTextField.textRangeFromPosition(self.linkTextField.beginningOfDocument, toPosition: self.linkTextField.endOfDocument)
        UIMenuController.sharedMenuController().setMenuVisible(false, animated: true)
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool
    {
        if linkTextField.text == ""
        {
            searchImage.hidden = false
            searchImage.frame = CGRectMake(72, 33, 14, 14)
            searchImage.image = UIImage(named: "URLMenuSearchMagnifier@2x.png")
            reloadButton.alpha = 0.0
            reloadButton.userInteractionEnabled = false
            stopLoadingButton.alpha = 0.0
            stopLoadingButton.userInteractionEnabled = false
        }
        
        var reachabilityStatus = IJReachability.isConnectedToNetwork()
        
        if reachabilityStatus == false
        {
            configureView("message", messageText: "Stainless cannot open the page because your device is not connected to the Internet.")
        }
        else
        {
            if examineReachabilityOfHost("google.com") == true
            {
                notConnected = false
                
                UIView.animateWithDuration(0.2, animations:
                    {
                        textField.frame = CGRectMake(textField.frame.origin.x, textField.frame.origin.y, textField.frame.size.width + 64, textField.frame.size.height)
                        
                        textField.textAlignment = NSTextAlignment.Center
                        
                        if !textField.isFirstResponder()
                        {
                            if self.webView.request != nil
                            {
                                var shortenedLinkArray = self.webView.request!.URL!.absoluteString!.componentsSeparatedByString("/")
                                
                                if shortenedLinkArray[2] != "www.google.com" && !shortenedLinkArray[3].hasPrefix("search")
                                {
                                    if shortenedLinkArray[2].hasPrefix("www.")
                                    {
                                        var linkWithoutWPrefixArray = shortenedLinkArray[2].componentsSeparatedByString("www.")
                                        
                                        textField.text = linkWithoutWPrefixArray[1]
                                    }
                                    else
                                    {
                                        textField.text = shortenedLinkArray[2]
                                    }
                                }
                                else if shortenedLinkArray[2] == "www.google.com" && shortenedLinkArray[3].hasPrefix("search")
                                {
                                    textField.text = self.webView.stringByEvaluatingJavaScriptFromString("document.getElementById('lst-ib').value")
                                }
                                else if shortenedLinkArray[2] == "www.google.com" && !shortenedLinkArray[3].hasPrefix("search")
                                {
                                    textField.text = "google.com"
                                }
                                
                                if textField.text == nil || textField.text == ""
                                {
                                    self.searchImage.hidden = false
                                    self.searchImage.frame = CGRectMake(72, 33, 14, 14)
                                    self.searchImage.image = UIImage(named: "URLMenuSearchMagnifier@2x.png")
                                }
                                else
                                {
                                    if shortenedLinkArray[0].hasPrefix("https")
                                    {
                                        if !self.linkTextField.isFirstResponder()
                                        {
                                            self.searchImage.hidden = false
                                            self.searchImage.frame = CGRectMake(15, 35.0, 8.67, 11.92125)
                                            self.searchImage.image = UIImage(named: "NavigationBarLock@2x.png")
                                        }
                                        
                                        self.isSecure = true
                                    }
                                    else
                                    {
                                        self.searchImage.hidden = true
                                        self.isSecure = false
                                    }
                                }
                            }
                        }
                        
                        self.cancelButton.hidden = true
                        self.cancelButton.userInteractionEnabled = false
                        
                        if self.webView.loading == false
                        {
                            UIView.animateWithDuration(0.2, delay: 0, options:UIViewAnimationOptions.CurveEaseOut, animations:
                                {() in
                                    if self.linkTextField.text != ""
                                    {
                                        self.reloadButton.alpha = 1.0
                                        self.reloadButton.userInteractionEnabled = true
                                        
                                        if self.webView.request != nil
                                        {
                                            var shortenedLinkArray = self.webView.request!.URL!.absoluteString!.componentsSeparatedByString("/")
                                            
                                            if shortenedLinkArray[0].hasPrefix("https") && !self.linkTextField.isFirstResponder()
                                            {
                                                self.searchImage.hidden = false
                                                self.searchImage.frame = CGRectMake(15, 35.0, 8.67, 11.92125)
                                                self.searchImage.image = UIImage(named: "NavigationBarLock@2x.png")
                                            }
                                        }
                                    }
                                },
                                completion: nil)
                        }
                })
            }
            else
            {
                self.notConnected = true
            }
        }
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        if notConnected == false
        {
            autoCompleteTableView.alpha = 0.0
            
            textField.resignFirstResponder()
            
            let validURLRegex = NSRegularExpression(pattern: "(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+",options: nil, error: nil)!
            
            if validURLRegex.firstMatchInString("http://\(textField.text)", options: nil, range: NSMakeRange(0, "http://\(textField.text)".length)) == nil
            {
                var urlToLoad = NSURL(string: "http://www.google.com/search?q=\(textField.text)".stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
                var networkRequest = NSURLRequest(URL: urlToLoad!)
                dispatch_async(dispatch_get_main_queue())
                    {
                        dispatch_async(dispatch_get_main_queue())
                            {
                                self.webView.loadRequest(networkRequest)
                        }
                }
            }
            else
            {
                var hostReachable = examineReachabilityOfHost(textField.text)
                
                if hostReachable == true
                {
                    if textField.text.hasPrefix("htt")
                    {
                        var urlToLoad = NSURL(string: "\(textField.text)")
                        var networkRequest = NSURLRequest(URL: urlToLoad!)
                        dispatch_async(dispatch_get_main_queue())
                            {
                                self.webView.loadRequest(networkRequest)
                        }
                    }
                    else
                    {
                        var urlToLoad = NSURL(string: "http://\(textField.text)")
                        var networkRequest = NSURLRequest(URL: urlToLoad!)
                        dispatch_async(dispatch_get_main_queue())
                            {
                                self.webView.loadRequest(networkRequest)
                        }
                    }
                }
                else
                {
                    configureView("message", messageText: "Stainless cannot open the page because the server cannot be found.")
                }
            }
        }
        else
        {
            configureView("message", messageText: "Stainless cannot open the page because your device is not connected to the Internet.")
            textField.resignFirstResponder()
            self.webView.stopLoading()
            
            UIView.animateWithDuration(0.2, animations:
                {
                    textField.frame = CGRectMake(textField.frame.origin.x, textField.frame.origin.y, textField.frame.size.width + 64, textField.frame.size.height)
                    
                    textField.textAlignment = NSTextAlignment.Center
                    
                    self.cancelButton.hidden = true
                    self.cancelButton.userInteractionEnabled = false
            })
        }
        return true
    }
}

extension ViewController : UITableViewDelegate
{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        if topHit != nil
        {
            return 2
        }
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0
        {
            return autoCompleteArray.count
        }
        
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let currentCell = tableView.dequeueReusableCellWithIdentifier("regularCell") as! SCE
        
        if indexPath.section == 0 && linkTextField.text != nil && linkTextField.text != ""
        {
            currentCell.titleLabel!.text = autoCompleteArray[indexPath.row]
        }
        else
        {
            if topHit != nil && linkTextField.text != nil && linkTextField.text != ""
            {
                currentCell.titleLabel!.text = topHit.pageTitle!
            }
        }
        
        return currentCell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if indexPath.section != 0
        {
            var urlToLoad = topHit.pageURL!
            var networkRequest = NSURLRequest(URL: urlToLoad)
            autoCompleteTableView.alpha = 0.0
            var tappedSuggestion = autoCompleteArray[indexPath.row]
            dispatch_async(dispatch_get_main_queue())
                {
                    dispatch_async(dispatch_get_main_queue())
                        {
                            self.webView.loadRequest(networkRequest)
                    }
            }
            autoCompleteArray.removeAll(keepCapacity: false)
            cancelButton(self)
            searchImage.hidden = true
            linkTextField.text = tappedSuggestion
        }
        else
        {
            var formattedURLString = "http://www.google.com/search?q=\(autoCompleteArray[indexPath.row]))".stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            formattedURLString = dropLast(formattedURLString)
            var urlToLoad = NSURL(string: formattedURLString)
            var networkRequest = NSURLRequest(URL: urlToLoad!)
            autoCompleteTableView.alpha = 0.0
            var tappedSuggestion = autoCompleteArray[indexPath.row]
            dispatch_async(dispatch_get_main_queue())
                {
                    dispatch_async(dispatch_get_main_queue())
                        {
                            self.webView.loadRequest(networkRequest)
                    }
            }
            autoCompleteArray.removeAll(keepCapacity: false)
            cancelButton(self)
            searchImage.hidden = true
            linkTextField.text = tappedSuggestion
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String
    {
        if section == 0
        {
            return "Google Search"
        }
        
        return "Top Hit"
    }
}

extension String
{
    var length: Int {return count(self)}
}
