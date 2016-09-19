//
//  HealthCategorySampleBuilder.swift
//  CycleOmics
//
//  Created by Mojtaba Koosej on 7/5/16.
//  Copyright © 2016 Curio. All rights reserved.
//

import ResearchKit
import CareKit
/**
 A protocol that defines the methods and properties required to be able to save
 an `ORKTaskResult` to a `ORKCarePlanStore` with an associated `HKCategorySample`.
 */
protocol HealthCategorySampleBuilder {
    
    var categoryType: HKCategoryType { get }
    var value: Int { get }
    func buildSampleWithTaskResult(_ result: ORKTaskResult, date:Date) -> HKCategorySample
    func buildCategoricalResultForCarePlanEvent(_ event: OCKCarePlanEvent, taskResult: ORKTaskResult) -> OCKCarePlanEventResult
}

extension HealthCategorySampleBuilder {
    
    func shouldIgnoreSample(_ result:ORKTaskResult?) -> Bool {
        
        if let checkType = self as? SexualActivities {
            return checkType.shouldIgnoreSample(result)
        }
        
        return false
    }
}
