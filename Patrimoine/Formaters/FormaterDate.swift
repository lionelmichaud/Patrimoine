//
//  FormaterDate.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

var longDateFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .none
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()

var mediumDateFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()

var shortDateFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()

var dayMonthLongFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "ddMMMM" // format Janv., Fevr., Mars
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()

var dayMonthMediumFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd/MMM" // format Janv., Fevr., Mars
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()

var dayMonthShortFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd/MM" // format Janv., Fevr., Mars
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()

var monthLongFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM" // format January, February, March
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()

var monthMediumFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM" // format Janv., Fevr., Mars
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()

var monthShortFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM" // format 01, 02, 03
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()
