//
//  Extensions-Date.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 24/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//
// https://gist.github.com/Rawnly/2d0d8cf85048f0bc533afb19bdef5c1c
// https://medium.com/@rserentill/dealing-with-relative-dates-in-swift-the-cool-way-5903a7af2461

import Foundation

// MARK: - DateComponents from Int
// https://medium.com/@rserentill/dealing-with-relative-dates-in-swift-the-cool-way-5903a7af2461
extension Int {
    var seconds : DateComponents { .init(second : self) }
    var minutes : DateComponents { .init(minute : self) }
    var hours   : DateComponents { .init(hour   : self) }
    var days    : DateComponents { .init(day    : self) }
    var weeks   : DateComponents { .init(day   : self * 7) }
    var months  : DateComponents { .init(month  : self) }
    var years   : DateComponents { .init(year   : self) }
}
// MARK: - Relative Dates from Now or from a another date
// https://medium.com/@rserentill/dealing-with-relative-dates-in-swift-the-cool-way-5903a7af2461
extension DateComponents {
    /// Usage:
    ///
    ///     print("Yesterday:", 1.days.ago!)
    var ago: Date? { Calendar.current.date(byAdding: -self,
                                           to: Date()) }
    
    /// Usage:
    ///
    ///     print("3 years from now:", 3.years.fromNow!)
    ///     print("1 hour and twenty minutes from now:", (1.hours + 20.minutes).fromNow!)
    ///     print("1 hour - 55 seconds ago:", (1.hours - 55.seconds).ago!)
    ///     print("2 weeks - 1 day + 5 hours ago:", (2.weeks - 1.days + 5.hours).ago!)
    var fromNow: Date? { Calendar.current.date(byAdding: self,
                                               to: Date()) }
    func before(_ thisDate: Date) -> Date? {
        Calendar.current.date(byAdding: -self,
                              to: thisDate)
    }
    
    func from(_ thisDate: Date) -> Date? {
        Calendar.current.date(byAdding: self,
                              to: thisDate)
    }
    
    static prefix func - (rhs: Self) -> DateComponents {
        .init(year: -rhs.year,
              month: -rhs.month,
              day: -rhs.day,
              hour: -rhs.hour,
              minute: -rhs.minute,
              second: -rhs.second)
    }
    static func + (lhs: Self, rhs: Self) -> DateComponents {
        DateComponents(year: lhs.year + rhs.year,
                       month: lhs.month + rhs.month,
                       day: lhs.day + rhs.day,
                       hour: lhs.hour + rhs.hour,
                       minute: lhs.minute + rhs.minute,
                       second: lhs.second + rhs.second)
    }
    static func - (lhs: Self, rhs: Self) -> DateComponents {
        DateComponents(year: lhs.year - rhs.year,
                       month: lhs.month - rhs.month,
                       day: lhs.day - rhs.day,
                       hour: lhs.hour - rhs.hour,
                       minute: lhs.minute - rhs.minute,
                       second: lhs.second - rhs.second)
    }
}

// https://medium.com/@rserentill/dealing-with-relative-dates-in-swift-the-cool-way-5903a7af2461
extension Optional where Wrapped: Numeric {
    static prefix func - (rhs: Self) -> Wrapped? {
        switch rhs {
            case .some(let value):
                return value * -1
            case .none:
                return nil
        }
    }
    static func + (lhs: Self, rhs: Self) -> Wrapped? {
        switch (lhs, rhs) {
            case (.some(let lhsValue), .some(let rhsValue)):
                return lhsValue + rhsValue
            case (.none, .some(let value)), (.some(let value), .none):
                return value
            default: return nil
        }
    }
    static func - (lhs: Self, rhs: Self) -> Wrapped? {
        switch (lhs, rhs) {
            case (.some(let lhsValue), .some(let rhsValue)):
                return lhsValue - rhsValue
            case (.none, .some(let value)), (.some(let value), .none):
                return value
            default: return nil
        }
    }
}

// MARK: - Int from Date
// https://gist.github.com/Rawnly/2d0d8cf85048f0bc533afb19bdef5c1c
extension Date {
    static var calendar: Calendar {
        return Calendar.current
    }
    
    var weekDay: Int {
        return Date.calendar.component(.weekday, from: self)
    }
    
    var weekOfMonth: Int {
        return Date.calendar.component(.weekOfMonth, from: self)
    }
    
    var weekOfYear: Int {
        return Date.calendar.component(.weekOfYear, from: self)
    }
    
    var dayOfYear: Int? {
        return Date.calendar.ordinality(of: .day, in: .year, for: self)
    }
    
    var year: Int {
        return Date.calendar.component(.year, from: self)
    }
    
    var month: Int {
        return Date.calendar.component(.month, from: self)
    }
    
    var quarter: Int {
        return Date.calendar.component(.quarter, from: self)
    }
    
    var day: Int {
        return Date.calendar.component(.day, from: self)
    }
    
    var era: Int {
        return Date.calendar.component(.era, from: self)
    }
    
    var hours: Int {
        return Date.calendar.component(.hour, from: self)
    }
    
    var minutes: Int {
        return Date.calendar.component(.minute, from: self)
    }
    
    var seconds: Int {
        return Date.calendar.component(.second, from: self)
    }
    
    var nanoseconds: Int {
        return Date.calendar.component(.nanosecond, from: self)
    }
}

// MARK: - Date Utility
// https://gist.github.com/Rawnly/2d0d8cf85048f0bc533afb19bdef5c1c
extension Date {
    static var now: Date {
        return self.init()
    }
    
    /// "HH:MM"
    var stringTime: String {
        return getStringTime(showSeconds: false)
    }
    
    /// "HH:MM:SS"
    var stringTimeWithSeconds: String {
        return getStringTime(showSeconds: true)
    }
    
    var timestamp: TimeInterval {
        return timeIntervalSince1970
    }
    
    private func getStringTime(showSeconds: Bool = false) -> String {
        var time = "\(hours.description):\(minutes.description)"
        
        if showSeconds {
            time += ":\(seconds.description)"
        }
        
        return time
    }
    
    func days(between otherDate: Date) -> Int {
        let calendar = Calendar.current
        
        let startOfSelf = calendar.startOfDay(for: self)
        let startOfOther = calendar.startOfDay(for: otherDate)
        let components = calendar.dateComponents([.day], from: startOfSelf, to: startOfOther)
        
        return abs(components.day ?? 0)
    }
}

// MARK: - Date Utility
extension Date {
    /// 02/01/2001
    var stringShortDate: String {
        return shortDateFormatter.string(from: self)
    }
    
    /// 2 janv. 2001
    var stringMediumDate: String {
        return mediumDateFormatter.string(from: self)
    }
    
    /// 2 janvier 2001
    var stringLongDate: String {
        return longDateFormatter.string(from: self)
    }

    /// 02/01
    var stringShortDayMonth: String {
        return dayMonthShortFormatter.string(from: self)
    }
    
    /// 2 janv.
    var stringMediumDayMonth: String {
        return dayMonthMediumFormatter.string(from: self)
    }
    
    /// 2 janvier
    var stringLongDayMonth: String {
        return dayMonthLongFormatter.string(from: self)
    }
}

// MARK: - Optional Date Utility
extension Optional where Wrapped == Date {
    /// 02/01/2001
    var stringShortDate: String {
        switch self {
            case .some(let date):
                return date.stringShortDate
            case .none:
                return "nil"
        }
    }
    
    /// 2 janv. 2001
    var stringMediumDate: String {
        switch self {
            case .some(let date):
                return date.stringMediumDate
            case .none:
                return "nil"
        }
    }
    
    /// 2 janvier 2001
    var stringLongDate: String {
        switch self {
            case .some(let date):
                return date.stringLongDate
            case .none:
                return "nil"
        }
    }
}

func min(_ date1: Date, _ date2: Date) -> Date {
    if date1 <= date2 { return date1 } else { return date2 }
}

func max(_ date1: Date, _ date2: Date) -> Date {
    if date1 <= date2 { return date2 } else { return date1 }
}

func firstDayOf(year: Int) -> Date {
    Date.calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
}

func lastDayOf(year: Int) -> Date {
    Date.calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
}

func numberOfDays(from: Date, to: Date) -> DateComponents {
    Date.calendar.dateComponents([.day], from: from, to: to)
}

func numberOf(_ component: Calendar.Component, from: Date, to: Date) -> DateComponents {
    Date.calendar.dateComponents([component], from: from, to: to)
}

extension Date {
    func toString(format: String) -> String {
        let df = DateFormatter()
        df.dateFormat = format
        return df.string(from: self)
    }
}
