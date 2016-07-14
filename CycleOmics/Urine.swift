//
//  StressSurvey.swift
//  CycleOmics
//
//  Created by Mojtaba Koosej on 7/6/16.
//  Copyright © 2016 Curio. All rights reserved.
//

import CareKit
import ResearchKit

/**
 Struct that conforms to the `Activity` protocol to define an activity to take
 medication.
 */
struct Urine: TubeSample {
    // MARK: Activity
    
    let activityType: ActivityType = .Urine
    let title = NSLocalizedString("Urine Sample", comment: "")
    
    func carePlanActivity() -> OCKCarePlanActivity {
        // Create a weekly schedule.
        let startDate = NSDateComponents(year: 2016, month: 01, day: 01)
        let schedule = OCKCareSchedule.weeklyScheduleWithStartDate(startDate, occurrencesOnEachDay: [1, 1, 1, 1, 1, 1, 1])
        
        // Get the localized strings to use for the activity.
        let title = NSLocalizedString("Urine", comment: "")
        let summary = NSLocalizedString("", comment: "")
        let instructions = NSLocalizedString("", comment: "")
        
        let activity = OCKCarePlanActivity.interventionWithIdentifier(
            activityType.rawValue,
            groupIdentifier: nil,
            title: title,
            text: summary,
            tintColor: Colors.Yellow.color,
            instructions: instructions,
            imageURL: nil,
            schedule: schedule,
            userInfo: nil
        )
        
        return activity
    }
    
    func task() -> ORKTask {
        // Get the localized strings to use for the task.
        let question = NSLocalizedString("Please enter the tube number you are using for sampling", comment: "")
        
        let questionStep = ORKQuestionStep(identifier: activityType.rawValue, title: title, text: question, answer: ORKAnswerFormat.integerAnswerFormatWithUnit(nil))
        questionStep.optional = false
        
        // Create an ordered task with a single question.
        let task = ORKOrderedTask(identifier: activityType.rawValue, steps: [questionStep])
        
        return task
    }
}
