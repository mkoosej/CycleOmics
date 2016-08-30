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
        
        //create date ranges for the day (whole day date range)
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        formatter.timeStyle = .LongStyle
        
        let s = formatter.stringFromDate(day.startOfDay)
        let e = formatter.stringFromDate(day.endOfDay!)
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
        
        
        // Collecting data for assesment entries
        var assesmentResults = [[String]]()
        let assesmentHeaders = ["Assesment", "Results"]
        
        for ( assesmentId, event ) in assesmentQuery.results {
            
            if let activity = ActivityType(rawValue: assesmentId) {
                
                switch activity {
                    case .CervicalMucus:
                        assesmentResults.append(mucusRow(activity, event: event))
                    case .SexualActivities:
                        assesmentResults.append(sexualRow(activity, event: event))
                    case .Sleep:
                        assesmentResults.append(sleepRow(activity, event: event))
                    default:
                        assesmentResults.append(valueRow(activity, event: event))
                }
            }
        }
        let assesmentsTable = OCKDocumentElementTable(headers: assesmentHeaders, rows: assesmentResults)
        
        // Structure the pdf document using the result's data
        let title = "Report of the Day"
        let paragraph = OCKDocumentElementParagraph(content: "")
        
        // Create PDF
        let document = OCKDocument(title: title, elements: [paragraph, activityTable, assesmentsTable])
        let firstName = NSUserDefaults.standardUserDefaults().stringForKey("givenName")!
        let lastName = NSUserDefaults.standardUserDefaults().stringForKey("familyName")!
        let userName = "\(firstName) \(lastName)"
        document.pageHeader = "Research: CycleOmics, User Name: \(userName)"
        
        return document
        
        // TODO: you can move it in another thread but the query should run on main thread
        // and the user is waiting for preview anyways
        // it makes sense to block the thread and only have an option for cancelling the operation
      }

    private func valueRow(activity:ActivityType, event:OCKCarePlanEvent) -> [String] {
        
        if let result = event.result {
            return [activity.localizedName, result.valueString]
        }
        else {
            return [activity.localizedName, ""]
        }
    }

    private func sleepRow(activity:ActivityType, event:OCKCarePlanEvent) -> [String] {
        
        if let result = event.result {
            return [activity.localizedName, result.valueString]
        }
        else {
            return [activity.localizedName, ""]
        }
    }

    private func sexualRow(activity:ActivityType, event:OCKCarePlanEvent) -> [String] {
        
        if let result = event.result {
            return [activity.localizedName, result.valueString]
        }
        else {
            return [activity.localizedName, ""]
        }
    }
    
    private func mucusRow(activity:ActivityType, event:OCKCarePlanEvent) -> [String] {
        
        if let result = event.result {
            return [activity.localizedName, result.valueString]
        }
        else {
            return [activity.localizedName, ""]
        }
    }
}