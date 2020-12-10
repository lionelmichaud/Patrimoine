//
//  FormaterCharts.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Charts // https://github.com/danielgindi/Charts.git

// swiftlint:disable type_name
class Kilo€Formatter: NSObject, IAxisValueFormatter, IValueFormatter {
    let numFormatter: NumberFormatter
    // swiftlint:enable type_name

    override init() {
//        numFormatter = NumberFormatter()
//
//        // if number is less than 1 add 0 before decimal
//        numFormatter.minimumIntegerDigits = 1 // how many digits do want before decimal
//        numFormatter.multiplier = 0.001
//        //numFormatter.thousandSeparator = " "
//        numFormatter.positiveSuffix = " k€"
//        numFormatter.negativeSuffix = " k€"
//        numFormatter.paddingPosition = .beforePrefix
//        numFormatter.paddingCharacter = "0"
//        //numFormatter.zeroSymbol = ""
        
        numFormatter = valueKilo€Formatter
    }

    /// Called when a value from an axis is formatted before being drawn.
    ///
    /// For performance reasons, avoid excessive calculations and memory allocations inside this method.
    ///
    /// - returns: The customized label that is drawn on the axis.
    /// - parameter value:           the value that is currently being drawn
    /// - parameter axis:            the axis that the value belongs to
    ///
    public func stringForValue(_ value : Double,
                               axis    : AxisBase?) -> String {
        return numFormatter.string(from: NSNumber(value: value))!
    }

    /// - Parameters:
    ///   - value:           The value to be formatted
    ///   - dataSetIndex:    The index of the DataSet the entry in focus belongs to
    ///   - viewPortHandler: provides information about the current chart state (scale, translation, ...)
    /// - Returns:           The formatted label ready to be drawn
    public func stringForValue(_ value         : Double,
                               entry           : ChartDataEntry,
                               dataSetIndex    : Int,
                               viewPortHandler : ViewPortHandler?) -> String {
        return numFormatter.string(from: NSNumber(value: value))!
    }
}

class PercentFormatter: NSObject, IAxisValueFormatter, IValueFormatter {
    let numFormatter: NumberFormatter
    
    override init() {
        numFormatter = NumberFormatter()
        
        // if number is less than 1 add 0 before decimal
        numFormatter.minimumIntegerDigits = 1 // how many digits do want before decimal
        numFormatter.multiplier = 100.0
        //numFormatter.thousandSeparator = " "
        numFormatter.positiveSuffix = " %"
        numFormatter.negativeSuffix = " %"
        numFormatter.paddingPosition = .beforePrefix
        numFormatter.paddingCharacter = "0"
        //numFormatter.zeroSymbol = ""
    }
    
    /// Called when a value from an axis is formatted before being drawn.
    ///
    /// For performance reasons, avoid excessive calculations and memory allocations inside this method.
    ///
    /// - returns: The customized label that is drawn on the axis.
    /// - parameter value:           the value that is currently being drawn
    /// - parameter axis:            the axis that the value belongs to
    ///
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return numFormatter.string(from: NSNumber(value: value))!
    }
    
    /// - Parameters:
    ///   - value:           The value to be formatted
    ///   - dataSetIndex:    The index of the DataSet the entry in focus belongs to
    ///   - viewPortHandler: provides information about the current chart state (scale, translation, ...)
    /// - Returns:           The formatted label ready to be drawn
    public func stringForValue(_ value: Double,
                               entry: ChartDataEntry,
                               dataSetIndex: Int,
                               viewPortHandler: ViewPortHandler?) -> String {
        return numFormatter.string(from: NSNumber(value: value))!
    }
}

public class DateValueFormatter: NSObject, IAxisValueFormatter {
    private let dateFormatter = DateFormatter()
    
    override init() {
        super.init()
        dateFormatter.dateFormat = "dd MMM HH:mm"
    }
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return dateFormatter.string(from: Date(timeIntervalSince1970: value))
    }
}

public class DayAxisValueFormatter: NSObject, IAxisValueFormatter {
    weak var chart: BarLineChartViewBase?
    let months = ["Jan", "Feb", "Mar",
                  "Apr", "May", "Jun",
                  "Jul", "Aug", "Sep",
                  "Oct", "Nov", "Dec"]
    
    init(chart: BarLineChartViewBase) {
        self.chart = chart
    }
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let days = Int(value)
        let year = determineYear(forDays: days)
        let month = determineMonth(forDayOfYear: days)
        
        let monthName = months[month % months.count]
        let yearName = "\(year)"
        
        if let chart = chart,
            chart.visibleXRange > 30 * 6 {
            return monthName + yearName
        } else {
            let dayOfMonth = determineDayOfMonth(forDays: days, month: month + 12 * (year - 2016))
            var appendix: String
            
            switch dayOfMonth {
                case 1, 21, 31: appendix = "st"
                case 2, 22: appendix = "nd"
                case 3, 23: appendix = "rd"
                default: appendix = "th"
            }
            
            return dayOfMonth == 0 ? "" : String(format: "%d\(appendix) \(monthName)", dayOfMonth)
        }
    }
    
    private func days(forMonth month: Int, year: Int) -> Int {
        // month is 0-based
        switch month {
            case 1:
                var is29Feb = false
                if year < 1582 {
                    is29Feb = (year < 1 ? year + 1 : year) % 4 == 0
                } else if year > 1582 {
                    is29Feb = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
                }
                
                return is29Feb ? 29 : 28
            
            case 3, 5, 8, 10:
                return 30
            
            default:
                return 31
        }
    }
    
    private func determineMonth(forDayOfYear dayOfYear: Int) -> Int {
        var month = -1
        var days = 0
        
        while days < dayOfYear {
            month += 1
            if month >= 12 {
                month = 0
            }
            
            let year = determineYear(forDays: days)
            days += self.days(forMonth: month, year: year)
        }
        
        return max(month, 0)
    }
    
    private func determineDayOfMonth(forDays days: Int, month: Int) -> Int {
        var count = 0
        var daysForMonth = 0
        
        while count < month {
            let year = determineYear(forDays: days)
            daysForMonth += self.days(forMonth: count % 12, year: year)
            count += 1
        }
        
        return days - daysForMonth
    }
    
    private func determineYear(forDays days: Int) -> Int {
        switch days {
            case ...366: return 2016
            case 367...730: return 2017
            case 731...1094: return 2018
            case 1095...1458: return 2019
            default: return 2020
        }
    }
}

public class IntAxisValueFormatter: NSObject, IAxisValueFormatter {
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return "\(Int(value))"
    }
}

public class LargeValueFormatter: NSObject, IValueFormatter, IAxisValueFormatter {
    
    /// Suffix to be appended after the values.
    ///
    /// **default**: suffix: ["", "k", "m", "b", "t"]
    public var suffix = ["", "K", "M", "G", "T"]
    
    /// An appendix text to be added at the end of the formatted value.
    public var appendix: String?
    
    /// Nombre minimum de chiffres représentatifs à afficher = 3
    public var min3digit: Bool = true
    
    public init(appendix  : String? = nil,
                min3digit : Bool) {
        self.appendix  = appendix
        self.min3digit = min3digit
    }
    
    fileprivate func format(value: Double) -> String {
        var sig = value
        var length = 0
        let maxLength = suffix.count - 1
        
        while abs(sig) >= 1000.0 && length < maxLength {
            sig /= 1000.0
            length += 1
        }
        
        var r: String
        if min3digit {
            switch abs(sig) {
                case 0.0:
                    r = String(format: "%.0f", sig) + suffix[length]
                    
                case 0.0..<1.0:
                    r = String(format: "%.3f", sig) + suffix[length]
                    
                case 1.0..<10.0:
                    r = String(format: "%.2f", sig) + suffix[length]
                    
                case 10.0..<100.0:
                    r = String(format: "%.1f", sig) + suffix[length]
                    
                default:
                    r = String(format: "%.0f", sig) + suffix[length]
            }
        } else {
            r = String(format: "%.0f", sig) + suffix[length]
            
        }
        
        if let appendix = appendix {
            r += appendix
        }
        
        return r
    }
    
    public func stringForValue(
        _ value: Double,
        axis: AxisBase?) -> String {
        return format(value: value)
    }
    
    public func stringForValue(
        _ value: Double,
        entry: ChartDataEntry,
        dataSetIndex: Int,
        viewPortHandler: ViewPortHandler?) -> String {
        return format(value: value)
    }
}

public class ExpenseCateroryValueFormatter: NSObject, IAxisValueFormatter {

    // libélés de l'axe X
    var names = [String]()

    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return names[Int(value)]
    }
}

public class IrppValueFormatter: NSObject, IAxisValueFormatter {
    
    // libélés de l'axe X
    var names = SocialAccounts.IrppEnum.allCases.map { $0.displayString }
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return names[Int(value)]
    }
}
