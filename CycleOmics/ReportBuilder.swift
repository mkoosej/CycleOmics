//
//  ReportBuilder.swift
//  CycleOmics
//
//  Created by Mojtaba Koosej on 8/4/16.
//  Copyright © 2016 Curio. All rights reserved.
//

import Foundation
import CareKit


class ReportBuilder {
    
    // MARK: properties
    private let carePlanStore: OCKCarePlanStore
    private let updateOperationQueue = NSOperationQueue()
    
    required init(carePlanStore: OCKCarePlanStore) {
        self.carePlanStore = carePlanStore
    }
    
    func reportForDate(date: NSDate)->OCKDocument {
        
        let title = "Report of the Day"
        let subtitle = OCKDocumentElementSubtitle(subtitle: "First subtitle")
        
        let paragraph = OCKDocumentElementParagraph(content: "Hello")
        
        // Sample Table
        let activityHeaders = ["Sample" , "Tube Number"]
        //Query the store for sample types
        let activityResults = self.getEnumaratedResultForActivities(date, activities:
            [.Saliva, .FingerBloodSpot , .VaginalSwab, .Urine , .Stool ])
        let activityTable = OCKDocumentElementTable(headers: activityHeaders, rows: activityResults)
        
        // Symptom Table
        let assesmentHeaders = ["Symptoms" , "", ""]
        //Query the store for symptom types
        let assesmentResults = getEnumaratedResultForActivities(date , activities:
            [.Saliva ,.Stool ,.FingerBloodSpot,.Urine, .VaginalSwab ])
        let assesmentsTable = OCKDocumentElementTable(headers: assesmentHeaders, rows: assesmentResults)
        
        
        let document = OCKDocument(title: title, elements: [subtitle, paragraph, activityTable, assesmentsTable])
        
        let userName = "Mojtab Koosej"
        document.pageHeader = "Research: CycleOmics, User Name: \(userName)"
        
        return document
    }
    
    private func getEnumaratedResultForActivities(date:NSDate, activities: [ActivityType]) -> [[String]]? {
        
        let calendar = NSCalendar.currentCalendar()
        let start = NSDateComponents(date: date.startOfDay, calendar: calendar)
        let end = NSDateComponents(date: date.endOfDay!, calendar: calendar)
        
        var results: [[String]] = []
        for activityId in activities {
        
            let activity = findActivity(withIdentifer: activityId)!
            
            carePlanStore.enumerateEventsOfActivity(
                activity,
                startDate: start,
                endDate: end,
                handler: { event,pointer in
                    
                    if(event?.state == .Completed) {
                        
                        // if it's a sampling activity , just add the tube number
                        if let value = event?.result?.valueString {
                            results.append([value])
                        }
                        // if it's a symptom add the respected value
                        else {
                            
                        }
                    }
                
                }, completion: { success,error in
                
            })
        }
        
        return results
    }
    
    private func findActivity(withIdentifer identifier:ActivityType) -> OCKCarePlanActivity? {
        
        /*
         Create a semaphore to wait for the asynchronous call to `activityForIdentifier`
         to complete.
         */
        let semaphore = dispatch_semaphore_create(0)
        
        var activity: OCKCarePlanActivity?
        
        dispatch_async(dispatch_get_main_queue()) { // <rdar://problem/25528295> [CK] OCKCarePlanStore query methods crash if not called on the main thread
            self.carePlanStore.activityForIdentifier(identifier.rawValue) { success, foundActivity, error in
                activity = foundActivity
                if !success {
                    print(error?.localizedDescription)
                }
                
                // Use the semaphore to signal that the query is complete.
                dispatch_semaphore_signal(semaphore)
            }
        }
        
        // Wait for the semaphore to be signalled.
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        return activity
    }
}