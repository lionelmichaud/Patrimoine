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
    internal init(family: Family?) {
        self.debts = DebtArray(family: family)
        self.loans = LoanArray(family: family)
    }
    
    // MARK: - Methods
    
    func value(atEndOf year: Int) -> Double {
        loans.items.sumOfValues(atEndOf: year) +
            debts.items.sumOfValues(atEndOf: year)
    }
    
    /// Calcule  la valeur nette taxable du patrimoine immobilier de la famille selon la méthode de calcul choisie
    /// - Parameters:
    ///   - year: année d'évaluation
    ///   - evaluationMethod: méthode d'évalution des biens
    /// - Returns: assiette nette fiscale calculée selon la méthode choisie
    func realEstateValue(atEndOf year     : Int,
                         evaluationMethod : EvaluationMethod) -> Double {
        switch evaluationMethod {
            case .ifi, .isf :
                /// on prend la valeure IFI des emprunts
                /// pour: le foyer fiscal
                return FiscalHousehold.value(atEndOf: year) { name in
                    loans.ownedValue(by               : name,
                                     atEndOf          : year,
                                     evaluationMethod : evaluationMethod)
                }
                
            default:
                /// on prend la valeure totale de toutes les emprunts
                return loans.value(atEndOf: year)
        }
    }

    /// Calcule le passif taxable à la succession d'une personne
    /// - Note: [Reference](https://www.service-public.fr/particuliers/vosdroits/F14198)
    /// - Parameters:
    ///   - year: année d'évaluation
    ///   - decedent: personne dont on calcule la succession
    /// - Returns: passif taxable à la succession
    func taxableInheritanceValue(of decedent  : Person,
                                 atEndOf year : Int) -> Double {
        loans.ownedValue(by               : decedent.displayName,
                         atEndOf          : year,
                         evaluationMethod : .inheritance) +
            debts.ownedValue(by               : decedent.displayName,
                             atEndOf          : year,
                             evaluationMethod : .inheritance)
    }
    
    func valueOfDebts(atEndOf year: Int) -> Double {
        debts.value(atEndOf: year)
    }
    
    func valueOfLoans(atEndOf year: Int) -> Double {
        loans.value(atEndOf: year)
    }
}
