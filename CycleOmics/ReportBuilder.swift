//
//  ReportBuilder.swift
//  CycleOmics
//
//  Created by Mojtaba Koosej on 8/4/16.
//  Copyright © 2016 Curio. All rights reserved.
//

import Foundation
import CareKit

class ReportsBuilder {
    
    private let carePlanStore: OCKCarePlanStore
            
    required init(carePlanStore: OCKCarePlanStore) {
        self.carePlanStore = carePlanStore
    }
    
    func createReport(forDay day:NSDate)->OCKDocument? {
        
        var elements = [OCKDocumentElement]()
        
        let firstName = NSUserDefaults.standardUserDefaults().stringForKey("givenName")!
        let lastName = NSUserDefaults.standardUserDefaults().stringForKey("familyName")!
        let userName = "\(firstName) \(lastName)"
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = .FullStyle
        
        // Structure the pdf document using the result's data
        var title = "Daily Report"
        title += "\nDate: \(formatter.stringFromDate(day))"
        title += "\nParticipant: \(userName)"
        
        //create date ranges for the day (whole day date range)
        let formatter2 = NSDateFormatter()
        formatter2.dateStyle = .LongStyle
        formatter2.timeStyle = .LongStyle
        
        let s = formatter2.stringFromDate(day.startOfDay)
        let e = formatter2.stringFromDate(day.endOfDay!)
        debugPrint("The date range: \(s) - \(e)")
        
        // The report creation starts here
        // 1. Query for the data
        // 2. create pdf using the result set
        // 3. inform other VC and send it back for preview
        
        let activityQuery = ActivityQuery(carePlanStore: carePlanStore);
        activityQuery.Query(day.startOfDayComponent, endDate: day.endOfDayComponent)
        
        let assesmentQuery = AssesmentQuery(carePlanStore: carePlanStore);
        assesmentQuery.Query(day.startOfDayComponent, endDate: day.endOfDayComponent)
        
        
        // Collecting data for sample tube entries
        let activityHeaders = ["Sample Type" , "Tube Number"]
        var activityResults = [[String]]()
        for ( activityId, event ) in activityQuery.results {
            
            if let activity = ActivityType(rawValue: activityId) {
                if let result = event.result {
                    activityResults.append([ activity.localizedName, result.valueString])
                }
                else {
                    activityResults.append([ activity.localizedName, ""])
                }
            }
        }
        let activityTable = OCKDocumentElementTable(headers: activityHeaders, rows: activityResults)
        elements.append(activityTable)
        
        // Collecting data for assesment entries
        var assesmentResults = [[String]]()
        let assesmentHeaders = ["Assesment", "Results"]
        var stressEvent:OCKCarePlanEvent?
        var noteEvent:OCKCarePlanEvent?
        
        for ( assesmentId, event ) in assesmentQuery.results {
            
            if let activity = ActivityType(rawValue: assesmentId) {
                
                switch activity {
                    case .CervicalMucus:
                        assesmentResults.append(mucusRow(activity, event: event))
                    case .SexualActivities:
                        assesmentResults.append(sexualRow(activity, event: event))
                    case .Sleep:
                        assesmentResults.append(sleepRow(activity, event: event))
                    case .Stress:
                        stressEvent = event
                        continue //separate table
                    case .Notes:
                        noteEvent = event
                        continue //separate paragraph
                    default:
                        assesmentResults.append(valueRow(activity, event: event))
                }
            }
        }
        let assesmentsTable = OCKDocumentElementTable(headers: assesmentHeaders, rows: assesmentResults)
        elements.append(assesmentsTable)
        
        if(noteEvent != nil) {
            if let noteParag = noteParagraph(.Notes, event: noteEvent!) {
                elements.append(noteParag)
            }
        }
        
        elements.append(OCKDocumentElementParagraph(content: "<p style='page-break-after:always;'> </p>"))
        
        // Daily Stress Survey table
        if stressEvent != nil {
            if let stresssTable = self.stressTable(.Stress, event: stressEvent!) {
                elements.append(OCKDocumentElementParagraph(content:"<b>Daily Stress Survey:</b>"))
                elements.append(stresssTable)
            }
        }
        
        // Create PDF
        let document = OCKDocument(title: title, elements: elements)
        document.pageHeader = "CycleOmics, Participant: \(userName), \(formatter.stringFromDate(day))"
        
        return document
        
        // TODO: you can move it in another thread but the query should run on main thread
        // and the user is waiting for preview anyways
        // it makes sense to block the thread and only have an option for cancelling the operation
    }
    
    //MARK: value results

    private func valueRow(activity:ActivityType, event:OCKCarePlanEvent) -> [String] {
        
        if let result = event.result {
            return [activity.localizedName, result.valueString]
        }
        else {
            return [activity.localizedName, ""]
        }
    }


    //MARK: categorical results

    private func sleepRow(activity:ActivityType, event:OCKCarePlanEvent) -> [String] {
        
        if let result = event.result {
            if let categorySample = result.sample as? HKCategorySample {
                let startDate = categorySample.startDate
                let endDate = categorySample.endDate
                //calculate hours difference
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateStyle = .ShortStyle
                dateFormatter.timeStyle = .ShortStyle
                
                let difference = endDate.timeIntervalSinceDate(startDate)
                let hours = String(format: "%02d", Int(difference) / 3600)
                let minutes = String(format: "%02d", (Int(difference) / 60) % 60)
                
                var text = "\(hours):\(minutes)\n"
                text += "\(dateFormatter.stringFromDate(startDate)) - \(dateFormatter.stringFromDate(endDate)) "
                debugPrint(text)
                
                return [activity.localizedName, text ]
            }
        }
        
        return [activity.localizedName, ""]
    }

    private func sexualRow(activity:ActivityType, event:OCKCarePlanEvent) -> [String] {
        
        if let result = event.result {
            if let categorySample = result.sample as? HKCategorySample {
                let protectionUsed = Bool(categorySample.metadata!["HKSexualActivityProtectionUsed"] as! Int)
                let date = categorySample.startDate
                
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateStyle = .ShortStyle
                dateFormatter.timeStyle = .ShortStyle
                
                let dateString = dateFormatter.stringFromDate(date)
                
                //date_formatter + protection used
                var text = ""
                if protectionUsed == true {
                    text += "Protection used"
                }
                else {
                    text += "Protection not used"
                }
                text += "\n\(dateString)"
                
                debugPrint(text)
                
                return [activity.localizedName, text]
            }
        }
        
        return [activity.localizedName, "-"]
    }

    private func mucusRow(activity:ActivityType, event:OCKCarePlanEvent) -> [String] {
        
        if let result = event.result {
            if let categorySample = result.sample as? HKCategorySample {
                return [activity.localizedName, CervicalMucus.valueStrings[categorySample.value]! ]
            }
        }
        
        return [activity.localizedName, ""]
    }
    
    //MARK: custom results
    
    private func noteRow(activity:ActivityType, event:OCKCarePlanEvent) -> [String] {
        
        if let result = event.result, userInfo = result.userInfo {
            return [activity.localizedName, userInfo["note"] as! String]
        }
        else {
            return [activity.localizedName, ""]
        }
    }
    
    private func noteParagraph(activity:ActivityType, event:OCKCarePlanEvent) -> OCKDocumentElementParagraph? {
        
        if let result = event.result, userInfo = result.userInfo {
            if var content =  userInfo["note"] as? String   {
               
                if(!content.isEmpty) {
                    
                    content = "<b>Extra Notes:</b>\n" + content
                    return OCKDocumentElementParagraph(content: content)
                }
            }
        }
        
        return nil;
        
    }
    
    private func stressTable(activity:ActivityType, event:OCKCarePlanEvent) -> OCKDocumentElementTable? {
        
        var rows = [[String]]()
        let headers = ["Question", "Answer"]
        
        guard let userInfo = event.result?.userInfo else { return nil }
        for (index,value) in userInfo.values.enumerate() {
            
            let intValue = value as! Int
            var row = [String]()
            row.append("<span style='padding-right:5em; text-align:left !important'>\(Stress.questions[index])</right>");
            row.append("\(intValue)")
            
            rows.append(row)
        }
        
        //navigate the results collection and fill in the table rows with X
       
        return OCKDocumentElementTable(headers: headers, rows: rows)
    }

}