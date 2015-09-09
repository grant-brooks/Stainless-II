//
//  History-Controller.swift
//  
//
//  Created by Grant Goodman on 8/26/15.
//
//

import UIKit

class HC: UIViewController
{
    var historyArray = [HistoryObject]()
    var selectedIndexPath: NSIndexPath!
    var previouslySelectedLink: NSURL!
    var deletedCurrent: Bool!
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var historyTableView: UITableView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        deletedCurrent = false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "selectLinkSegue"
        {
            var destinationController = segue.destinationViewController as! ViewController
            
            destinationController.selectedLink = historyArray[selectedIndexPath.row]
//            
            if deletedCurrent == false
            {
                destinationController.previousURL = previouslySelectedLink
            }
            
            destinationController.historyArray = historyArray
        }
        
        if segue.identifier == "doneButtonSegue"
        {
            var destinationController = segue.destinationViewController as! ViewController
            
            if deletedCurrent == false
            {
                destinationController.previousURL = previouslySelectedLink
            }
            
            destinationController.historyArray = historyArray
        }
    }
    
    @IBAction func doneButton(sender: AnyObject)
    {
        performSegueWithIdentifier("doneButtonSegue", sender: self)
    }
}

extension HC : UITableViewDelegate
{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return historyArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let currentCell = tableView.dequeueReusableCellWithIdentifier("historyCell") as! HCE
        
        currentCell.titleLabel.text = historyArray[indexPath.row].pageTitle!
        
        var urlAsString = "\(historyArray[indexPath.row].pageURL!)"
        currentCell.subtitleLabel.text = urlAsString
        
        return currentCell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        selectedIndexPath = indexPath
        
        performSegueWithIdentifier("selectLinkSegue", sender: self)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if editingStyle == UITableViewCellEditingStyle.Delete
        {
            if previouslySelectedLink == historyArray[indexPath.row].pageURL
            {
                previouslySelectedLink == NSURL(string:"about:blank")
                deletedCurrent = true
            }
            
            historyArray.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
}
