//
//  Liabilities.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 09/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct Liabilities {

    // MARK: - Properties
    
    var debts : DebtArray
    var loans : LoanArray
    
    // MARK: - Initializers
    
    internal init(family: Family?) {
        self.debts = DebtArray(family: family)
        self.loans = LoanArray(family: family)
    }
    
    // MARK: - Methods
    
    func value(atEndOf year: Int) -> Double {
        loans.items.sumOfValues(atEndOf: year) +
            debts.items.sumOfValues(atEndOf: year)
    }
    
    func valueOfRealEstateLiabilities(atEndOf year     : Int,
                                      evaluationMethod : EvaluationMethod) -> Double {
        switch evaluationMethod {
            case .ifi, .isf :
                /// on prend la valeure IFI des emprunts
                /// pour: adultes + enfants non indépendants
                guard let family = Patrimoin.family else {return 0.0}
                
                var cumulatedvalue: Double = 0.0
                
                for member in family.members {
                    var toBeConsidered : Bool
                    
                    if (member is Adult) {
                        toBeConsidered = true
                    } else if (member is Child) {
                        let child = member as! Child
                        toBeConsidered = !child.isIndependant(during: year)
                    } else {
                        toBeConsidered = false
                    }
                    
                    if toBeConsidered {
                        cumulatedvalue +=
                            loans.ownedValue(by               : member.displayName,
                                             atEndOf          : year,
                                             evaluationMethod : evaluationMethod)
                    }
                }
                return cumulatedvalue
                
            default:
                /// on prend la valeure totale de toutes les emprunts
                return loans.value(atEndOf: year)
        }
    }

    /// Calcule le passif  taxable à la succession d'une personne
    /// - Note: [Reference](https://www.service-public.fr/particuliers/vosdroits/F14198)
    /// - Parameters:
    ///   - year: année d'évaluation
    ///   - thisPerson: personne dont on calcule la succession
    /// - Returns: passif taxable à la succession
    func taxableInheritanceValue(of decedent  : Person,
                                 atEndOf year : Int) -> Double {
        return 0
    }
    func valueOfDebts(atEndOf year: Int) -> Double {
        debts.value(atEndOf: year)
    }
    
    func valueOfLoans(atEndOf year: Int) -> Double {
        loans.value(atEndOf: year)
    }
}
