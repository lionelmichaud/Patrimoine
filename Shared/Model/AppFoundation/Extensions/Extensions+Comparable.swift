//
//  Extensions+Comparable.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

extension Comparable {
    /// Clamping is the practice of forcing a value to fall within a specific range.
    /// - Parameters:
    ///   - low: lower bound
    ///   - high: upper bound
    /// - Returns: clamped value
    /// Clamping is the practice of forcing a value to fall within a specific range
    ///
    /// Usage:
    ///
    ///     let number2 = 5.0
    ///     print(number2.clamp(low: 0, high: 10))
    ///     print(number2.clamp(low: 0, high: 3))
    ///     let letter1 = "r"
    ///     print(letter1.clamp(low: "a", high: "f"))
    ///
    /// - Parameters:
    ///   - low: lower bound
    ///   - high: upper bound
    /// - Returns: clamped value
    ///
    ///  - Note: [Reference](https://www.hackingwithswift.com/articles/141/8-useful-swift-extensions)
    func clamp(low: Self, high: Self) -> Self {
        if self > high {
            return high
        } else if self < low {
            return low
        }
        
        return self
    }
}
