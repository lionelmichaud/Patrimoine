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
    
    /// Charger les passifs stockés en fichier JSON
    /// - Parameter family: famille à laquelle associer le patrimoine
    /// - Note: family est utilisée pour injecter dans chaque passif un délégué family.ageOf
    ///         permettant de calculer les valeurs respectives des Usufruits et Nu-Propriétés
    internal init(with personAgeProvider: PersonAgeProvider?) {
        self.debts = DebtArray(with: personAgeProvider)
        self.loans = LoanArray(with: personAgeProvider)
    }
    
    // MARK: - Methods
    
    func value(atEndOf year: Int) -> Double {
        loans.items.sumOfValues(atEndOf: year) +
            debts.items.sumOfValues(atEndOf: year)
    }
    
    /// Calls the given closure on each element in the sequence in the same order as a for-in loop
    func forEachOwnable(_ body: (Ownable) throws -> Void) rethrows {
        try loans.items.forEach(body)
        try debts.items.forEach(body)
    }
    
    /// Transférer la propriété d'un bien d'un défunt vers ses héritiers en fonction de l'option
    ///  fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    mutating func transferOwnershipOf(decedentName       : String,
                                      chidrenNames       : [String]?,
                                      spouseName         : String?,
                                      spouseFiscalOption : InheritanceDonation.FiscalOption?) {
        for idx in 0..<loans.items.count {
            try! loans.items[idx].ownership.transferOwnershipOf(
                decedentName       : decedentName,
                chidrenNames       : chidrenNames,
                spouseName         : spouseName,
                spouseFiscalOption : spouseFiscalOption)
        }
        for idx in 0..<debts.items.count {
            try! debts.items[idx].ownership.transferOwnershipOf(
                decedentName       : decedentName,
                chidrenNames       : chidrenNames,
                spouseName         : spouseName,
                spouseFiscalOption : spouseFiscalOption)
        }
    }
    
    /// Calcule  la valeur du patrimoine immobilier de la famille selon la méthode de calcul choisie
    /// - Parameters:
    ///   - year: année d'évaluation
    ///   - evaluationMethod: méthode d'évalution des biens
    /// - Returns: assiette nette fiscale calculée selon la méthode choisie
    func realEstateValue(atEndOf year        : Int,
                         for fiscalHousehold : FiscalHouseholdSumator,
                         evaluationMethod    : EvaluationMethod) -> Double {
        switch evaluationMethod {
            case .ifi, .isf :
                /// on prend la valeure IFI des emprunts
                /// pour: le foyer fiscal
                return fiscalHousehold.sum(atEndOf: year) { name in
                    loans.ownedValue(by               : name,
                                     atEndOf          : year,
                                     evaluationMethod : evaluationMethod)
                }
                
            case .legalSuccession, .patrimoine:
                /// on prend la valeure totale de toutes les emprunts
                return loans.value(atEndOf: year)
                
            case .lifeInsuranceSuccession:
                return 0
        }
    }
    
    func valueOfDebts(atEndOf year: Int) -> Double {
        debts.value(atEndOf: year)
    }
    
    func valueOfLoans(atEndOf year: Int) -> Double {
        loans.value(atEndOf: year)
    }
}

extension Liabilities: CustomStringConvertible {
    var description: String {
        """
        PASSIF:
        \(debts.description.withPrefixedSplittedLines("  "))
        \(loans.description.withPrefixedSplittedLines("  "))
        """
    }
}
