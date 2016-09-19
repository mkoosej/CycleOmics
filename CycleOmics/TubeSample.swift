//
//  TubeSample.swift
//  CycleOmics
//
//  Created by Mojtaba Koosej on 7/11/16.
//  Copyright © 2016 Curio. All rights reserved.
//

import Foundation
import ResearchKit

protocol TubeSample : Activity {
    func task() -> ORKTask
}

extension TubeSample {
        
    func task() -> ORKTask {
        
        // Create a question.
        let text = NSLocalizedString("Please enter the tube number and description for your sampling", comment: "")
        let formStep = ORKFormStep(identifier: activityType.rawValue, title: title, text: text)
        formStep.optional = false
        
        var steps = [ORKFormItem]()
        let number = ORKFormItem(identifier: activityType.rawValue, text: "Tube Number:", answerFormat: ORKAnswerFormat.textAnswerFormatWithMaximumLength(20))
        number.optional = false
        steps.append(number)
        
        let desc = ORKFormItem(identifier: activityType.rawValue + "_description", text: "Description:", answerFormat: ORKAnswerFormat.textAnswerFormat())
        desc.optional = true
        steps.append(desc)
        
        formStep.formItems = steps
        
        let task = ORKOrderedTask(identifier: activityType.rawValue, steps: [formStep])
        
        return task
    }
    
}