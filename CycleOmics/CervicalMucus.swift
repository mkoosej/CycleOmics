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
        HKCategoryValueCervicalMucusQuality.dry.rawValue:"Dry",
        HKCategoryValueCervicalMucusQuality.sticky.rawValue:"Sticky",
        HKCategoryValueCervicalMucusQuality.creamy.rawValue:"Creamy",
        HKCategoryValueCervicalMucusQuality.watery.rawValue:"Watery",
        HKCategoryValueCervicalMucusQuality.eggWhite.rawValue:"Egg white"
    ]
    
    // MARK: HealthSampleBuilder Properties
    let categoryType: HKCategoryType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.cervicalMucusQuality)!
    
    let value: Int = HKCategoryValue.notApplicable.rawValue
    
    func carePlanActivity() -> OCKCarePlanActivity {
        // Create a weekly schedule.
        let startDate = NSDateComponents(year: 2016, month: 01, day: 01)
        let schedule = OCKCareSchedule.weeklySchedule(withStartDate: startDate as DateComponents, occurrencesOnEachDay: [1, 1, 1, 1, 1, 1, 1])
        
        // Get the localized strings to use for the assessment.
        let summary = NSLocalizedString("", comment: "")
        
        let activity = OCKCarePlanActivity.assessment(
            withIdentifier: activityType.rawValue,
            groupIdentifier: nil,
            title: self.title,
            text: summary,
            tintColor: Colors.purple.color,
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
        let answerFormat = ORKAnswerFormat.choiceAnswerFormat(with: .singleChoice, textChoices: choices)
        let questionStep = ORKQuestionStep(identifier: "cerv_miniform", title: title, answer: answerFormat)
        questionStep.isOptional = false
        
        let task = ORKOrderedTask(identifier: activityType.rawValue, steps: [questionStep])
        return task
    }
    
    // MARK: HealthSampleBuilder
    
    /// Builds a `HKCategorySample` from the information in the supplied `ORKTaskResult`.
    func buildSampleWithTaskResult(_ result: ORKTaskResult, date:Date) -> HKCategorySample {
        
        guard let firstResult = result.firstResult as? ORKStepResult, let stepResult = firstResult.results?.first else { fatalError("Unexepected task results") }
        
        // Get the numeric answer for the result.
        guard let choiceResult = stepResult as? ORKChoiceQuestionResult, let numericAnswer = choiceResult.choiceAnswers!.first as? Int else { fatalError("Unable to determine result answer") }
        
        // Create a `HKCategorySample` for the answer.
        
        return HKCategorySample(
            type: categoryType,
            value: numericAnswer,
            start: date,
            end: date
        )
    }
    
    func buildCategoricalResultForCarePlanEvent(_ event: OCKCarePlanEvent, taskResult: ORKTaskResult) -> OCKCarePlanEventResult {
        
        let date = Calendar.current.date(from: event.date)!
        let categorySample = self.buildSampleWithTaskResult(taskResult,date: date)
        
        // Build the result should be saved.
        return OCKCarePlanEventResult(
            categorySample: categorySample,
            categoryValueStringKeys: self.ValueStringForCategory() as [NSNumber : String],
            userInfo: nil
        )
    }

    
    // MARK: Convinience
    
    fileprivate func getAnswerChoices() -> [ORKTextChoice] {
        
        var choices =  [ORKTextChoice]()
        
        for (value,text) in CervicalMucus.valueStrings {
            choices.append(ORKTextChoice(text: NSLocalizedString(text, comment: ""), value: value as NSCoding & NSCopying & NSObjectProtocol) )
        }
        
        return choices
    }
    
    fileprivate func ValueStringForCategory() -> [Int:String] {
        
        return [
            HKCategoryValueCervicalMucusQuality.dry.rawValue : "D",
            HKCategoryValueCervicalMucusQuality.sticky.rawValue : "S",
            HKCategoryValueCervicalMucusQuality.creamy.rawValue : "C",
            HKCategoryValueCervicalMucusQuality.watery.rawValue : "W",
            HKCategoryValueCervicalMucusQuality.eggWhite.rawValue : "E",
        ]
    }
}
