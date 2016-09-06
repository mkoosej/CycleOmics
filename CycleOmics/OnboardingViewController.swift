/*
Copyright (c) 2015, Apple Inc. All rights reserved.

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

import UIKit
import ResearchKit

class OnboardingViewController: UIViewController {
    // MARK: IB actions
    
    @IBAction func joinButtonTapped(sender: UIButton) {
        let consentDocument = ConsentDocument()
        let consentStep = ORKVisualConsentStep(identifier: "VisualConsentStep", document: consentDocument)
        
        let healthDataStep = HealthDataStep(identifier: "Health")
        
        let signature = consentDocument.signatures!.first!
        
        let reviewConsentStep = ORKConsentReviewStep(identifier: "ConsentReviewStep", signature: signature, inDocument: consentDocument)
        
        reviewConsentStep.text = "Review the consent form."
        reviewConsentStep.reasonForConsent = "By agreeing you confirm that you read the consent form and that you wish to join the CycleOmics Research Study."
        
        
        let passcodeStep = ORKPasscodeStep(identifier: "Passcode")
        passcodeStep.text = "Now you will create a passcode to identify yourself to the app and protect access to information you've entered."
        
        
        let completionStep = ORKCompletionStep(identifier: "CompletionStep")
        completionStep.title = "Welcome aboard."
        completionStep.text = "Thank you for joining this study."
        
        let defaultTime = NSDateComponents()
        defaultTime.hour = 8
        defaultTime.minute = 0

        let formStep = ORKQuestionStep(
            identifier: "notificationStep",
            title: "Reminder",
            text: "What time do you generaly wake up? We will send you a notification to remind you of your first activity.",
            answer: ORKAnswerFormat.timeOfDayAnswerFormatWithDefaultComponents(defaultTime)
        )
        
        let orderedTask = ORKOrderedTask(identifier: "Join", steps: [consentStep, reviewConsentStep, healthDataStep, passcodeStep, formStep, completionStep])
        let taskViewController = ORKTaskViewController(task: orderedTask, taskRunUUID: nil)
        taskViewController.delegate = self
        
        presentViewController(taskViewController, animated: true, completion: nil)
    }
    
    private func setNotficationTime(results:ORKTaskResult) {
        
        let stepResult = results.stepResultForStepIdentifier("notificationStep")?.firstResult as? ORKTimeOfDayQuestionResult
        
        if(stepResult == nil)  { return }
        
        let calendar = NSCalendar.currentCalendar()
        let wakeup = stepResult?.dateComponentsAnswer!
        
        let today = NSDate()
        let components = calendar.components([.Year , .Month, .Day, .Hour, .Minute, .Second], fromDate: today)
        components.minute = (wakeup?.minute)!
        components.hour = (wakeup?.hour)!
        components.second = 0
        
        let date = calendar.dateFromComponents(components)
        NSUserDefaults.standardUserDefaults().setValue(date, forKey: "notification_time")
        
        // register notification settings
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: nil))
        
        // schedule notificaion
        let notification = UILocalNotification()
        notification.alertBody = "It's time for you to complete your first task of the day"
        notification.alertAction = "open"
        notification.fireDate = date
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.userInfo = ["title": "reminder", "UUID": "curio.cycleomics.local"]
        notification.repeatInterval = .Day
        notification.timeZone = NSCalendar.currentCalendar().timeZone
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    private func saveIdentifications(results:ORKTaskResult) {
        
        let stepResult = results.stepResultForStepIdentifier("ConsentReviewStep")?.firstResult as? ORKConsentSignatureResult
        
        if(stepResult == nil)  { return }
        
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let givenName = stepResult?.signature?.givenName {
            defaults.setValue(givenName, forKey: "givenName")
        }
        
        if let familyName = stepResult?.signature?.familyName {
            defaults.setValue(familyName, forKey: "familyName")
        }
    }
    
    private func completeOnboarding(results:ORKTaskResult) {
        
        saveIdentifications(results)
        setNotficationTime(results)
        performSegueWithIdentifier("unwindToStudy", sender: nil)
    }
}

extension OnboardingViewController : ORKTaskViewControllerDelegate {
    
    func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        switch reason {
            case .Completed:
                completeOnboarding(taskViewController.result)
            case .Discarded, .Failed, .Saved:
                dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func taskViewController(taskViewController: ORKTaskViewController, viewControllerForStep step: ORKStep) -> ORKStepViewController? {
        if step is HealthDataStep {
            let healthStepViewController = HealthDataStepViewController(step: step)
            return healthStepViewController
        }
        
        return nil
    }
    
}
