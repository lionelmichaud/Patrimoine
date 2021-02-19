//
//  Extensions+String.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

extension String {
    /// Counting words in a string
    ///
    /// Usage:
    ///
    ///     let phrase = "The rain in Spain"
    ///     print(phrase.wordCount)
    ///
    ///  - Note: [Reference](https://www.hackingwithswift.com/articles/141/8-useful-swift-extensions)
    var wordCount: Int {
        let regex = try? NSRegularExpression(pattern: "\\w+")
        return regex?.numberOfMatches(in: self, range: NSRange(location: 0, length: self.utf16.count)) ?? 0
    }
    
    /// Replacing a fix number of substrings
    ///
    /// Usage:
    ///
    ///     let phrase = "How much wood would a woodchuck chuck if a woodchuck would chuck wood?"
    ///     print(phrase.replacingOccurrences(of: "would", with: "should", count: 1))
    ///
    /// - Parameters:
    ///   - search: string to search
    ///   - replacement: replacement string
    ///   - maxReplacements: number of occurences
    /// - Returns: new String
    ///
    ///  - Note: [Reference](https://www.hackingwithswift.com/articles/141/8-useful-swift-extensions)
    func replacingOccurrences(of search: String, with replacement: String, count maxReplacements: Int) -> String {
        var count = 0
        var returnValue = self
        
        while let range = returnValue.range(of: search) {
            returnValue = returnValue.replacingCharacters(in: range, with: replacement)
            count += 1
            
            // exit as soon as we've made all replacements
            if count == maxReplacements {
                return returnValue
            }
        }
        return returnValue
    }
    
    /// Truncating with ellipsis
    ///
    /// Usage:
    ///
    ///     let testString = "He thrusts his fists against the posts and still insists he sees the ghosts."
    ///     print(testString.truncate(to: 20, addEllipsis: true))
    ///
    /// - Parameters:
    ///   - length: tronquer audelà de cette longeur
    ///   - addEllipsis: ajouter elipse à la fin
    /// - Returns: new String
    ///
    ///  - Note: [Reference](https://www.hackingwithswift.com/articles/141/8-useful-swift-extensions)
    func truncate(to length: Int, addEllipsis: Bool = false) -> String {
        if length > count { return self }
        
        let endPosition = self.index(self.startIndex, offsetBy: length)
        let trimmed = self[..<endPosition]
        
        if addEllipsis {
            return "\(trimmed)..."
        } else {
            return String(trimmed)
        }
    }
    
    /// Adding a prefix to a string
    ///
    /// Usage:
    ///
    ///     let url = "www.hackingwithswift.com"
    ///     let fullURL = url.withPrefix("https://")
    ///
    /// - Parameters:
    ///     - prefix: préfix à jouter en début
    /// - Returns: new String
    ///
    ///  - Note: [Reference](https://www.hackingwithswift.com/articles/141/8-useful-swift-extensions)
    func withPrefix(_ prefix: String) -> String {
        if self.hasPrefix(prefix) { return self }
        return "\(prefix)\(self)"
    }
    
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    mutating func trim() {
        self = self.trimmed
    }

    func toDate(format: String) -> Date? {
        let df = DateFormatter()
        df.dateFormat = format
        return df.date(from: self)
    }

    var asURL: URL? {
        URL(string: self)
    }

//    let digitsOnlyYes = "1234567890".containsOnlyDigits
//    let digitsOnlyNo = "12345+789".containsOnlyDigits
    var containsOnlyDigits: Bool {
        let notDigits = NSCharacterSet.decimalDigits.inverted
        return rangeOfCharacter(from: notDigits, options: String.CompareOptions.literal, range: nil) == nil
    }

//    let alphanumericYes = "asd3kJh43saf".isAlphanumeric
//    let alphanumericNo = "Kkncs+_s3mM.".isAlphanumeric
    var isAlphanumeric: Bool {
        !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }

}

extension String {
//    let subscript1 = "Hello, world!"[7...]
//    let subscript2 = "Hello, world!"[7...11]

    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    subscript (bounds: CountableRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        if end < start { return "" }
        return self[start..<end]
    }
    
    subscript (bounds: CountableClosedRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        if end < start { return "" }
        return self[start...end]
    }
    
    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        if end < start { return "" }
        return self[start...end]
    }
    
    subscript (bounds: PartialRangeThrough<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        if end < startIndex { return "" }
        return self[startIndex...end]
    }
    
    subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        if end < startIndex { return "" }
        return self[startIndex..<end]
    }
}

extension String {
    var splittedLines: [String] {
        split(separator: "\n", omittingEmptySubsequences: false).map {String($0)}
    }
    func withPrefixedSplittedLines(_ prefix: String) -> [String] {
        splittedLines.withPrefix(prefix)
    }
    func withPrefixedSplittedLines(_ prefix: String) -> String {
        let string = splittedLines.withPrefix(prefix).reduce("", { r, s in r + s + "\n" })
        return String(string.dropLast(1))
    }
}

extension Array where Element == String {
    func withPrefix(_ prefix: String) -> [String] {
        self.map { prefix + $0 }
    }
}
