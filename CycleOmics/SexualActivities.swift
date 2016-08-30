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
        
        // Create a question.
        let booleanQuestionStep = ORKQuestionStep(identifier: "had_sex", title: "Sexual Activity", text: "Did you have any sexual activity in this day?" , answer: ORKAnswerFormat.booleanAnswerFormat())
        booleanQuestionStep.optional = false
        
        
        // Form for the category sample
        let formStep = ORKFormStep(identifier: "sex_miniform", title: "Sexual Activity", text: "")
        formStep.optional = false
        
        var steps = [ORKFormItem]()
        let protection = ORKFormItem(identifier: "sex_protection", text: "Protection Used:", answerFormat: ORKAnswerFormat.booleanAnswerFormat())
        protection.optional = false
        let date = ORKFormItem(identifier: "sex_date", text: "Date:", answerFormat: ORKAnswerFormat.dateTimeAnswerFormat())
        date.optional = false
        
        steps.append(protection)
        steps.append(date)
        
        formStep.formItems = steps
        
        // A dummy skip step for navigatable form
        let skipStep = ORKInstructionStep(identifier: "survey_skipped")
        skipStep.title = "Thanks for your answer!"
        skipStep.optional = false
        
        // Create an ordered task with a single question.
        let task: ORKNavigableOrderedTask = ORKNavigableOrderedTask(identifier: "sex_survey", steps: [booleanQuestionStep, formStep, skipStep])
        
        // If the user didn't have sex skip the second step and nothing needs to be logged in HKStore
        let resultSelector = ORKResultSelector.init(resultIdentifier: "had_sex");
        let predicateSkippedSex: NSPredicate = ORKResultPredicate.predicateForBooleanQuestionResultWithResultSelector(resultSelector, expectedAnswer: false)
        
        let predicateRule = ORKPredicateStepNavigationRule(resultPredicates: [predicateSkippedSex], destinationStepIdentifiers: ["survey_skipped"], defaultStepIdentifier: nil, validateArrays: true)
        task.setNavigationRule(predicateRule, forTriggerStepIdentifier: "had_sex")
        
        return task
    }
    
    // MARK: HealthSampleBuilder
    
    /// Builds a `HKCategorySample` from the information in the supplied `ORKTaskResult`.
    func buildSampleWithTaskResult(result: ORKTaskResult, date: NSDate) -> HKCategorySample {
        
        // Get the task result.
        guard let miniForm = result.stepResultForStepIdentifier("sex_miniform") else { fatalError("Unexepected task results") }
        guard let protectionStep = miniForm.resultForIdentifier("sex_protection") as? ORKBooleanQuestionResult else { fatalError("Unexepected task results") }
        guard let dateStep = miniForm.resultForIdentifier("sex_date") as? ORKDateQuestionResult else { fatalError("Unexepected task results") }

        let startDate =  dateStep.dateAnswer!
        let endDate =  dateStep.dateAnswer!
        let protectionUsed:Bool = (protectionStep.booleanAnswer?.boolValue)!
        
        let metadata = [HKMetadataKeySexualActivityProtectionUsed : protectionUsed]
        return HKCategorySample(type: categotyType, value: self.value, startDate: startDate, endDate: endDate, metadata: metadata)
    }
    
    func buildCategoricalResultForCarePlanEvent(event: OCKCarePlanEvent, taskResult: ORKTaskResult) -> OCKCarePlanEventResult {
    
        let date = event.date.date!
        if(self.shouldIgnoreSample(taskResult)) {
            return OCKCarePlanEventResult(valueString: "-", unitString: nil, userInfo: ["skipped":1])
        }
        
        let categorySample = self.buildSampleWithTaskResult(taskResult, date: date)
        
        // Build the result should be saved.
        return OCKCarePlanEventResult(
            categorySample: categorySample,
            categoryValueStringKeys: self.ValueStringForCategory(),
            userInfo: nil
        )
    }
    
    func shouldIgnoreSample(result: ORKTaskResult?) -> Bool {
        
        guard let firstResult = result?.firstResult as? ORKStepResult, stepResult = firstResult.results?.first else {
            return true
        }
        
        // Get the boolean answer for the result.
        guard let booleanResult = stepResult as? ORKBooleanQuestionResult, booleanAnswer = booleanResult.booleanAnswer as? Bool else { fatalError("Unable to determine result answer") }
        
        return !booleanAnswer
    }
    
    private func ValueStringForCategory() -> [Int:String] {
        
        return [
            self.value: "✔️"
        ]
    }
    
}
