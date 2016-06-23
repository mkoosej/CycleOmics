
import ResearchKit
import CareKit

/**
 Struct that conforms to the `Assessment` protocol to define a basal body temprature.
 */
struct BasalBodyTemprature: Assessment {
    // MARK: Activity
    
    let activityType: ActivityType = .BasalBodyTemp
    
    func carePlanActivity() -> OCKCarePlanActivity {
        // Create a weekly schedule.
        let startDate = NSDateComponents(year: 2016, month: 01, day: 01)
        let schedule = OCKCareSchedule.weeklyScheduleWithStartDate(startDate, occurrencesOnEachDay: [1, 1, 1, 1, 1, 1, 1])
        
        // Get the localized strings to use for the assessment.
        let title = NSLocalizedString("Basel Body Temperature ", comment: "")
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
        // Get the localized strings to use for the task.
        let quantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBasalBodyTemperature)!
        let unit = HKUnit.degreeFahrenheitUnit();
        let answerFormat = ORKHealthKitQuantityTypeAnswerFormat(quantityType: quantityType, unit:unit, style: .Integer)
        
        // Create a question.
        let title = NSLocalizedString("Input your basal body temperature", comment: "")
        let questionStep = ORKQuestionStep(identifier: activityType.rawValue, title: title, answer: answerFormat)
        questionStep.optional = false
        
        // Create an ordered task with a single question.
        let task = ORKOrderedTask(identifier: activityType.rawValue, steps: [questionStep])
        
        return task
    }
}
