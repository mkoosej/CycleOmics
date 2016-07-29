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
 Struct that conforms to the `Activity` protocol to define a hamstring stretch
 activity.
 */
struct Stool: TubeSample {
    // MARK: Activity
    
    let activityType: ActivityType = .Stool
    let title = NSLocalizedString("Stool Sample", comment: "")
    
    func carePlanActivity() -> OCKCarePlanActivity {
        // Create a weekly schedule.
        let startDate = NSDateComponents(year: 2016, month: 01, day: 01)
        let schedule = OCKCareSchedule.weeklyScheduleWithStartDate(startDate, occurrencesOnEachDay: [1, 1, 1, 1, 1, 1, 1])
        
        // Get the localized strings to use for the activity.
        let title = NSLocalizedString("Stool Sample", comment: "")
        let summary = NSLocalizedString("Follow the instructions.", comment: "")
        let text = "1) Collect one tube of stool, at least 2 ml, into the bigger tube.\n\n" +
        "2) Thinly coat a swab with feces from toilet paper.\n\n" +
        "3) Insert the swab in the provided 2 ml collection tube (containing MoBio reagent).\n\n" +
        "4) Swirl/agitate the swab for 30 seconds\n\n" +
        "5) Break off the handle, leaving the swab head in the reagent tube\n\n" +
        "6) Close the tube.\n\n" +
        "7) Mark the date and time on the tube.\n\n" +
        "8) Freeze it immediately.\n\n"
        let instructions = NSLocalizedString(text, comment: "")
        let imageUrl = NSBundle.mainBundle().URLForResource("StoolSample", withExtension: "png")
        
        // Create the intervention activity.
        let activity = OCKCarePlanActivity.interventionWithIdentifier(
            activityType.rawValue,
            groupIdentifier: nil,
            title: title,
            text: summary,
            tintColor: Colors.Green.color,
            instructions: instructions,
            imageURL: imageUrl,
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
