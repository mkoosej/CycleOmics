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
    fileprivate let storeManager = CarePlanStoreManager.sharedCarePlanStoreManager
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet var applicationNameLabel: UILabel!
    var todayIndex:Int = 0
    var availableDates = 0
    var dates = [Date]()
    var URLs = [URL]()
    
    // MARK: Static Properties
    static var needsUpdate:Bool = true;
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize properties
        applicationNameLabel.text = "CycleOmics"
        //TODO: localize this
        nameLabel.text = getUserName()
        (self.dates,self.todayIndex) = Date.daysInThisWeek()
        self.availableDates = todayIndex + 1
        
        storeManager.delegate = self
        
        //Create reports for each day
        createReport()
        
        // Ensure the table view automatically sizes its rows.
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Create reports for each day
        createReport()
    }

    // MARK: UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // it's always equal to numberf of days in week
        return 7
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProfileStaticTableViewCell.reuseIdentifier, for: indexPath) as? ProfileStaticTableViewCell else { fatalError("Unable to dequeue a ProfileStaticTableViewCell") }
        
        let cellDate = dates[(indexPath as NSIndexPath).row]
        cell.titleLabel.text = cellDate.getLocalizedDayofWeek
        
        // TODO: check if it's been sent
        let hasSent = UserDefaults.standard.bool(forKey: dateStringFormatter(cellDate))
        cell.valueLabel.isHidden = !hasSent
        cell.sendBtn.isHidden = true

        // disable dates in the future
        let today = Date()
        switch cellDate.compare(today) {
            case .orderedAscending:
                cell.sendBtn.isEnabled = true
                cell.titleLabel.textColor = UIColor.black
            default:
                cell.sendBtn.isEnabled = false
                cell.titleLabel.textColor = UIColor.gray
        }
        
        // highlight today's row
        if (indexPath as NSIndexPath).row == todayIndex {
            cell.titleLabel.textColor = UIColor.red
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        previewPdf((indexPath as NSIndexPath).row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        let cellDate = dates[(indexPath as NSIndexPath).row]
        let today = Date()
        switch cellDate.compare(today) {
        case .orderedAscending:
            return true
        default:
            return false
        }
    }
    
    // MARK: Convenience
    fileprivate func getPersistenceDirectoryURL() -> URL {
        
        let searchPaths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let applicationSupportPath = searchPaths[0]
        let persistenceDirectoryURL = URL(fileURLWithPath: applicationSupportPath)
        
        if !FileManager.default.fileExists(atPath: persistenceDirectoryURL.absoluteString, isDirectory: nil) {
            try! FileManager.default.createDirectory(at: persistenceDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return persistenceDirectoryURL
    }
    
    // returns a key for saving date specefic values
    fileprivate func dateStringFormatter(_ date:Date)->String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    //MARK: Report
    fileprivate func createReport() {
        
        if ProfileViewController.needsUpdate == true {
            
            ProfileViewController.needsUpdate = false
        
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .long
            
            let reportBuilder = ReportsBuilder(carePlanStore: storeManager.store)
            
            for i in 0..<availableDates {
                let date = dates[i]
                
                let s = formatter.string(from: date)
                debugPrint("Creating report for date \(s)")
                
                if let doc = reportBuilder.createReport(forDay: date) {
                    
                    //store the pdf in memory
                    let pdfURL = generatePdfUrl(i)
                    doc.createPDFData(completion: { [weak self] (data : Data, error: Error?) in
                        // it's synchrous so we don't have to worry about it ( not sure :} )
                        if (try? data.write(to: pdfURL, options: [.atomic])) != nil {
                            self!.URLs.append(pdfURL)
                        }
                        else {
                            debugPrint("error in writing file \(pdfURL)")
                        }
                    })
                }
            }
        }
    }
    
    fileprivate func getUserName() -> String {
        let firstName = UserDefaults.standard.string(forKey: "givenName")!
        let lastName = UserDefaults.standard.string(forKey: "familyName")!
        return "\(firstName) \(lastName)"
    }
}

extension ProfileViewController: QLPreviewControllerDataSource {
    
    // MARK: QLPreviewControllerDataSource
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return availableDates;
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        
        // the pdf should exist and available on the disk ast this point
        return URLs[index] as QLPreviewItem
    }
    
    fileprivate func previewPdf(_ index:Int) {
        
        // start previewing the document at the current section index
        if QLPreviewController.canPreview(URLs[index] as QLPreviewItem) {
            let previewController = QLPreviewController()
            previewController.dataSource = self
            previewController.currentPreviewItemIndex = index
            DispatchQueue.main.async(execute: { //to prevent the unbalance call issue
                self.navigationController!.present(previewController, animated: true, completion: nil)
            })
        }
    }
    
    fileprivate func generatePdfUrl(_ index:Int)->URL {

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: dates[index])
        let user = getUserName()
        let fileName = "\(user)-\(dateString).pdf"
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    }
}

extension ProfileViewController: CarePlanStoreManagerDelegate {
    
    func forceUpdateReports() {
        ProfileViewController.needsUpdate = true
    }
}
