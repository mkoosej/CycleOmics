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
 Struct that conforms to the `Assessment` protocol to define a sexual activity tracking
 assessment.
 */
struct CervicalMucus: Assessment, HealthCategorySampleBuilder {
    // MARK: Activity
    
    let activityType: ActivityType = .CervicalMucus
    
    static let valueStrings:[Int:String] = [
        HKCategoryValueCervicalMucusQuality.Dry.rawValue:"Dry",
        HKCategoryValueCervicalMucusQuality.Sticky.rawValue:"Sticky",
        HKCategoryValueCervicalMucusQuality.Creamy.rawValue:"Creamy",
        HKCategoryValueCervicalMucusQuality.Watery.rawValue:"Watery",
        HKCategoryValueCervicalMucusQuality.EggWhite.rawValue:"Egg white"
    ]
    
    // MARK: HealthSampleBuilder Properties
    let categoryType: HKCategoryType = HKCategoryType.categoryTypeForIdentifier(HKCategoryTypeIdentifierCervicalMucusQuality)!
    
    let value: Int = HKCategoryValue.NotApplicable.rawValue
    
    func carePlanActivity() -> OCKCarePlanActivity {
        // Create a weekly schedule.
        let startDate = NSDateComponents(year: 2016, month: 01, day: 01)
        let schedule = OCKCareSchedule.weeklyScheduleWithStartDate(startDate, occurrencesOnEachDay: [1, 1, 1, 1, 1, 1, 1])
        
        // Get the localized strings to use for the assessment.
        let summary = NSLocalizedString("", comment: "")
        
        let activity = OCKCarePlanActivity.assessmentWithIdentifier(
            activityType.rawValue,
            groupIdentifier: nil,
            title: self.title,
            text: summary,
            tintColor: Colors.Purple.color,
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
        let title = NSLocalizedString("Cervical Mucus Quality", comment: "")
        
        let choices = getAnswerChoices()
        let answerFormat = ORKAnswerFormat.choiceAnswerFormatWithStyle(.SingleChoice, textChoices: choices)
        let questionStep = ORKQuestionStep(identifier: "cerv_miniform", title: title, answer: answerFormat)
        questionStep.optional = false
        
        let task = ORKOrderedTask(identifier: activityType.rawValue, steps: [questionStep])
        return task
    }
    
    // MARK: HealthSampleBuilder
    
    /// Builds a `HKCategorySample` from the information in the supplied `ORKTaskResult`.
    func buildSampleWithTaskResult(result: ORKTaskResult, date:NSDate) -> HKCategorySample {
        
        guard let firstResult = result.firstResult as? ORKStepResult, stepResult = firstResult.results?.first else { fatalError("Unexepected task results") }
        
        // Get the numeric answer for the result.
        guard let choiceResult = stepResult as? ORKChoiceQuestionResult, numericAnswer = choiceResult.choiceAnswers!.first as? Int else { fatalError("Unable to determine result answer") }
        
        // Create a `HKCategorySample` for the answer.
        
        return HKCategorySample(
            type: categoryType,
            value: numericAnswer,
            startDate: date,
            endDate: date
        )
    }
    
    func buildCategoricalResultForCarePlanEvent(event: OCKCarePlanEvent, taskResult: ORKTaskResult) -> OCKCarePlanEventResult {
        
        let date = NSCalendar.currentCalendar().dateFromComponents(event.date)!
        let categorySample = self.buildSampleWithTaskResult(taskResult,date: date)
        
        // Build the result should be saved.
        return OCKCarePlanEventResult(
            categorySample: categorySample,
            categoryValueStringKeys: self.ValueStringForCategory(),
            userInfo: nil
        )
    }

    
    // MARK: Convinience
    
    private func getAnswerChoices() -> [ORKTextChoice] {
        
        var choices =  [ORKTextChoice]()
        
        for (value,text) in CervicalMucus.valueStrings {
            choices.append(ORKTextChoice(text: NSLocalizedString(text, comment: ""), value: value) )
        }
        
        return choices
    }
    
    private func ValueStringForCategory() -> [Int:String] {
        
        return [
            HKCategoryValueCervicalMucusQuality.Dry.rawValue : "D",
            HKCategoryValueCervicalMucusQuality.Sticky.rawValue : "S",
            HKCategoryValueCervicalMucusQuality.Creamy.rawValue : "C",
            HKCategoryValueCervicalMucusQuality.Watery.rawValue : "W",
            HKCategoryValueCervicalMucusQuality.EggWhite.rawValue : "E",
        ]
    }
}
