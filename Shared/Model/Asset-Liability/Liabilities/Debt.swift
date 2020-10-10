//
//  Liability.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

typealias DebtArray = ItemArray<Debt>

// MARK: - Stock de dette incrémentable ou diminuable
/// stock de dette incrémentable ou diminuable
struct Debt: Codable, Identifiable, NameableValuable {
    
    // properties
    
    var id    = UUID()
    var name  : String
    var note  : String
    var value : Double
    
    // initialization
    
    // methods
    
    /// Valeur résiduelle courante de la dette
    /// - Parameter year: année courante
    func value (atEndOf year: Int) -> Double {
        return value
    }
    mutating func setValue(to value: Double) {
        self.value = value
    }
    mutating func add(amount: Double) {
        value += amount
    }
    mutating func remove(amount: Double) {
        value -= amount
    }
    func print() {
        Swift.print("    ", name)
        Swift.print("       current value: \(value) €")
    }
}

// MARK: Extensions
extension Debt: Comparable {
    static func < (lhs: Debt, rhs: Debt) -> Bool {
        (lhs.name < rhs.name)
    }
}

extension Debt: CustomStringConvertible {
    var description: String {
        return """
        \(name)
        valeur: \(value.€String)
        
        """
    }
}

