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