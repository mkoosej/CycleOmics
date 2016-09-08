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
    
    class func daysInThisWeek() -> ([NSDate], todayIndex:Int) {
        // create calendar
        let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
        
        // today's date
        let today = NSDate()
        let todayComponent = calendar.components([.Day, .Month, .Year], fromDate: today)
        
        // range of dates in this week
        let thisWeekDateRange = calendar.rangeOfUnit(.Day, inUnit:.WeekOfMonth, forDate:today)
        
        // date interval from today to beginning of week
        let dayInterval = thisWeekDateRange.location - todayComponent.day
        
        // date for beginning day of this week, ie. this week's Sunday's date
        let beginningOfWeek = calendar.dateByAddingUnit(.Day, value: dayInterval, toDate: today, options: .MatchNextTime)
        
        var dates: [NSDate] = []
        
        // to include days of the week belongs to past month
        // we should always have 7 days
        for i in (thisWeekDateRange.length-7) ..< thisWeekDateRange.length {
            let date = calendar.dateByAddingUnit(.Day, value: i, toDate: beginningOfWeek!, options: .MatchNextTime)!
            dates.append(date)
        }
        
        let todayIndex = -(dayInterval + (thisWeekDateRange.length-7))
        
        return (dates,todayIndex)
    }
    
    var getLocalizedDayofWeek:String {
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let dayOfWeekString = dateFormatter.stringFromDate(self)
        
        return dayOfWeekString
    }
    
}