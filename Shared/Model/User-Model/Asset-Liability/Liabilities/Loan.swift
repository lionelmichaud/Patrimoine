//
//  Loan.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

typealias LoanArray = ArrayOfNameableValuable<Loan>

// MARK: - Emprunt à remboursement constant, périodique, annuel et à taux fixe

/// Emprunt à remboursement constant, périodique, annuel et à taux fixe
struct Loan: Codable, Identifiable, NameableValuable, Ownable {
    
    // MARK: - Properties

    var id                = UUID()
    var name              : String = ""
    var note              : String = ""
    // propriétaires
    // attention: par défaut la méthode delegate pour ageOf = nil
    // c'est au créateur de l'objet (View ou autre objet du Model) de le faire
    var ownership            : Ownership = Ownership()

    var firstYear         : Int // au 31 décembre
    var lastYear          : Int // au 31 décembre
    var loanedValue       : Double = 0 // negative number
    var interestRate      : Double = 0// %
    var monthlyInsurance  : Double = 0 // cout mensuel
    private var nbPeriod  : Int {
        (lastYear - firstYear + 1)
    }
    private var yearlyPayement: Double {
        loanPayement(loanedValue  : loanedValue,
                     interestRate : interestRate/100.0,
                     nbPeriod     : nbPeriod) +
        12 * monthlyInsurance
    }
    var totalPayement     : Double {
        yearlyPayement * nbPeriod.double()
    }
    var costOfCredit      : Double {
        totalPayement + loanedValue
    }

    // MARK: - Initializers

    // MARK: - Methods

    /// Montant du remboursement périodique (capital + intérêts)
    /// - Parameter year: année courante
    func yearlyPayement(_ year: Int) -> Double {
        ((firstYear...lastYear).contains(year) ? yearlyPayement : 0.0)
    }
    /// Montant des remboursements restants dûs
    /// - Parameter year: année courante
    func value(atEndOf year: Int) -> Double {
        ((firstYear...lastYear).contains(year) ?
            yearlyPayement * (lastYear - year).double() :
            0.0)
    }
}

// MARK: Extensions
extension Loan: Comparable {
    static func < (lhs: Loan, rhs: Loan) -> Bool {
        (lhs.name < rhs.name)
    }
}

extension Loan: CustomStringConvertible {
    var description: String {
        """
        EMPRUNT: \(name)
        - Note:
        \(note.withPrefixedSplittedLines("    "))
        - Droits de propriété:
        \(ownership.description.withPrefixedSplittedLines("  "))
        - valeur(\(Date.now.year): \(value(atEndOf: Date.now.year).€String)
        - first year:       \(firstYear) last year: \(lastYear)
        - loaned Value:     \(loanedValue) final Value: \(value(atEndOf: lastYear).€String)
        - yearly Payement:  \(yearlyPayement.€String)
        - interest Rate:    \(interestRate) %
        - monthly Insurance:\(monthlyInsurance) %
        """
    }
}
