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
    
    // if number is less than 1 add 0 before decimal
    numFormatter.minimumIntegerDigits = 1 // how many digits do want before decimal
    numFormatter.multiplier = 0.001
    //numFormatter.thousandSeparator = " "
    //numFormatter.positiveSuffix = " k€"
    //numFormatter.negativeSuffix = " k€"
    numFormatter.paddingPosition = .beforePrefix
    numFormatter.paddingCharacter = "0"
    numFormatter.zeroSymbol = ""
    
    return numFormatter
}()

var valueEuroFormatter: NumberFormatter = {
    let numFormatter = NumberFormatter()
    numFormatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    numFormatter.isLenient = true
    numFormatter.maximumFractionDigits = 0
    numFormatter.numberStyle = .currency
    
    return numFormatter
}()

var percentFormatter: NumberFormatter = {
    let numFormatter = NumberFormatter()
    numFormatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    numFormatter.isLenient = true
    numFormatter.numberStyle = .percent
    numFormatter.minimumIntegerDigits = 1
    numFormatter.maximumIntegerDigits = 3
    numFormatter.minimumFractionDigits = 2
    numFormatter.maximumFractionDigits = 2
    numFormatter.positivePrefix = "+"
    return numFormatter
}()

extension Double {
    var euroString: String {
        valueEuroFormatter.string(from: self as NSNumber) ?? ""
    }
}
