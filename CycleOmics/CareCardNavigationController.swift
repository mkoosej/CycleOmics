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


class CareCardNavigationController: UINavigationController {
    
    private let storeManager = CarePlanStoreManager.sharedCarePlanStoreManager
    private let sampleData: SampleData
    private var careCardViewController: OCKCareCardViewController!
    private var shouldComplete = true
    private var lastInterventionEvent:OCKCarePlanEvent?
    
    required init?(coder aDecoder: NSCoder) {
        
        sampleData = SampleData(carePlanStore: storeManager.store)
        super.init(coder: aDecoder)
        
        careCardViewController = createCareCardViewController()
        careCardViewController.delegate = self
        
        self.pushViewController(careCardViewController, animated: true)
    }
    
    private func createCareCardViewController() -> OCKCareCardViewController {
        let viewController = OCKCareCardViewController(carePlanStore: storeManager.store)
        
        // Setup the controller's title and tab bar item
        viewController.title = NSLocalizedString("Care Card", comment: "")
        viewController.tabBarItem = UITabBarItem(title: viewController.title, image: UIImage(named:"carecard"), selectedImage: UIImage(named: "carecard-filled"))
        viewController.delegate = self
        
        return viewController
    }
}

extension CareCardNavigationController: OCKCareCardViewControllerDelegate {
    
    /// Called when the user taps an assessment on the `OCKSymptomTrackerViewController`.
    
    func careCardViewController(viewController: OCKCareCardViewController, didSelectButtonWithInterventionEvent interventionEvent: OCKCarePlanEvent) {
        
        //Lookup the care plan the row represents.
        guard let activityType = ActivityType(rawValue: interventionEvent.activity.identifier) else { return }
        guard let sampleAssessment = sampleData.activityWithType(activityType) as? TubeSample else { return }

        /*
         Check if we should show a task for the selected assessment event
         based on its state.
        */
        guard interventionEvent.state == .Initial ||
            interventionEvent.state == .NotCompleted ||
            (interventionEvent.state == .Completed && interventionEvent.activity.resultResettable) else { return }
        
        // Show an `ORKTaskViewController` for the assessment's task.
        let taskViewController = ORKTaskViewController(task: sampleAssessment.task(), taskRunUUID: nil)
        taskViewController.delegate = self
        
        shouldComplete = false
        lastInterventionEvent = interventionEvent
        presentViewController(taskViewController, animated: true, completion: nil)
    }
  
    func careCardViewController(viewController: OCKCareCardViewController, shouldHandleEventCompletionForActivity interventionActivity: OCKCarePlanActivity) -> Bool {
        
        return false
    }
}

extension CareCardNavigationController: ORKTaskViewControllerDelegate {
    
    /// Called with then user completes a presented `ORKTaskViewController`.
    func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        
        defer {
            dismissViewControllerAnimated(true, completion: nil)
        }
        
        // Make sure the reason the task controller finished is that it was completed.
        guard reason == .Completed else {
            shouldComplete = false
            return
        }
        
        guard let event = lastInterventionEvent else { return }
        
        let result = taskViewController.result
        
        guard let firstResult = result.firstResult as? ORKStepResult, stepResult = firstResult.results?.first else { fatalError("Unexepected task results") }

        guard let integerResult = stepResult as? ORKNumericQuestionResult, tube_number = integerResult.numericAnswer else {
            return
        }
        
        // Build an `OCKCarePlanEventResult` that can be saved into the `OCKCarePlanStore`.
        let carePlanResult = OCKCarePlanEventResult(valueString: tube_number.stringValue, unitString: nil, userInfo: nil)
        completeEvent(event, inStore: storeManager.store, withResult: carePlanResult)
    }
    
    // MARK: Convenience

    private func completeEvent(event: OCKCarePlanEvent, inStore store: OCKCarePlanStore, withResult result: OCKCarePlanEventResult) {
        store.updateEvent(event, withResult: result, state: .Completed) { success, _, error in
            if !success {
                print(error?.localizedDescription)
            }
        }
    }
}
