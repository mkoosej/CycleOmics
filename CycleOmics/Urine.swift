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
    
    func carePlanActivity() -> OCKCarePlanActivity {
        // Create a weekly schedule.
        let startDate = NSDateComponents(year: 2016, month: 01, day: 01)
        let schedule = OCKCareSchedule.weeklyScheduleWithStartDate(startDate, occurrencesOnEachDay: [1, 1, 1, 1, 1, 1, 1])
        
        // Get the localized strings to use for the activity.
        let summary = NSLocalizedString("Follow the intructions", comment: "")
        let text = "1) Collect first morning urine sample before eating any food. It is considered the most valuable because it is more concentrated and more likely to yield abnormalities if present. \n\n" +
        "2) It is important to clean the genitalia before collecting urine. Bacteria and cells from the surrounding skin can contaminate the sample and interfere with the interpretation of test results. With women, menstrual blood and vaginal secretions can also be a source of contamination. Women should spread the labia of the vagina and clean from front to back; men should wipe the tip of the penis.\n\n" +
        "3) Collect midstream. Start to urinate, let some urine fall into the toilet, then collect one to two ounces of urine in the container provided, then void the rest into the toilet. This type of collection is called a \"midstream collection\" or a \"clean catch.\"" +
        "4) Aliquot and store without delay. As soon as the collection finishes, the urine sample should be transferred into a 200 ul and 1 ml aliquots (per sample) with 2D-labled tubes using a plastic pipet. Discard the plastic pipet after use." +
        "5) Marked the date and time of collection on the side of the two tubes." +
        "6) Store at freezer immediately."

        let instructions = NSLocalizedString(text, comment: "")
//        let imageUrl = NSBundle.mainBundle().URLForResource("UrineSample", withExtension: "png")
        
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
