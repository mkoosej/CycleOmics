//
//  NSDate+day.swift
//  CycleOmics
//
//  Created by Mojtaba Koosej on 8/7/16.
//  Copyright © 2016 Curio. All rights reserved.
//

import Foundation

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date? {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return (Calendar.current as NSCalendar).date(byAdding: components, to: startOfDay, options: NSCalendar.Options())
    }
    
    var startOfDayComponent: DateComponents {
        return NSDateComponents(date: startOfDay, calendar: Calendar.current) as DateComponents
    }
    
    var endOfDayComponent: DateComponents {
        return NSDateComponents(date: endOfDay!, calendar: Calendar.current) as DateComponents
    }
    
    static func daysInThisWeek() -> ([Date], todayIndex:Int) {
        // create calendar
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        
        // today's date
        let today = Date()
        let todayComponent = (calendar as NSCalendar).components([.day, .month, .year], from: today)
        
        // range of dates in this week
        let thisWeekDateRange = (calendar as NSCalendar).range(of: .day, in:.weekOfMonth, for:today)
        
        // date interval from today to beginning of week
        let dayInterval = thisWeekDateRange.location - todayComponent.day!
        
        // date for beginning day of this week, ie. this week's Sunday's date
        let beginningOfWeek = (calendar as NSCalendar).date(byAdding: .day, value: dayInterval, to: today, options: .matchNextTime)
        
        var dates: [Date] = []
        
        // to include days of the week belongs to past month
        // we should always have 7 days
        for i in 0..<7 {
            let date = (calendar as NSCalendar).date(byAdding: .day, value: i, to: beginningOfWeek!, options: .matchNextTime)!
            dates.append(date)
        }
        
        let todayIndex = abs(dayInterval)
        
        return (dates, todayIndex)
    }
    
    var getLocalizedDayofWeek:String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let dayOfWeekString = dateFormatter.string(from: self)
        
        return dayOfWeekString
    }
    
}
