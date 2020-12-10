//
//  Constants.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct CalendarCst {
    static let nowComponents = Date.calendar.dateComponents([.year, .month, .day], from: Date.now)
    static let thisYear      = nowComponents.year!
    static let forever       = 3000
    static let endOfYearDate = Date.calendar.nextDate(after: Date.now,
                                                             matching: DateComponents(calendar: Date.calendar, month: 12, day: 31),
                                                             matchingPolicy: .nextTime)
    static let endOfYearComp = Date.calendar.dateComponents([.year, .month, .day], from: endOfYearDate!)
    //    static var endOfYearComp: DateComponents {
    //        var endOfYearComp = Date.nowComponents
    //        endOfYearComp.month = 12
    //        endOfYearComp.day = 31
    //        return endOfYearComp
    //    }
}

struct StringCst {
    static let header = "  "
}

struct RetirmentCst {
    static let minAgepension = 62
    static let maxAgepension = 67
}

struct ScenarioCst {
    static let minAgeUniversity   = 18
    static let minAgeIndependance = 24
}

struct FileNameCst {
    static let familyMembersFileName         = "persons.json"
//    static let familyRealEstatesFileName     = "immobilier.json"
//    static let familySCPIsFileName           = "SCPI.json"
//    static let familyFreeInvestsFileName     = "investissement libre.json"
//    static let familyPeriodicInvestsFileName = "investissement périodique.json"
//    static let familyExpensesFileName        = "dépenses.json"
}
