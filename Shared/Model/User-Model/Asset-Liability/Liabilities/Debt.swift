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
struct Debt: Codable, Identifiable, NameableValuable, Ownable {
    
    // MARK: - Properties

    var id    = UUID()
    var name  : String = ""
    var note  : String = ""
    // propriétaires
    // attention: par défaut la méthode delegate pour ageOf = nil
    // c'est au créateur de l'objet (View ou autre objet du Model) de le faire
    var ownership : Ownership = Ownership()
    var value     : Double
    
    // MARK: - Initializers

    // MARK: - Methods

    /// Valeur résiduelle courante de la dette
    /// - Parameter year: année courante
    func value (atEndOf year: Int) -> Double {
        return value
    }
    mutating func setValue(to value: Double) {
        self.value = value
    }
    mutating func increase(by thisAmount: Double) {
        value += thisAmount
    }
    mutating func decrease(by thisAmount: Double) {
        value -= thisAmount
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
        Dette: \(name)
          valeur: \(value.€String)
        
        """
    }
}
