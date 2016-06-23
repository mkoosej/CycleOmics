//
//  SymptomTrackerViewController.swift
//  CycleOmics
//
//  Created by Mojtaba Koosej on 6/23/16.
//  Copyright © 2016 Curio. All rights reserved.
//

import UIKit
import ResearchKit
import CareKit


class SymptomTrackerViewController: UIViewController {
    
    // MARK: Properties
    
    private let storeManager = CarePlanStoreManager.sharedCarePlanStoreManager

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

//extension SymptomTrackerViewController: OCKSymptomTrackerViewControllerDelegate {
//    
//    /// Called when the user taps an assessment on the `OCKSymptomTrackerViewController`.
//    func symptomTrackerViewController(viewController: OCKSymptomTrackerViewController, didSelectRowWithAssessmentEvent assessmentEvent: OCKCarePlanEvent) {
//        
//        // Lookup the assessment the row represents.
//        guard let activityType = ActivityType(rawValue: assessmentEvent.activity.identifier) else { return }
//        guard let sampleAssessment = sampleData.activityWithType(activityType) as? Assessment else { return }
//        
//        /*
//         Check if we should show a task for the selected assessment event
//         based on its state.
//         */
//        guard assessmentEvent.state == .Initial ||
//            assessmentEvent.state == .NotCompleted ||
//            (assessmentEvent.state == .Completed && assessmentEvent.activity.resultResettable) else { return }
//        
//        // Show an `ORKTaskViewController` for the assessment's task.
//        let taskViewController = ORKTaskViewController(task: sampleAssessment.task(), taskRunUUID: nil)
//        taskViewController.delegate = self
//        
//        presentViewController(taskViewController, animated: true, completion: nil)
//    }
//}

extension SymptomTrackerViewController: CarePlanStoreManagerDelegate {
    
    /// Called when the `CarePlanStoreManager`'s insights are updated.
    func carePlanStoreManager(manager: CarePlanStoreManager, didUpdateInsights insights: [OCKInsightItem]) {
        // Update the insights view controller with the new insights.
//        insightsViewController.items = insights
    }
}