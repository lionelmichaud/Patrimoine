//
//  Patrimoine.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 10/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Patrimoine constitué d'un Actif et d'un Passif
final class Patrimoin: ObservableObject {
    
    // MARK: - Static properties
    
    // doit être injecté depuis l'extérieur avant toute instanciation de la classe
    static var family: Family?
    
    // MARK: - Static Methods
    
    /// Définir le mode de simulation à utiliser pour tous les calculs futurs
    /// - Parameter simulationMode: mode de simulation à utiliser
    static func setSimulationMode(to simulationMode : SimulationModeEnum) {
        Assets.setSimulationMode(to: simulationMode)
    }
    
    // MARK: - Properties
    
    @Published var assets      = Assets(personAgeProvider: Patrimoin.family)
    @Published var liabilities = Liabilities(personAgeProvider: Patrimoin.family)
    
    // MARK: - Methods
    
    func value(atEndOf year: Int) -> Double {
        assets.value(atEndOf: year) +
            liabilities.value(atEndOf: year)
    }
      
    /// Réinitialiser les valeurs courantes des investissements libres
    /// - Warning:
    ///   - Doit être appelée après le chargement d'un objet FreeInvestement depuis le fichier JSON
    ///   - Doit être appelée après toute simulation ayant affectée le Patrimoine (succession)
    func resetFreeInvestementCurrentValue() {
        assets.resetFreeInvestementCurrentValue()
    }
    
    /// Recharger les actifs et passifs à partir des fichiers pour repartir d'une situation initiale sans aucune modification
    /// - Warning: Doit être appelée après toute simulation ayant affectée le Patrimoine (succession)
    func reLoad() {
        assets.reLoad(personAgeProvider: Patrimoin.family)
        liabilities.reLoad(personAgeProvider: Patrimoin.family)
    }
    
    /// Capitaliser les intérêts des investissements financiers libres
    /// - Parameters:
    ///   - year: à la fin de cette année
    func capitalizeFreeInvestments(atEndOf year: Int) {
        for idx in 0..<assets.freeInvests.items.count {
            assets.freeInvests.items[idx].capitalize(atEndOf: year)
        }
    }
    
    /// Ajouter la capacité d'épargne à l'investissement libre de type Assurance vie de meilleur rendement
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   - amount: capacité d'épargne = montant à investir
    func investNetCashFlow(_ amount: Double) {
        assets.freeInvests.items.sort(by: {$0.averageInterestRate > $1.averageInterestRate})
        
        // investir en priorité dans une assurance vie
        for idx in 0..<assets.freeInvests.items.count {
            switch assets.freeInvests.items[idx].type {
                case .lifeInsurance(let periodicSocialTaxes, _):
                    if periodicSocialTaxes && amount != 0 {
                        // investir la totalité du cash
                        assets.freeInvests.items[idx].add(amount)
                        return
                    }
                default: ()
            }
        }
        for idx in 0..<assets.freeInvests.items.count {
            switch assets.freeInvests.items[idx].type {
                case .lifeInsurance(let periodicSocialTaxes, _):
                    if !periodicSocialTaxes && amount != 0 {
                        // investir la totalité du cash
                        assets.freeInvests.items[idx].add(amount)
                        return
                    }
                default: ()
            }
        }
        
        // si pas d'assurance vie alors investir dans un PEA
        for idx in 0..<assets.freeInvests.items.count where assets.freeInvests.items[idx].type == .pea {
            // investir la totalité du cash
            assets.freeInvests.items[idx].add(amount)
            return
        }
        // si pas d'assurance vie ni de PEA alors investir dans un autre placement
        for idx in 0..<assets.freeInvests.items.count where assets.freeInvests.items[idx].type == .other {
            // investir la totalité du cash
            assets.freeInvests.items[idx].add(amount)
            return
        }
    }
    
    /// Retirer le montant d'un investissement libre: d'abord PEA ensuite Assurance vie puis autre
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   - amount: découvert en fin d'année à combler = montant à désinvestir
    ///   - lifeInsuranceRebate: franchise d'imposition sur les plus values
    ///   - year: année en cours
    /// - Throws: Si pas assez de capital -> CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
    /// - Returns: taxable Interests
    func removeFromInvestement(thisAmount amount   : Double,
                               atEndOf year        : Int,
                               lifeInsuranceRebate : inout Double) throws -> Double {
        var amountRemainingToRemove = amount
        var totalTaxableInterests   = 0.0
        
        assets.freeInvests.items.sort(by: {$0.averageInterestRate < $1.averageInterestRate})
        
        // PEA: retirer le montant d'un investissement libre: d'abord le PEA procurant le moins bon rendement
        for idx in 0..<assets.freeInvests.items.count where assets.freeInvests.items[idx].type == .pea {
            // tant que l'on a pas retiré le montant souhaité
            // retirer le montant du PEA s'il y en avait assez à la fin de l'année dernière
            if amountRemainingToRemove > 0.0 && assets.freeInvests.items[idx].value(atEndOf: year-1) > 0.0 {
                let removal = assets.freeInvests.items[idx].remove(netAmount: amountRemainingToRemove)
                amountRemainingToRemove -= removal.revenue
                // IRPP: les plus values PEA ne sont pas imposables à l'IRPP
                // Prélèvements sociaux: prélevés à la source sur le montant brut du retrait donc pas à payer dans le futur
                if amountRemainingToRemove <= 0.0 { return totalTaxableInterests }
            }
        }
        
        // ASSURANCE VIE: si le solde des PEA n'était pas suffisant alors retirer de l'Assurances vie procurant le moins bon rendement
        for idx in 0..<assets.freeInvests.items.count {
            switch assets.freeInvests.items[idx].type {
                case .lifeInsurance:
                    // tant que l'on a pas retiré le montant souhaité
                    // retirer le montant de l'Assurances vie s'il y en avait assez à la fin de l'année dernière
                    if amountRemainingToRemove > 0.0 && assets.freeInvests.items[idx].value(atEndOf: year-1) > 0.0 {
                        let removal = assets.freeInvests.items[idx].remove(netAmount: amountRemainingToRemove)
                        amountRemainingToRemove -= removal.revenue
                        // IRPP: part des produit de la liquidation inscrit en compte courant imposable à l'IRPP après déduction de ce qu'il reste de franchise
                        var taxableInterests: Double
                        // apply rebate if some is remaining
                        taxableInterests = zeroOrPositive(removal.taxableInterests - lifeInsuranceRebate)
                        lifeInsuranceRebate -= (removal.taxableInterests - taxableInterests)
                        // géré comme un revenu en report d'imposition (dette)
                        totalTaxableInterests += taxableInterests
                        // Prélèvements sociaux => prélevés à la source sur le montant brut du retrait donc pas à payer dans le futur
                        if amountRemainingToRemove <= 0.0 { return totalTaxableInterests }
                    }
                default:
                    ()
            }
        }
        
        // TODO: - Si pas assez alors prendre sur la trésorerie
        
        if amountRemainingToRemove > 0.0 {
            // on a pas pu retirer suffisament pour couvrir le déficit de cash de l'année
            throw CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
        }
        
        return totalTaxableInterests
    }
}
