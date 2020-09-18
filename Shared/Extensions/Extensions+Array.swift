//
//  Extensions+Array.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

extension Array where Element: AdditiveArithmetic {
    /// Somme de tous les éléméents d'un Array
    ///
    /// Usage:
    ///
    ///     let doubles = [1.5, 2.7, 3.0]
    ///     doubles.sum()    // 7.2
    ///
    /// - Returns: somme de tous les éléméents du tableau
    ///
    ///  - Note: [Reference](https://stackoverflow.com/questions/24795130/finding-sum-of-elements-in-swift-array)
    func sum () -> Element {
        return reduce(.zero, +)
    }
}

extension Array where Element: SignedNumeric {
    static prefix func - (array: Array<Element>) -> Array<Element> {
        var newArray = Array<Element>()
        for idx in array.indices {
            newArray.append(-array[idx])
        }
        return newArray
    }
}

extension Array {
    /// If you have an array of elements and you want to split them into chunks of a size you specify
    ///
    /// Usage:
    ///
    ///     let numbers = Array(1...100)
    ///     let result = numbers.chunked(into: 5) // Hello, Markdown!
    ///
    /// - Parameters:
    ///     - sdfds: sdfds
    /// - Returns: sdfsdf
    /// - Throws: sdfsdf
    /// - Warning: sdffsd
    ///
    ///  - Note: [Reference](https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks)
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Array {
    func isSorted(_ isOrderedBefore: (Element, Element) -> Bool) -> Bool {
        for i in 1..<self.count {
            if !isOrderedBefore(self[i-1], self[i]) {
                return false
            }
        }
        return true
    }
}
