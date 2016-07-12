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
struct SexualActivities: Assessment, HealthCategorySampleBuilder {
    // MARK: Activity
    
    let activityType: ActivityType = .SexualActivities
    
    // MARK: HealthSampleBuilder Properties
    let categotyType: HKCategoryType = HKCategoryType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSexualActivity)!
    
    let value: Int = HKCategoryValue.NotApplicable.rawValue
    
    func carePlanActivity() -> OCKCarePlanActivity {
        // Create a weekly schedule.
        let startDate = NSDateComponents(year: 2016, month: 01, day: 01)
        let schedule = OCKCareSchedule.weeklyScheduleWithStartDate(startDate, occurrencesOnEachDay: [1, 1, 1, 1, 1, 1, 1])
        
        // Get the localized strings to use for the assessment.
        let title = NSLocalizedString("Sexual Activity", comment: "")
        let summary = NSLocalizedString("", comment: "")
        
        let activity = OCKCarePlanActivity.assessmentWithIdentifier(
            activityType.rawValue,
            groupIdentifier: nil,
            title: title,
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
        
        // Create a question.
        let questionStep = ORKQuestionStep(identifier: "had_sex", title: "Sexual Activity", text: "Did you have any sexual activity in this day?" , answer: ORKAnswerFormat.booleanAnswerFormat())
        questionStep.optional = false
        
        // Form for the category sample
        let formStep = ORKFormStep(identifier: "sex_miniform", title: "Sexual Activity", text: "")
        formStep.optional = false
        
        var steps = [ORKFormItem]()
                
        let protection = ORKFormItem(identifier: "sex_protection", text: "Protection Used:", answerFormat: ORKAnswerFormat.booleanAnswerFormat())
        
        let date = ORKFormItem(identifier: "sex_date", text: "Date:", answerFormat: ORKAnswerFormat.dateTimeAnswerFormat())
        
        steps.append(protection)
        steps.append(date)
        
        formStep.formItems = steps
        
        let skipStep = ORKInstructionStep(identifier: "survey_skipped")
        skipStep.title = "Thanks for your answer!"
        
        // Create an ordered task with a single question.
        let task: ORKNavigableOrderedTask = ORKNavigableOrderedTask(identifier: "sex_survey", steps: [questionStep, formStep, skipStep])
        
        // If the user didn't have sex skip the second step and nothing needs to be logged in HKStore
        let resultSelector = ORKResultSelector.init(stepIdentifier: "had_sex", resultIdentifier: "had_sex");
        let predicateSkippedSex: NSPredicate = ORKResultPredicate.predicateForChoiceQuestionResultWithResultSelector(resultSelector, expectedAnswerValue: false)
        
        let predicateRule = ORKPredicateStepNavigationRule(resultPredicates: [predicateSkippedSex], destinationStepIdentifiers: ["survey_skipped"], defaultStepIdentifier: "survey_skipped", validateArrays: true)
        task.setNavigationRule(predicateRule, forTriggerStepIdentifier: "sex_survey")
        
        return task
    }
    
    // MARK: HealthSampleBuilder
    
    /// Builds a `HKCategorySample` from the information in the supplied `ORKTaskResult`.
    func buildSampleWithTaskResult(result: ORKTaskResult) -> HKCategorySample {
        
        // Get the first result for the first step of the task result.
        guard let firstResult = result.firstResult as? ORKStepResult, stepResult = firstResult.results?.first else { fatalError("Unexepected task results") }
        
        let startDate =  NSDate()
        let endDate =  NSDate()
        let protectionUsed = true
        
        let metadata = [HKCategoryTypeIdentifierSexualActivity : protectionUsed]
        
        return HKCategorySample(type: categotyType, value: value, startDate: startDate, endDate: endDate, metadata: metadata)
    }
    
    func buildCategoricalResultForCarePlanEvent(event: OCKCarePlanEvent, taskResult: ORKTaskResult) -> OCKCarePlanEventResult {
        // Get the first result for the first step of the task result.
        guard let firstResult = taskResult.firstResult as? ORKStepResult, stepResult = firstResult.results?.first else { fatalError("Unexepected task results") }
        
        // Determine what type of result should be saved.
        if let scaleResult = stepResult as? ORKScaleQuestionResult, answer = scaleResult.scaleAnswer {
            return OCKCarePlanEventResult(valueString: answer.stringValue, unitString: "out of 10", userInfo: nil)
        }
        else if let numericResult = stepResult as? ORKNumericQuestionResult, answer = numericResult.numericAnswer {
            return OCKCarePlanEventResult(valueString: answer.stringValue, unitString: numericResult.unit, userInfo: nil)
        }
        
        fatalError("Unexpected task result type")
    }

    
}
