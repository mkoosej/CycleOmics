//
//  SexualActivities.swift
//  CycleOmics
//
//  Created by Mojtaba Koosej on 7/5/16.
//  Copyright © 2016 Curio. All rights reserved.
//

import ResearchKit
import CareKit

/**
 Struct that conforms to the `Assessment` protocol to define a sleep tracking
assessment.
 */
struct Sleep: Assessment, HealthCategorySampleBuilder {
    // MARK: Activity
    
    let activityType: ActivityType = .Sleep
    
    // MARK: HealthSampleBuilder Properties
    let categoryType: HKCategoryType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
    
    let value: Int = HKCategoryValueSleepAnalysis.asleep.rawValue
    
    func carePlanActivity() -> OCKCarePlanActivity {
        // Create a weekly schedule.
        let startDate = NSDateComponents(year: 2016, month: 01, day: 01)
        let schedule = OCKCareSchedule.weeklySchedule(withStartDate: startDate as DateComponents, occurrencesOnEachDay: [1, 1, 1, 1, 1, 1, 1])
        
        
        let activity = OCKCarePlanActivity.assessment(
            withIdentifier: activityType.rawValue,
            groupIdentifier: nil,
            title: self.title,
            text: nil,
            tintColor: Colors.lightBlue.color,
            resultResettable: false,
            schedule: schedule,
            userInfo: nil
        )
        
        return activity
    }
    
    // MARK: Assessment
    
    func task() -> ORKTask {
        // Get the localized strings to use for the task.
        
        // Create a question.
        let title = NSLocalizedString("Log the times you were asleep after you went to bed", comment: "")
        
        let formStep = ORKFormStep(identifier: "sleep_miniform", title: "Sleep Analysis", text: title)
        formStep.isOptional = false
        
        var steps = [ORKFormItem]()
        let start = ORKFormItem(identifier: "sleep_starts", text: "Starts", answerFormat: ORKAnswerFormat.dateTime())
        start.isOptional = false
        
        let end = ORKFormItem(identifier: "sleep_end", text: "Ends", answerFormat: ORKAnswerFormat.dateTime())
        end.isOptional = false
        
        steps.append(start)
        steps.append(end)
        
        formStep.formItems = steps
        
        // Create an ordered task with a single question.
        let task = ORKOrderedTask(identifier: activityType.rawValue, steps: [formStep])
    
        return task
    }

    // MARK: HealthSampleBuilder
    
    /// Builds a `HKCategorySample` from the information in the supplied `ORKTaskResult`.
    func buildSampleWithTaskResult(_ result: ORKTaskResult, date:Date) -> HKCategorySample {
        
        // Get the start time and end time of the sleep event
        guard let firstResult = result.firstResult as? ORKStepResult,
            let start = firstResult.results?.first as? ORKDateQuestionResult,
            let end = firstResult.results?[1] as? ORKDateQuestionResult
            else { fatalError("Unexepected task results") }
        
        return HKCategorySample(
            type: self.categoryType,
            value: self.value, start:
            start.dateAnswer!,
            end: end.dateAnswer!
        )
    }
    
    func buildCategoricalResultForCarePlanEvent(_ sample: OCKCarePlanEvent, taskResult: ORKTaskResult) -> OCKCarePlanEventResult {
        
        let date = Calendar.current.date(from: sample.date)!
        let categorySample = self.buildSampleWithTaskResult(taskResult,date: date)
        
        // Build the result should be saved.
        return OCKCarePlanEventResult(
            categorySample: categorySample,
            categoryValueStringKeys: [ 1: "✓" ],
            userInfo: nil
        )
    }
}
