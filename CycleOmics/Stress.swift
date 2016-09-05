/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import ResearchKit
import CareKit

/**
 Struct that conforms to the `Assessment` protocol to define a Stress
 assessment.
 */
struct Stress: Assessment {
    // MARK: Activity
    
    let activityType: ActivityType = .Stress
    
    let questions = [
        "In the last day, how often have you been upset because of something that happened unexpectedly?",
        "In the last day, how often have you felt that you were unable to control the important things in your life?",
        "In the last day, how often have you felt nervous and “stressed”?",
        "In the last day, how often have you felt confident about your ability to handle your personal problems?",
        "In the last day, how often have you felt that things were going your way?",
        "In the last day, how often have you found that you could not cope with all the things you had to do?",
        "In the last day, how often have you been able to control irritations in your life?",
        "In the last day, how often have you felt that you were on top of things?",
        "In the last day, how often have you been angered because of things that were outside your control?",
        "In the last day, how often have you felt difficulties were pilling up so high that you could not overcome them?",
    ]
    
    func carePlanActivity() -> OCKCarePlanActivity {
        // Create a weekly schedule.
        let startDate = NSDateComponents(year: 2016, month: 01, day: 01)
        let schedule = OCKCareSchedule.weeklyScheduleWithStartDate(startDate, occurrencesOnEachDay: [1, 1, 1, 1, 1, 1, 1])
        
        // Get the localized strings to use for the assessment.
        let activity = OCKCarePlanActivity.assessmentWithIdentifier(
            activityType.rawValue,
            groupIdentifier: nil,
            title: self.title,
            text: nil,
            tintColor: Colors.Red.color,
            resultResettable: false,
            schedule: schedule,
            userInfo: nil
        )
        
        return activity
    }
    
    // MARK: Assessment
    
    func task() -> ORKTask {
        // Get the localized strings to use for the task.
        
        var steps = [ORKStep]()
        
        
            
        // Instruction step
        let instructionStep = ORKInstructionStep(identifier: "IntroStep")
        instructionStep.title = "Daily Stress Survey"
        instructionStep.text = "In this survey you've been asked about your feelings and thoughts during the “last day”. Each answer represents how often you felt or thought a certain way."
            
        steps += [instructionStep]
        
        for (index,question) in questions.enumerate() {
            
            // Quest question using text choice
            let questionStepTitle = question
            let textChoices = [
                ORKTextChoice(text: "Never", value: 0),
                ORKTextChoice(text: "Almost Never", value: 1),
                ORKTextChoice(text: "Sometimes", value: 2),
                ORKTextChoice(text: "Fairly Often", value: 3),
                ORKTextChoice(text: "Very Often", value: 4)
            ]
            
            let answerFormat: ORKTextChoiceAnswerFormat = ORKAnswerFormat.choiceAnswerFormatWithStyle(.SingleChoice, textChoices: textChoices)
            let questionStep = ORKQuestionStep(identifier: "SurveyQuestion \(index+1)", title: questionStepTitle, answer: answerFormat)
            questionStep.optional = false
            
            steps += [questionStep]
            
        }
        
        return ORKOrderedTask(identifier: "SurveyTask", steps: steps)
    }
}
