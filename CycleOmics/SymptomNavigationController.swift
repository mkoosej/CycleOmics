//
//  SymptomNavigationController.swift
//  CycleOmics
//
//  Created by Mojtaba Koosej on 6/23/16.
//  Copyright © 2016 Curio. All rights reserved.
//

import UIKit
import ResearchKit
import CareKit


class SymptomNavigationController: UINavigationController {
    
    private let storeManager = CarePlanStoreManager.sharedCarePlanStoreManager
    private let sampleData: SampleData
    private var symptomTrackerViewController: OCKSymptomTrackerViewController!

    required init?(coder aDecoder: NSCoder) {

        sampleData = SampleData(carePlanStore: storeManager.store)
        super.init(coder: aDecoder)
        
        symptomTrackerViewController = createSymptomTrackerViewController()

        self.pushViewController(symptomTrackerViewController, animated: true)        
    }
    
    private func createSymptomTrackerViewController() -> OCKSymptomTrackerViewController {
        let viewController = OCKSymptomTrackerViewController(carePlanStore: storeManager.store)
        viewController.delegate = self
        
        // Setup the controller's title and tab bar item
        viewController.title = NSLocalizedString("Symptom Tracker", comment: "")
        viewController.tabBarItem = UITabBarItem(title: viewController.title, image: UIImage(named:"symptoms"), selectedImage: UIImage(named: "symptoms-filled"))
        
        return viewController
    }
}


extension SymptomNavigationController: OCKSymptomTrackerViewControllerDelegate {
    
    /// Called when the user taps an assessment on the `OCKSymptomTrackerViewController`.
    func symptomTrackerViewController(viewController: OCKSymptomTrackerViewController, didSelectRowWithAssessmentEvent assessmentEvent: OCKCarePlanEvent) {
        
        // Lookup the assessment the row represents.
        guard let activityType = ActivityType(rawValue: assessmentEvent.activity.identifier) else { return }
        guard let sampleAssessment = sampleData.activityWithType(activityType) as? Assessment else { return }
        
        /*
         Check if we should show a task for the selected assessment event
         based on its state.
         */
        guard assessmentEvent.state == .Initial ||
            assessmentEvent.state == .NotCompleted ||
            (assessmentEvent.state == .Completed && assessmentEvent.activity.resultResettable) else { return }
        
        // Show an `ORKTaskViewController` for the assessment's task.
        let taskViewController = ORKTaskViewController(task: sampleAssessment.task(), taskRunUUID: nil)
        taskViewController.delegate = self
        
        presentViewController(taskViewController, animated: true, completion: nil)
    }
}


extension SymptomNavigationController: ORKTaskViewControllerDelegate {
    
    /// Called with then user completes a presented `ORKTaskViewController`.
    func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        
        defer {
            dismissViewControllerAnimated(true, completion: nil)
        }
        
        // Make sure the reason the task controller finished is that it was completed.
        guard reason == .Completed else {
            debugPrint("The task with id \(taskViewController.task?.identifier) has been canceled")
            return
        }
        
        // Determine the event that was completed and the `SampleAssessment` it represents.
        guard let event = symptomTrackerViewController.lastSelectedAssessmentEvent,
            activityType = ActivityType(rawValue: event.activity.identifier),
            sampleAssessment = sampleData.activityWithType(activityType) as? Assessment else {
                debugPrint("Error in capturing even values")
                return
        }
        
        guard let date = NSCalendar.currentCalendar().dateFromComponents(event.date) else {
            debugPrint("Error in capturing even date")
            return
        }
        
        // Check assessment can be associated with a HealthKit sample.
        if let healthSampleBuilder = sampleAssessment as? HealthQuantitySampleBuilder {
            // Build the sample to save in the HealthKit store.
            
            let sample = healthSampleBuilder.buildSampleWithTaskResult(taskViewController.result, date: date)
            let sampleTypes: Set<HKSampleType> = [sample.sampleType]
            
            let carePlanResult = sampleAssessment.buildResultForCarePlanEvent(event, taskResult: taskViewController.result)
            
            //Save the quantity sample to HKStore
            saveSampleHealthStore(sampleTypes, sample: sample, event: event, carePlanResult: carePlanResult, completionBlock: {
                
                //Save the quantity sample to CarePlanStore  
                let healthKitAssociatedResult = OCKCarePlanEventResult(
                    quantitySample: sample,
                    quantityStringFormatter: healthSampleBuilder.quantityStringFormatter,
                    displayUnit: healthSampleBuilder.unit,
                    displayUnitStringKey: healthSampleBuilder.localizedUnitForSample(sample),
                    userInfo: nil
                )
                
                self.completeEvent(event, inStore: self.storeManager.store, withResult: healthKitAssociatedResult)
            })
        }
        else if let healthSampleBuilder = sampleAssessment as? HealthCategorySampleBuilder {
            // Build the sample to save in the HealthKit store.
            
            if(healthSampleBuilder.shouldIgnoreSample(taskViewController.result)) { //for conditional tasks that doesn't require sampling
                
                let carePlanResult = sampleAssessment.buildResultForCarePlanEvent(event, taskResult: taskViewController.result)
                self.completeEvent(event, inStore: self.storeManager.store, withResult: carePlanResult)
                return
            }
            
            let sample = healthSampleBuilder.buildSampleWithTaskResult(taskViewController.result,date: date)
            let sampleTypes: Set<HKSampleType> = [sample.sampleType]
            let carePlanResult = sampleAssessment.buildResultForCarePlanEvent(event, taskResult: taskViewController.result)
            
            //Save the category sample to HKStore
            saveSampleHealthStore(sampleTypes, sample: sample, event: event, carePlanResult: carePlanResult, completionBlock: {
                
                self.completeEvent(event, inStore: self.storeManager.store, withResult: carePlanResult)
            })
        }
        else {
            // Update the event with the result.
            
            // Build an `OCKCarePlanEventResult` that can be saved into the `OCKCarePlanStore`.
            let carePlanResult = sampleAssessment.buildResultForCarePlanEvent(event, taskResult: taskViewController.result)
            completeEvent(event, inStore: storeManager.store, withResult: carePlanResult)
        }
    }
    
    // MARK: Convenience
    
    private func completeEvent(event: OCKCarePlanEvent, inStore store: OCKCarePlanStore, withResult result: OCKCarePlanEventResult) {
        store.updateEvent(event, withResult: result, state: .Completed) { success, _, error in
            if !success {
                debugPrint(error?.localizedDescription)
            }
        }
    }
    
    private func saveSampleHealthStore(sampleTypes: Set<HKSampleType>, sample: HKSample, event: OCKCarePlanEvent , carePlanResult: OCKCarePlanEventResult , completionBlock: (Void)->Void ) {
        
        // Requst authorization to store the HealthKit sample.
        let healthStore = HKHealthStore()
        healthStore.requestAuthorizationToShareTypes(sampleTypes, readTypes: sampleTypes, completion: { success, _ in
            // Check if authorization was granted.
            if !success {
                /*
                 Fall back to saving the simple `OCKCarePlanEventResult`
                 in the `OCKCarePlanStore`.
                 */
                self.completeEvent(event, inStore: self.storeManager.store, withResult: carePlanResult)
                return
            }
            
            // Save the HealthKit sample in the HealthKit store.
            healthStore.saveObject(sample, withCompletion: { success, _ in
                if success {
                    completionBlock()
                }
                else {
                    /*
                     Fall back to saving the simple `OCKCarePlanEventResult`
                     in the `OCKCarePlanStore`.
                     */
                    self.completeEvent(event, inStore: self.storeManager.store, withResult: carePlanResult)
                }
            })
        })
    }
}
