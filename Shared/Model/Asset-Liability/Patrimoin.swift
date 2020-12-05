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
    
    @Published var assets      = Assets(family: Patrimoin.family)
    @Published var liabilities = Liabilities()
    
    // MARK: - Methods
    
    func value(atEndOf year: Int) -> Double {
        assets.value(atEndOf: year) +
            liabilities.value(atEndOf: year)
    }
    
    func netValueOfRealEstateAssets(atEndOf year: Int) -> Double {
        assets.valueOfRealEstateAssets(atEndOf: year) +
            liabilities.valueOfLoans(atEndOf: year)
    }
    
    /// Réinitialiser les valeurs courantes des investissements libres
    func resetFreeInvestementCurrentValue() {
        var investements = [FreeInvestement]()
        assets.freeInvests.items.forEach {
            var invest = $0
            invest.resetCurrentState()
            investements.append(invest)
        }
        assets.freeInvests.items = investements
    }
    
    /// Capitaliser les intérêts des investissements financiers libres
    /// - Parameters:
    ///   - year: à la fin de cette année
    func capitalizeFreeInvestments(atEndOf year: Int) {
        var investements = [FreeInvestement]()
        assets.freeInvests.items.forEach {
            var invest = $0
            invest.capitalize(atEndOf: year)
            investements.append(invest)
        }
        assets.freeInvests.items = investements
    }
    
    /// Placer le net cash flow en fin d'année
    /// - Parameters:
    ///   - amount: montant à placer
    ///   - category: dans cette catégories d'actif
    fileprivate func investNetCashFlow(amount      : inout Double,
                                       in category : InvestementType) {
        guard amount != 0 else {
            return
        }
        var investements = [FreeInvestement]()
        assets.freeInvests.items.sorted(by: {$0.interestRate > $1.interestRate}).forEach {
            var invest = $0
            switch invest.type {
                case category:
                    // ajouter le montant à cette assurance vie si cela n'est pas encore fait
                    if amount != 0 {
                        invest.add(amount)
                        amount = 0
                    }
                    // ajouter l'item à la liste après en avoir modifier le montant au besoin
                    investements.append(invest)
                default:
                    // ajouter l'item à la liste sans modification
                    investements.append(invest)
            }
        }
        assets.freeInvests.items = investements
    }
    
    /// Ajouter la capacité d'épargne à l'investissement libre de type Assurance vie de meilleur rendement
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   - amount: capacité d'épargne = montant à investir
    func investNetCashFlow(_ amount: Double) {
        var amount = amount
        // investir en priorité dans une assurance vie
        investNetCashFlow(amount: &amount,
                          in: .lifeInsurance(periodicSocialTaxes: true))
        investNetCashFlow(amount: &amount,
                          in: .lifeInsurance(periodicSocialTaxes: false))
        
        // si pas d'assurance vie alors investir dans un PEA
        investNetCashFlow(amount: &amount, in: .pea)
        
        // si pas d'assurance vie ni de PEA alors investir dans un autre placement
        investNetCashFlow(amount: &amount, in: .other)
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
                               lifeInsuranceRebate : inout Double) throws -> Double  {
        var investements            = [FreeInvestement]()
        var amountRemainingToRemove = amount
        var totalTaxableInterests   = 0.0
        
        // retirer le montant d'un investissement libre: d'abord le PEA procurant le moins bon rendement
        assets.freeInvests.items.sorted(by: {$0.interestRate < $1.interestRate}).forEach {
            var invest = $0
            switch invest.type {
                case .pea:
                    // tant que l'on a pas retiré le montant souhaité
                    if amountRemainingToRemove > 0.0 {
                        // retirer le montant du PEA s'il n'est pas vide
                        if invest.value(atEndOf: year) > 0.0 {
                            let removal = invest.remove(netAmount: amountRemainingToRemove)
                            amountRemainingToRemove -= removal.revenue
                            // IRPP: les plus values PEA ne sont pas imposables à l'IRPP
                            // Prélèvements sociaux: prélevés à la source sur le montant brut du retrait donc pas à payer dans le futur
                        }
                    }
                default:
                    ()
            }
            investements.append(invest)
        }
        assets.freeInvests.items = investements
        
        investements = [FreeInvestement]()
        if amountRemainingToRemove > 0.0 {
            // si le solde des PEA n'était pas suffisant alors retirer de l'Assurances vie procurant le moins bon rendement
            assets.freeInvests.items.sorted(by: {$0.interestRate < $1.interestRate}).forEach {
                var invest = $0
                switch invest.type {
                    case .lifeInsurance(_):
                        // tant que l'on a pas retiré le montant souhaité
                        if amountRemainingToRemove > 0.0 {
                            // retirer le montant de l'Assurances vie si elle n'est pas vide
                            if invest.value(atEndOf: year) > 0.0 {
                                let removal = invest.remove(netAmount: amountRemainingToRemove)
                                amountRemainingToRemove -= removal.revenue
                                // IRPP: part des produit de la liquidation inscrit en compte courant imposable à l'IRPP après déduction de ce qu'il reste de franchise
                                var taxableInterests: Double
                                // apply rebate if some is remaining
                                taxableInterests = max(0.0, removal.taxableInterests - lifeInsuranceRebate)
                                lifeInsuranceRebate -= (removal.taxableInterests - taxableInterests)
                                // géré comme un revenu en report d'imposition (dette)
                                totalTaxableInterests += taxableInterests
                                // Prélèvements sociaux => prélevés à la source sur le montant brut du retrait donc pas à payer dans le futur
                            }
                        }
                    default:
                        ()
                }
                investements.append(invest)
            }
            self.assets.freeInvests.items = investements
        }
        
        // TODO: - Si pas assez alors prendre sur la trésorerie
        
        if amountRemainingToRemove > 0.0 {
            // on a pas pu retirer suffisament pour couvrir le déficit de cash de l'année
            throw CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
        }
        
        return totalTaxableInterests
    }
    
}
