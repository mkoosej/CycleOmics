//
//  AssesmentQuery.swift
//  CycleOmics
//
//  Created by Mojtaba Koosej on 8/25/16.
//  Copyright © 2016 Curio. All rights reserved.
//

import Foundation
import CareKit

class AssesmentQuery : CarePlanQuery {
    
    let store: OCKCarePlanStore
    let activities: [ActivityType] = [.BasalBodyTemp, .Mood, .Stress, .Sleep, .SexualActivities, .CervicalMucus]
    var results = [String:OCKCarePlanEvent]()
    
    required init(carePlanStore: OCKCarePlanStore) {
        self.store = carePlanStore
    }
    
}