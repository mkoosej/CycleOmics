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
    
    fileprivate let storeManager = CarePlanStoreManager.sharedCarePlanStoreManager
    fileprivate let sampleData: SampleData
    fileprivate var careCardViewController: OCKCareCardViewController!
    fileprivate var shouldComplete = true
    fileprivate var lastInterventionEvent:OCKCarePlanEvent?
    
    required init?(coder aDecoder: NSCoder) {
        
        sampleData = SampleData(carePlanStore: storeManager.store)
        super.init(coder: aDecoder)
        
        careCardViewController = createCareCardViewController()
        careCardViewController.delegate = self
        
        self.pushViewController(careCardViewController, animated: true)
    }
    
    fileprivate func createCareCardViewController() -> OCKCareCardViewController {
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
    
    func careCardViewController(_ viewController: OCKCareCardViewController, didSelectButtonWithInterventionEvent interventionEvent: OCKCarePlanEvent) {
        
        //Lookup the care plan the row represents.
        guard let activityType = ActivityType(rawValue: interventionEvent.activity.identifier) else { return }
        guard let sampleAssessment = sampleData.activityWithType(activityType) as? TubeSample else { return }

        /*
         Check if we should show a task for the selected assessment event
         based on its state.
        */
        guard interventionEvent.state == .initial ||
            interventionEvent.state == .notCompleted ||
            (interventionEvent.state == .completed && interventionEvent.activity.resultResettable) else { return }
        
        // Show an `ORKTaskViewController` for the assessment's task.
        let taskViewController = ORKTaskViewController(task: sampleAssessment.task(), taskRun: nil)
        taskViewController.delegate = self
        
        shouldComplete = false
        lastInterventionEvent = interventionEvent
        present(taskViewController, animated: true, completion: nil)
    }
  
    func careCardViewController(_ viewController: OCKCareCardViewController, shouldHandleEventCompletionFor interventionActivity: OCKCarePlanActivity) -> Bool {
        
        return false
    }
}

extension CareCardNavigationController: ORKTaskViewControllerDelegate {
    
    /// Called with then user completes a presented `ORKTaskViewController`.
    func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        defer {
            dismiss(animated: true, completion: nil)
        }
        
        // Make sure the reason the task controller finished is that it was completed.
        guard reason == .completed else {
            shouldComplete = false
            return
        }
        
        guard let event = lastInterventionEvent else { return }
        
        let result = taskViewController.result
        
        guard let firstResult = result.firstResult as? ORKStepResult, let formResults = firstResult.results else { fatalError("Unexepected task results") }

        guard let textResult = formResults[0] as? ORKTextQuestionResult, let tubeNumber = textResult.textAnswer else {
            return
        }
        
        guard let textResult2 = formResults[1] as? ORKTextQuestionResult, let description = textResult2.textAnswer else {
            return
        }
        
        // Build an `OCKCarePlanEventResult` that can be saved into the `OCKCarePlanStore`.
        let dict = ["description": description]
        let carePlanResult = OCKCarePlanEventResult(valueString: tubeNumber, unitString: nil, userInfo: dict as [String : NSCoding]?)
        completeEvent(event, inStore: storeManager.store, withResult: carePlanResult)
    }
    
    // MARK: Convenience

    fileprivate func completeEvent(_ event: OCKCarePlanEvent, inStore store: OCKCarePlanStore, withResult result: OCKCarePlanEventResult) {
        store.update(event, with: result, state: .completed) { success, _, error in
            if !success {
                debugPrint(error?.localizedDescription)
            }
        }
    }
}
