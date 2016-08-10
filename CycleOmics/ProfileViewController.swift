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
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet var applicationNameLabel: UILabel!
    var todayIndex:Int = 0
    var dates:[NSDate] = []
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize properties
        applicationNameLabel.text = "CycleOmics"
        let firstName = NSUserDefaults.standardUserDefaults().stringForKey("givenName")!
        let lastName = NSUserDefaults.standardUserDefaults().stringForKey("familyName")!
        //TODO: localize this
        nameLabel.text = "\(firstName) \(lastName)"
        self.dates = daysInThisWeek()
        
        // Ensure the table view automatically sizes its rows.
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    // MARK: UITableViewDataSource
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // it's always equal to numberf of days in week
        return 7
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCellWithIdentifier(ProfileStaticTableViewCell.reuseIdentifier, forIndexPath: indexPath) as? ProfileStaticTableViewCell else { fatalError("Unable to dequeue a ProfileStaticTableViewCell") }
        
        let cellDate = dates[indexPath.row]
        cell.titleLabel.text = getLocalizedDayofWeek(cellDate)
        
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
        
        let date = dates[indexPath.row]
        previewPdf(date)
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

    private func daysInThisWeek() -> [NSDate] {
        // create calendar
        let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
        
        // today's date
        let today = NSDate()
        let todayComponent = calendar.components([.Day, .Month, .Year], fromDate: today)
        
        
        // range of dates in this week
        let thisWeekDateRange = calendar.rangeOfUnit(.Day, inUnit:.WeekOfMonth, forDate:today)
        
        // date interval from today to beginning of week
        let dayInterval = thisWeekDateRange.location - todayComponent.day
        
        // date for beginning day of this week, ie. this week's Sunday's date
        let beginningOfWeek = calendar.dateByAddingUnit(.Day, value: dayInterval, toDate: today, options: .MatchNextTime)
        
        var dates: [NSDate] = []
        
        // to include days of the week belongs to past month
        // we should always have 7 days
        for i in (thisWeekDateRange.length-7) ..< thisWeekDateRange.length {
            let date = calendar.dateByAddingUnit(.Day, value: i, toDate: beginningOfWeek!, options: .MatchNextTime)!
            dates.append(date)
        }
        
        todayIndex = -(dayInterval + (thisWeekDateRange.length-7))
        
        return dates
    }

    private func getLocalizedDayofWeek(date:NSDate)->String {
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let dayOfWeekString = dateFormatter.stringFromDate(date)
        
        return dayOfWeekString
    }
    
    // returns a key for saving date specefic values
    private func dateStringFormatter(date:NSDate)->String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.stringFromDate(date)
    }
}

extension ProfileViewController: QLPreviewControllerDataSource, UIDocumentInteractionControllerDelegate {
    
    // MARK: QLPreviewControllerDataSource
    func numberOfPreviewItemsInPreviewController(controller: QLPreviewController) -> Int {
        return 1;
    }
    
    func previewController(controller: QLPreviewController, previewItemAtIndex index: Int) -> QLPreviewItem {
        
        // convert index to date
        let date = NSDate()
        
        //        // create report for the date
        //        let name = "Mojtaba Koosej \(index)"
        //        let document = OCKDocument(title: name, elements: [])
        
        let sharedManager = CarePlanStoreManager.sharedCarePlanStoreManager
        let reportBuilder = ReportsBuilder(carePlanStore: sharedManager.store)
        var document:OCKDocument?
        reportBuilder.createReport(forDay: date) { (success, generatedDoc) in
            
            if(success) {
                document = generatedDoc!
            }
            else {
                //raise error
            }
        }
        
        let fileName = "Sample1.pdf"
        let pdfURL = getPersistenceDirectoryURL().URLByAppendingPathComponent(fileName)
        //
        //        document!.createPDFDataWithCompletion { (data : NSData, error: NSError?) in
        //            try! data.writeToURL(pdfURL, options: .AtomicWrite)
        //        }
        
        return pdfURL
    }
    
    private func previewPdf(date:NSDate) {
        
        let previewController = QLPreviewController()
        previewController.dataSource = self;
        
        // start previewing the document at the current section index
        self.navigationController!.presentViewController(previewController, animated: true, completion: nil)
    }
}
