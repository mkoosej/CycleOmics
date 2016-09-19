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
struct Saliva: TubeSample {
    // MARK: Activity
    
    let activityType: ActivityType = .Saliva
    
    func carePlanActivity() -> OCKCarePlanActivity {
        // Create a weekly schedule.
        let startDate = NSDateComponents(year: 2016, month: 01, day: 01)
        let schedule = OCKCareSchedule.weeklySchedule(withStartDate: startDate as DateComponents, occurrencesOnEachDay: [1, 1, 1, 1, 1, 1, 1])
        
        // Get the localized strings to use for the activity.
        let summary = NSLocalizedString("Follow the instructions", comment: "")
        let text = "1) Rinse the mouth. No brushing teeth at least 30 minutes before collection, and not to consume food and liquids (except water) or chewing gum.\n\n" +
        "2) Saliva is allowed to accumulate in the follor of the mouth and the subject spits it out into the 50 ml tube every 60 seconds.\n\n" +
        "3) The saliva sample should be transferred into a 1 ml 2D-labeled tube using a plastic pipet. Discard the plastic pipet after use.\n\n" +
        "4) Marked the date and time of collection on the side of the tube.\n\n" +
        "5) Store at freezer immediately."

        let instructions = NSLocalizedString(text, comment: "")

        // Create the intervention activity.
        let activity = OCKCarePlanActivity.intervention(
            withIdentifier: activityType.rawValue,
            groupIdentifier: nil,
            title: title,
            text: summary,
            tintColor: Colors.blue.color,
            instructions: instructions,
            imageURL: nil,
            schedule: schedule,
            userInfo: nil
        )
        
        return activity
    }
}
