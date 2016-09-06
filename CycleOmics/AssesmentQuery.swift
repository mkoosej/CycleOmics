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
    let activities: [ActivityType] = [.BasalBodyTemp, .Mood, .Sleep, .SexualActivities, .CervicalMucus, .Stress, .Notes]
    var results = [String:OCKCarePlanEvent]()
    
    required init(carePlanStore: OCKCarePlanStore) {
        self.store = carePlanStore
    }
    
}