//
//  NSDate+day.swift
//  CycleOmics
//
//  Created by Mojtaba Koosej on 8/7/16.
//  Copyright © 2016 Curio. All rights reserved.
//

import Foundation

extension NSDate {
    var startOfDay: NSDate {
        return NSCalendar.currentCalendar().startOfDayForDate(self)
    }
    
    var endOfDay: NSDate? {
        let components = NSDateComponents()
        components.day = 1
        components.second = -1
        return NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: startOfDay, options: NSCalendarOptions())
    }
    
    var startOfDayComponent: NSDateComponents {
        return NSDateComponents(date: startOfDay, calendar: NSCalendar.currentCalendar())
    }
    
    var endOfDayComponent: NSDateComponents {
        return NSDateComponents(date: endOfDay!, calendar: NSCalendar.currentCalendar())
    }
    
    
}