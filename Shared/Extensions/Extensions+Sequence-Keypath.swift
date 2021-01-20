//
//  Extensions+Sequence-Keypath.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - quickly sum any nested numbers within a sequence
extension Sequence {
    /// Compute sum of all elements in a sequence using keypah
    ///
    /// Usage:
    ///
    ///     let articlePrices = articles.sum(\.price)
    ///
    /// - Parameter keyPath
    /// - Returns: Sum of all elements
    ///
    ///  - Note: [Reference](https://www.swiftbysundell.com/articles/the-power-of-key-paths-in-swift/)
    func sum<T: Numeric>(for keyPath: KeyPath<Element, T>) -> T {
        return reduce(0) { sum, element in
            sum + element[keyPath: keyPath]
        }
    }
    
    func firstHigerOrEqual<T: Comparable>(than value: T, in keyPath: KeyPath<Element, T>) -> Element? {
        return first(where: { value <= $0[keyPath: keyPath] })
    }
    
    /// Perform elements extraction from a sequence using keypah
    ///
    /// Usage:
    ///
    ///     let articleIDs = articles.map(\.id)
    ///     let articleSources = articles.map(\.source)
    ///
    /// - Parameter keyPath
    /// - Returns: Sequence of extracted elements
    ///
    ///  - Note: [Reference](https://www.swiftbysundell.com/articles/the-power-of-key-paths-in-swift/)
    func map<T>(_ keyPath: KeyPath<Element, T>) -> [T] {
        return map { $0[keyPath: keyPath] }
    }
    
    /// Sorts elements in a sequence using keypah
    ///
    /// Usage:
    ///
    ///     playlist.songs.sorted(by: \.name)
    ///     playlist.songs.sorted(by: \.dateAdded)
    ///     playlist.songs.sorted(by: \.ratings.worldWide)
    ///
    /// - Parameter keyPath
    /// - Returns: Sorted sequence
    ///
    ///  - Note: [Reference](https://www.swiftbysundell.com/articles/the-power-of-key-paths-in-swift/)
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        return sorted { a, b in
            return a[keyPath: keyPath] < b[keyPath: keyPath]
        }
    }
    func sortedReversed<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        return sorted { a, b in
            return a[keyPath: keyPath] > b[keyPath: keyPath]
        }
    }
}

extension Array {
    /// Usage:
    ///
    ///     let found = articles.first(\.price, <=, 10.0)
    ///
    func first<T: Comparable>(_ keyPath: KeyPath<Element, T>, _ f: (T, T) -> Bool, _ value: T) -> Element? {
        return first(where: { f($0[keyPath: keyPath], value) })
    }
    
    /// Usage:
    ///
    ///     let found = articles.first(\.price, <=, 10.0)
    ///
    func last<T: Comparable>(_ keyPath: KeyPath<Element, T>, _ f: (T, T) -> Bool, _ value: T) -> Element? {
        return last(where: { f($0[keyPath: keyPath], value) })
    }
    
    /// Usage:
    ///
    ///     let found = articles.first(\.item, where: \.price, <=, 10.0)
    ///
    func last<T: Comparable, U>(_ keyPath1: KeyPath<Element, U>, where keyPath: KeyPath<Element, T>, _ f: (T, T) -> Bool, _ value: T) -> U? {
        if let last = last(where: { f($0[keyPath: keyPath], value) }) {
            return last[keyPath: keyPath1]
        } else {
            return nil
        }
    }
    
}
