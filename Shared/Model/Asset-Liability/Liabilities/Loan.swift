//
//  Loan.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

typealias LoanArray = ItemArray<Loan>

// MARK: - Emprunt à remboursement constant, périodique, annuel et à taux fixe
/// Emprunt à remboursement constant, périodique, annuel et à taux fixe
struct Loan: Codable, Identifiable, NameableAndValueable {
    
    // properties
    
    var id                = UUID()
    var name              : String
    var note              : String
    var firstYear         : Int // au 31 décembre
    var lastYear          : Int // au 31 décembre
    var loanedValue       : Double // negative number
    var interestRate      : Double// %
    var monthlyInsurance  : Double // cout mensuel
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

    // initialization
    
    init(name             : String,
         note             : String,
         firstYear        : Int,
         lastYear         : Int,
         initialValue     : Double,
         interestRate     : Double,
         monthlyInsurance : Double) {
        self.name             = name
        self.note             = note
        self.firstYear        = firstYear
        self.lastYear         = lastYear
        self.loanedValue      = initialValue
        self.interestRate     = interestRate
        self.monthlyInsurance = monthlyInsurance
    }
    
    // methods
    
    /// Montant du remboursement périodique (capital + intérêts)
    /// - Parameter year: année courante
    func yearlyPayement(_ year: Int) -> Double {
        ((firstYear...lastYear).contains(year) ? yearlyPayement : 0.0)
    }
    /// Montant des remboursements restants dûs
    /// - Parameter year: année courante
    func value (atEndOf year: Int) -> Double {
        ((firstYear...lastYear).contains(year) ?
            yearlyPayement * (lastYear - year).double() :
            0.0)
    }
    func print() {
        Swift.print("    ", name)
        Swift.print("       first year:        ", firstYear, "last year: ", lastYear)
        Swift.print("       loaned Value:      ", loanedValue, "final Value:", value(atEndOf: lastYear).rounded())
        Swift.print("       yearly Payement:   ", yearlyPayement.rounded(), "interest Rate: ", interestRate, "%")
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
        return """
        \(name)
        valeur:           \(value(atEndOf: Date.now.year).euroString)
        first year:       \(firstYear) last year: \(lastYear)
        loaned Value:     \(loanedValue) final Value: \(value(atEndOf: lastYear).euroString)
        yearly Payement:  \(yearlyPayement.euroString)
        interest Rate:    \(interestRate) %
        monthly Insurance:\(monthlyInsurance) %

        """
    }
}