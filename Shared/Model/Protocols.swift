//
//  Protocols.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: Protocol
protocol NameableAndValueable {
    var name: String { get }
    func value(atEndOf year: Int) -> Double
    func print()
}

extension Array where Element: NameableAndValueable {
    /// Somme de toutes les valeurs d'un Array
    ///
    /// Usage:
    ///
    ///     items.sum(atEndOf: 2020)
    ///
    /// - Returns: Somme de toutes les valeurs d'un Array
    func sum (atEndOf year: Int) -> Double {
        return reduce(.zero, {result, element in result + element.value(atEndOf: year)})
    }
}

protocol PickableEnum: CaseIterable, Hashable {
    var pickerString: String { get }
    var displayString: String { get }
}

extension PickableEnum {
    // default implementation
    var displayString: String { pickerString }
}

protocol PickableIdentifiableEnum: PickableEnum, Identifiable {
}

protocol Versionable {
    var version : Version { get set }
}
