//
//  SymptomNavigationController.swift
//  CycleOmics
//
//  Created by Mojtaba Koosej on 6/23/16.
//  Copyright © 2016 Curio. All rights reserved.
//

import UIKit
import ResearchKit
import HealthKit
import CareKit
import QuickLook

class ProfileViewController: UITableViewController {
    
    // MARK: Properties
    private let storeManager = CarePlanStoreManager.sharedCarePlanStoreManager
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet var applicationNameLabel: UILabel!
    var todayIndex:Int = 0
    var availableDates = 0
    var dates = [NSDate]()
    var URLs = [NSURL]()
    
    // MARK: Static Properties
    static var needsUpdate:Bool = true;
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize properties
        applicationNameLabel.text = "CycleOmics"
        //TODO: localize this
        nameLabel.text = getUserName()
        (self.dates,self.todayIndex) = NSDate.daysInThisWeek()
        self.availableDates = todayIndex + 1
        
        storeManager.delegate = self
        
        //Create reports for each day
        createReport()
        
        // Ensure the table view automatically sizes its rows.
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //Create reports for each day
        createReport()
    }

    // MARK: UITableViewDataSource
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // it's always equal to numberf of days in week
        return 7
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCellWithIdentifier(ProfileStaticTableViewCell.reuseIdentifier, forIndexPath: indexPath) as? ProfileStaticTableViewCell else { fatalError("Unable to dequeue a ProfileStaticTableViewCell") }
        
        let cellDate = dates[indexPath.row]
        cell.titleLabel.text = cellDate.getLocalizedDayofWeek
        
        // TODO: check if it's been sent
        let hasSent = NSUserDefaults.standardUserDefaults().boolForKey(dateStringFormatter(cellDate))
        cell.valueLabel.hidden = !hasSent
        cell.sendBtn.hidden = true

        // disable dates in the future
        let today = NSDate()
        switch cellDate.compare(today) {
            case .OrderedAscending:
                cell.sendBtn.enabled = true
                cell.titleLabel.textColor = UIColor.blackColor()
            default:
                cell.sendBtn.enabled = false
                cell.titleLabel.textColor = UIColor.grayColor()
        }
        
        // highlight today's row
        if indexPath.row == todayIndex {
            cell.titleLabel.textColor = UIColor.redColor()
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        previewPdf(indexPath.row)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        let cellDate = dates[indexPath.row]
        let today = NSDate()
        switch cellDate.compare(today) {
        case .OrderedAscending:
            return true
        default:
            return false
        }
    }
    
    // MARK: Convenience
    private func getPersistenceDirectoryURL() -> NSURL {
        
        let searchPaths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)
        let applicationSupportPath = searchPaths[0]
        let persistenceDirectoryURL = NSURL(fileURLWithPath: applicationSupportPath)
        
        if !NSFileManager.defaultManager().fileExistsAtPath(persistenceDirectoryURL.absoluteString, isDirectory: nil) {
            try! NSFileManager.defaultManager().createDirectoryAtURL(persistenceDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return persistenceDirectoryURL
    }
    
    // returns a key for saving date specefic values
    private func dateStringFormatter(date:NSDate)->String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.stringFromDate(date)
    }
    
    //MARK: Report
    private func createReport() {
        
        if ProfileViewController.needsUpdate == true {
            
            ProfileViewController.needsUpdate = false
        
            let formatter = NSDateFormatter()
            formatter.dateStyle = .LongStyle
            formatter.timeStyle = .LongStyle
            
            let reportBuilder = ReportsBuilder(carePlanStore: storeManager.store)
            
            for i in 0..<availableDates {
                let date = dates[i]
                
                let s = formatter.stringFromDate(date)
                debugPrint("Creating report for date \(s)")
                
                if let doc = reportBuilder.createReport(forDay: date) {
                    
                    //store the pdf in memory
                    let pdfURL = generatePdfUrl(i)
                    doc.createPDFDataWithCompletion { [weak self] (data : NSData, error: NSError?) in
                        // it's synchrous so we don't have to worry about it ( not sure :} )
                        if data.writeToURL(pdfURL, atomically: true) {
                            self!.URLs.append(pdfURL)
                        }
                        else {
                            debugPrint("error in writing file \(pdfURL)")
                        }
                    }
                }
            }
        }
    }
    
    private func getUserName() -> String {
        let firstName = NSUserDefaults.standardUserDefaults().stringForKey("givenName")!
        let lastName = NSUserDefaults.standardUserDefaults().stringForKey("familyName")!
        return "\(firstName) \(lastName)"
    }
}

extension ProfileViewController: QLPreviewControllerDataSource {
    
    // MARK: QLPreviewControllerDataSource
    func numberOfPreviewItemsInPreviewController(controller: QLPreviewController) -> Int {
        return availableDates;
    }
    
    func previewController(controller: QLPreviewController, previewItemAtIndex index: Int) -> QLPreviewItem {
        
        // the pdf should exist and available on the disk ast this point
        return URLs[index]
    }
    
    private func previewPdf(index:Int) {
        
        // start previewing the document at the current section index
        if QLPreviewController.canPreviewItem(URLs[index]) {
            let previewController = QLPreviewController()
            previewController.dataSource = self
            previewController.currentPreviewItemIndex = index
            dispatch_async(dispatch_get_main_queue(), { //to prevent the unbalance call issue
                self.navigationController!.presentViewController(previewController, animated: true, completion: nil)
            })
        }
    }
    
    private func generatePdfUrl(index:Int)->NSURL {

        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        let dateString = formatter.stringFromDate(dates[index])
        let user = getUserName()
        let fileName = "\(user)-\(dateString).pdf"
        return NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(fileName)
    }
}

extension ProfileViewController: CarePlanStoreManagerDelegate {
    
    func forceUpdateReports() {
        ProfileViewController.needsUpdate = true
    }
}
