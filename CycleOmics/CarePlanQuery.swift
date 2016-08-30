//
//  CarePlanQuery.swift
//  CycleOmics
//
//  Created by Mojtaba Koosej on 8/25/16.
//  Copyright © 2016 Curio. All rights reserved.
//

import Foundation
import CareKit

protocol CarePlanQuery : class {
    
    var store: OCKCarePlanStore { get }
    var activities: [ActivityType] { get }
    var results:[String:OCKCarePlanEvent] { get set}
}


extension CarePlanQuery {
    
    func findActivity(activityIdentifier:String) -> OCKCarePlanActivity? {
        
        /*
         Create a semaphore to wait for the asynchronous call to `activityForIdentifier`
         to complete.
         */
        let semaphore = dispatch_semaphore_create(0)
        
        var activity: OCKCarePlanActivity?
        
        
        self.store.activityForIdentifier(activityIdentifier) { success, foundActivity, error in
            activity = foundActivity
            
            if !success {
                debugPrint(error?.localizedDescription)
            }
            
            // Use the semaphore to signal that the query is complete.
            dispatch_semaphore_signal(semaphore)
        }
        
        // Wait for the semaphore to be signalled.
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        return activity
    }
    
    func Query(startDate:NSDateComponents, endDate:NSDateComponents) {
        
        //Do this for each acitivy
        debugPrint("=======================================")
        
        for ac in activities {
            
            debugPrint("Querying for \(ac.rawValue) activity")
            
            // Find the activity with the specified identifier in the store.
            guard let activity = findActivity(ac.rawValue) else { return}
            
            /*
             Create a semaphore to wait for the asynchronous call to `enumerateEventsOfActivity`
             to complete.
             */
            let semaphore = dispatch_semaphore_create(0)
            
            // Query for events for the activity between the requested dates.
            //            self.dailyEvents = DailyEvents()
            
            self.store.enumerateEventsOfActivity(activity, startDate: startDate, endDate: endDate, handler: { [unowned self] event, _  in
                
                if let event = event {
                    
                    self.results[ac.rawValue] = event
                    
                    
                    //add the extracted value to result set if it exists
                    if let value = event.result?.valueString {
                        
                        debugPrint("\(value)\n")
                    }
                    
                    
                } }, completion: { _, _ in
                    // Use the semaphore to signal that the query is complete.
                    dispatch_semaphore_signal(semaphore)
            })
            
            // Wait for the semaphore to be signalled.
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
        
        debugPrint("=============================================")
    }
}

