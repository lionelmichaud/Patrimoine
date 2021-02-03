//
//  FormaterNimber.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

var valueKiloFormatter: NumberFormatter = {
    let numFormatter = NumberFormatter()
    
    numFormatter.locale                = Locale(identifier : "fr_FR") // French Locale (fr_FR)
    // if number is less than 1 add 0 before decimal
    numFormatter.minimumIntegerDigits = 1 // how many digits do want before decimal
    numFormatter.multiplier           = 0.001
    numFormatter.paddingPosition      = .beforePrefix
    numFormatter.paddingCharacter     = "0"
    numFormatter.zeroSymbol           = ""
    return numFormatter
}()

var valueKilo€Formatter: NumberFormatter = {
    let numFormatter = NumberFormatter()
    
    numFormatter.locale                = Locale(identifier : "fr_FR") // French Locale (fr_FR)
    // if number is less than 1 add 0 before decimal
    numFormatter.minimumIntegerDigits = 1 // how many digits do you want before decimal point
    // numFormatter.maximumFractionDigits = 1 // how many digits do you want after decimal point
    numFormatter.multiplier           = 0.001
    // numFormatter.thousandSeparator  = " "
    numFormatter.positiveSuffix       = " k€"
    numFormatter.negativeSuffix       = " k€"
    numFormatter.paddingPosition      = .beforePrefix
    numFormatter.paddingCharacter     = "0"
    numFormatter.zeroSymbol           = "-"
    return numFormatter
}()

var value€Formatter: NumberFormatter = {
    let numFormatter = NumberFormatter()
    numFormatter.locale                = Locale(identifier : "fr_FR") // French Locale (fr_FR)
    numFormatter.isLenient             = true
    numFormatter.maximumFractionDigits = 0
    numFormatter.numberStyle           = .currency
    return numFormatter
}()

var percentFormatter: NumberFormatter = {
    let numFormatter = NumberFormatter()
    numFormatter.locale                = Locale(identifier : "fr_FR") // French Locale (fr_FR)
    numFormatter.isLenient             = true
    numFormatter.numberStyle           = .percent
    numFormatter.minimumIntegerDigits  = 1
    numFormatter.maximumIntegerDigits  = 3
    numFormatter.minimumFractionDigits = 2
    numFormatter.maximumFractionDigits = 2
    // numFormatter.positivePrefix      = "+"
    return numFormatter
}()

var percentIntegerFormatter: NumberFormatter = {
    let numFormatter = NumberFormatter()
    numFormatter.locale                = Locale(identifier : "fr_FR") // French Locale (fr_FR)
    numFormatter.isLenient             = true
    numFormatter.numberStyle           = .percent
    numFormatter.minimumIntegerDigits  = 1
    numFormatter.maximumIntegerDigits  = 3
    numFormatter.minimumFractionDigits = 0
    numFormatter.maximumFractionDigits = 0
    // numFormatter.positivePrefix      = "+"
    return numFormatter
}()

var decimalFormatter: NumberFormatter = {
    let numFormatter = NumberFormatter()
    numFormatter.locale                = Locale(identifier : "fr_FR") // French Locale (fr_FR)
    numFormatter.isLenient             = true
    numFormatter.numberStyle           = .decimal
    numFormatter.minimumIntegerDigits  = 1
    numFormatter.minimumFractionDigits = 2
    numFormatter.maximumFractionDigits = 2
    // numFormatter.positivePrefix      = "+"
    return numFormatter
}()

var decimalIntegerFormatter: NumberFormatter = {
    let numFormatter = NumberFormatter()
    numFormatter.locale                = Locale(identifier : "fr_FR") // French Locale (fr_FR)
    numFormatter.isLenient             = true
    numFormatter.numberStyle           = .decimal
    numFormatter.minimumIntegerDigits  = 1
    numFormatter.minimumFractionDigits = 0
    numFormatter.maximumFractionDigits = 0
    // numFormatter.positivePrefix      = "+"
    return numFormatter
}()

var decimalX100IntegerFormatter: NumberFormatter = {
    let numFormatter = NumberFormatter()
    numFormatter.locale                = Locale(identifier : "fr_FR") // French Locale (fr_FR)
    numFormatter.isLenient             = true
    numFormatter.numberStyle           = .decimal
    numFormatter.multiplier            = 100.0
    numFormatter.minimumIntegerDigits  = 1
    numFormatter.minimumFractionDigits = 0
    numFormatter.maximumFractionDigits = 0
    // numFormatter.positivePrefix      = "+"
    return numFormatter
}()

extension Double {
    var €String: String {
        value€Formatter.string(from: self as NSNumber) ?? ""
    }
    
    var k€String: String {
        valueKilo€Formatter.string(from: self as NSNumber) ?? ""
    }

    var percentStringRounded: String {
        percentIntegerFormatter.string(from: self as NSNumber) ?? ""
    }
    
    func percentString(digit: Int = 0) -> String {
        guard digit >= 0 else {
            return "??"
        }
        let numFormatter = NumberFormatter()
        numFormatter.locale                = Locale(identifier : "fr_FR") // French Locale (fr_FR)
        numFormatter.isLenient             = true
        numFormatter.numberStyle           = .decimal
        numFormatter.minimumIntegerDigits  = 1
        numFormatter.maximumIntegerDigits  = 3
        numFormatter.minimumFractionDigits = 0
        numFormatter.maximumFractionDigits = digit
        return numFormatter.string(from: self as NSNumber) ?? ""
    }
}
