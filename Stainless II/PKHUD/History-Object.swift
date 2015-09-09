//
//  History-Object.swift
//  
//
//  Created by Grant Goodman on 8/26/15.
//
//

import UIKit

class HistoryObject: NSObject
{
    var pageTitle: String! = ""
    var pageURL: NSURL!
    
    init(pageTitle : String, pageURL : NSURL)
    {
        self.pageTitle = pageTitle
        self.pageURL = pageURL
    }
}
