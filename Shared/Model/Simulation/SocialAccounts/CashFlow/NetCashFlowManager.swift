//
//  NetCashFlowManager.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 21/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.NetCashFlowManager")

struct NetCashFlowManager {
    /// Capitaliser les intérêts des investissements financiers libres
    /// - Parameters:
    ///   - year: à la fin de cette année
    func capitalizeFreeInvestments(in patrimoine : Patrimoin,
                                   atEndOf year  : Int) {
        for idx in 0..<patrimoine.assets.freeInvests.items.count {
            try! patrimoine.assets.freeInvests[idx].capitalize(atEndOf: year)
        }
    }
    
    // swiftlint:disable cyclomatic_complexity
    /// Investir les capitaux dans des actifs financiers détenus en PP par les récipiendaires des capitaux
    /// - Parameters:
    ///   - ownedCapitals: [nom du détenteur, du capital]
    ///   - year: année de l'investissement
    func investCapital(ownedCapitals : [String  : Double],
                       in patrimoine : Patrimoin,
                       atEndOf year  : Int) {
        ownedCapitals.forEach { (name, capital) in
            if capital != 0,
               let adult = Patrimoin.family?.member(withName: name) as? Adult,
               adult.isAlive(atEndOf: year) {
                
                // investir en priorité dans une assurance vie
                for idx in 0..<patrimoine.assets.freeInvests.items.count {
                    switch patrimoine.assets.freeInvests[idx].type {
                        case .lifeInsurance(let periodicSocialTaxes, _):
                            if periodicSocialTaxes &&
                                patrimoine.assets.freeInvests[idx].ownership.isAFullOwner(ownerName: name) {
                                // investir la totalité du cash
                                patrimoine.assets.freeInvests[idx].add(capital)
                                return
                            }
                        default: ()
                    }
                }
                for idx in 0..<patrimoine.assets.freeInvests.items.count {
                    switch patrimoine.assets.freeInvests[idx].type {
                        case .lifeInsurance(let periodicSocialTaxes, _):
                            if !periodicSocialTaxes &&
                                patrimoine.assets.freeInvests[idx].ownership.isAFullOwner(ownerName: name) {
                                // investir la totalité du cash
                                patrimoine.assets.freeInvests[idx].add(capital)
                                return
                            }
                        default: ()
                    }
                }
                
                // si pas d'assurance vie alors investir dans un PEA
                for idx in 0..<patrimoine.assets.freeInvests.items.count
                where patrimoine.assets.freeInvests[idx].type == .pea
                    && patrimoine.assets.freeInvests[idx].ownership.isAFullOwner(ownerName: name) {
                    // investir la totalité du cash
                    patrimoine.assets.freeInvests[idx].add(capital)
                    return
                }
                
                // si pas d'assurance vie ni de PEA alors investir dans un autre placement
                for idx in 0..<patrimoine.assets.freeInvests.items.count
                where patrimoine.assets.freeInvests[idx].type == .other
                    && patrimoine.assets.freeInvests[idx].ownership.isAFullOwner(ownerName: name) {
                    // investir la totalité du cash
                    patrimoine.assets.freeInvests[idx].add(capital)
                    return
                }
                
                customLog.log(level: .info, "Il n'y a plus de réceptacle pour receuillir les capitaux reçus par \(name) en \(year)")
                SimulationLogger.shared.log(logTopic: .simulationEvent,
                                            message: "Il n'y a plus de réceptacle pour receuillir les capitaux reçus par \(name) en \(year)")
            }
        }
    }
    // swiftlint :enable :this cyclomatic_complexity

    /// Ajouter la capacité d'épargne à l'investissement libre de type Assurance vie de meilleur rendement
    /// dont un des adultes est un des PP
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   - amount: capacité d'épargne = montant à investir
    func investNetCashFlow(amount         : Double,
                           in patrimoine  : Patrimoin,
                           for adultsName : [String]) {
        patrimoine.assets.freeInvests.items.sort(by: {$0.averageInterestRate > $1.averageInterestRate})
        
        // investir en priorité dans une assurance vie
        for idx in 0..<patrimoine.assets.freeInvests.items.count {
            switch patrimoine.assets.freeInvests[idx].type {
                case .lifeInsurance(let periodicSocialTaxes, _):
                    if periodicSocialTaxes && amount != 0
                        && patrimoine.assets.freeInvests[idx].isFullyOwned(partlyBy: adultsName) {
                        // investir la totalité du cash
                        patrimoine.assets.freeInvests[idx].add(amount)
                        return
                    }
                default: ()
            }
        }
        for idx in 0..<patrimoine.assets.freeInvests.items.count {
            switch patrimoine.assets.freeInvests[idx].type {
                case .lifeInsurance(let periodicSocialTaxes, _):
                    if !periodicSocialTaxes && amount != 0
                        && patrimoine.assets.freeInvests[idx].isFullyOwned(partlyBy: adultsName) {
                        // investir la totalité du cash
                        patrimoine.assets.freeInvests[idx].add(amount)
                        return
                    }
                default: ()
            }
        }
        
        // si pas d'assurance vie alors investir dans un PEA
        for idx in 0..<patrimoine.assets.freeInvests.items.count
        where patrimoine.assets.freeInvests[idx].type == .pea
            && patrimoine.assets.freeInvests[idx].isFullyOwned(partlyBy: adultsName) {
            // investir la totalité du cash
            patrimoine.assets.freeInvests[idx].add(amount)
            return
        }
        // si pas d'assurance vie ni de PEA alors investir dans un autre placement
        for idx in 0..<patrimoine.assets.freeInvests.items.count
        where patrimoine.assets.freeInvests[idx].type == .other
            && patrimoine.assets.freeInvests[idx].isFullyOwned(partlyBy: adultsName) {
            // investir la totalité du cash
            patrimoine.assets.freeInvests[idx].add(amount)
            return
        }
        
        customLog.log(level: .info, "Il n'y a plus de réceptacle pour receuillir les flux de trésorerie positifs")
        print("Il n'y a plus de réceptacle pour receuillir les flux de trésorerie positifs")
    }
    
    /// Calcule la valeur cumulée des FreeInvestments possédée par une personnne
    /// - Parameters:
    ///   - name: nom de la pesonne
    ///   - year: année d'évaluation
    /// - Returns: valeur cumulée des FreeInvestments possédée
    /// - On ne tient compte que des actifs détenus au moins en partie en PP
    fileprivate func totalFreeInvestementsValue(ownedBy name  : String,
                                                in patrimoine : Patrimoin,
                                                atEndOf year  : Int) -> Double {
        patrimoine.assets.freeInvests.items.reduce(0) { result, freeInvest in
            if freeInvest.ownership.isAFullOwner(ownerName: name) {
                return result + freeInvest.ownedValue(by               : name,
                                                      atEndOf          : year,
                                                      evaluationMethod : .patrimoine)
            } else {
                return result
            }
        }
    }
    
    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_parameter_count
    fileprivate func getCashFlowFromInvestement(in patrimoine             : Patrimoin,
                                                _ name                    : String,
                                                _ year                    : Int,
                                                _ amountRemainingToRemove : inout Double,
                                                _ totalTaxableInterests   : inout Double,
                                                _ lifeInsuranceRebate     : inout Double,
                                                _ taxes                   : inout [TaxeCategory: NamedValueTable]) {
        // PEA: retirer le montant d'un investissement libre: d'abord le PEA procurant le moins bon rendement
        for idx in 0..<patrimoine.assets.freeInvests.items.count
        where patrimoine.assets.freeInvests[idx].type == .pea
            && (name == "" || patrimoine.assets.freeInvests[idx].ownership.isAFullOwner(ownerName: name)) {
            // tant que l'on a pas retiré le montant souhaité
            // retirer le montant du PEA s'il y en avait assez à la fin de l'année dernière
            if amountRemainingToRemove > 0.0 && patrimoine.assets.freeInvests[idx].value(atEndOf: year-1) > 0.0 {
                let removal = patrimoine.assets.freeInvests[idx].remove(netAmount: amountRemainingToRemove)
                amountRemainingToRemove -= removal.revenue
                // IRPP: les plus values PEA ne sont pas imposables à l'IRPP
                // Prélèvements sociaux: prélevés à la source sur le montant brut du retrait donc pas à payer dans le futur
                if amountRemainingToRemove <= 0.0 { break }
            }
        }
        
        // ASSURANCE VIE: si le solde des PEA n'était pas suffisant alors retirer de l'Assurances vie procurant le moins bon rendement
        for idx in 0..<patrimoine.assets.freeInvests.items.count {
            switch patrimoine.assets.freeInvests[idx].type {
                case .lifeInsurance:
                    // tant que l'on a pas retiré le montant souhaité
                    // retirer le montant de l'Assurances vie s'il y en avait assez à la fin de l'année dernière
                    if amountRemainingToRemove > 0.0 &&
                        patrimoine.assets.freeInvests[idx].value(atEndOf: year-1) > 0.0
                        && (name == "" || patrimoine.assets.freeInvests[idx].ownership.isAFullOwner(ownerName: name)) {
                        let removal = patrimoine.assets.freeInvests[idx].remove(netAmount: amountRemainingToRemove)
                        amountRemainingToRemove -= removal.revenue
                        // IRPP: part des produit de la liquidation inscrit en compte courant imposable à l'IRPP après déduction de ce qu'il reste de franchise
                        var taxableInterests: Double
                        // apply rebate if some is remaining
                        taxableInterests = zeroOrPositive(removal.taxableInterests - lifeInsuranceRebate)
                        lifeInsuranceRebate -= (removal.taxableInterests - taxableInterests)
                        // géré comme un revenu en report d'imposition (dette)
                        totalTaxableInterests += taxableInterests
                        // Prélèvements sociaux => prélevés à la source sur le montant brut du retrait donc pas à payer dans le futur
                        if amountRemainingToRemove <= 0.0 { break }
                    }
                default:
                    ()
            }
        }
        
        // AUTRE: retirer le montant d'un investissement libre: d'abord celui procurant le moins bon rendement
        for idx in 0..<patrimoine.assets.freeInvests.items.count
        where patrimoine.assets.freeInvests[idx].type == .other
            && (name == "" || patrimoine.assets.freeInvests[idx].ownership.isAFullOwner(ownerName: name)) {
            // tant que l'on a pas retiré le montant souhaité
            // retirer le montant s'il y en avait assez à la fin de l'année dernière
            if amountRemainingToRemove > 0.0 && patrimoine.assets.freeInvests[idx].value(atEndOf: year-1) > 0.0 {
                let removal = patrimoine.assets.freeInvests[idx].remove(netAmount: amountRemainingToRemove)
                amountRemainingToRemove -= removal.revenue
                // IRPP: les plus values sont imposables à l'IRPP
                totalTaxableInterests += removal.taxableInterests
                // Prélèvements sociaux
                taxes[.socialTaxes]?.namedValues.append((name : patrimoine.assets.freeInvests[idx].name,
                                                         value: removal.socialTaxes))
                
                if amountRemainingToRemove <= 0.0 { break }
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity
    // swiftlint:enable function_parameter_count
    
    // swiftlint:disable function_parameter_count
    /// Retirer le montant d'un investissement libre: d'abord PEA ensuite Assurance vie puis autre
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   - amount: découvert en fin d'année à combler = montant à désinvestir
    ///   - lifeInsuranceRebate: franchise d'imposition sur les plus values
    ///   - year: année en cours
    /// - Throws: Si pas assez de capital -> CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
    /// - Returns: taxable Interests
    func getCashFromInvestement(thisAmount amount   : Double,
                                in patrimoine       : Patrimoin,
                                atEndOf year        : Int,
                                for adultsName      : [String],
                                taxes               : inout [TaxeCategory: NamedValueTable],
                                lifeInsuranceRebate : inout Double) throws -> Double {
        var amountRemainingToRemove = amount
        var totalTaxableInterests   = 0.0
        
        // trier les adultes vivants par ordre de capital décroissant (en termes de FreeInvestement)
        var sortedNames = [String]()
        if adultsName.count > 1 {
            sortedNames = adultsName.sorted {
                totalFreeInvestementsValue(ownedBy: $0,
                                           in: patrimoine,
                                           atEndOf: year) >
                    totalFreeInvestementsValue(ownedBy: $1,
                                               in: patrimoine,
                                               atEndOf: year)
            }
        } else {
            sortedNames = adultsName
        }
        sortedNames.forEach { name in
            print("nom: \(name)")
            print("richesse: \(totalFreeInvestementsValue(ownedBy: name, in: patrimoine, atEndOf: year).rounded())")
        }
        
        patrimoine.assets.freeInvests.items.sort(by: {$0.averageInterestRate < $1.averageInterestRate})
        
        // retirer le cash du capital de la personne la plus riche d'abord
        for name in sortedNames {
            getCashFlowFromInvestement(in: patrimoine,
                                       name,
                                       year,
                                       &amountRemainingToRemove,
                                       &totalTaxableInterests,
                                       &lifeInsuranceRebate,
                                       &taxes)
            if amountRemainingToRemove <= 0 { break }
        }
        
        // Note: s'il n'y a plus d'adulte vivant on prend dans le premier actif qui vient
        // ce sont les héritiers qui payent
        if amountRemainingToRemove > 0.0 && adultsName.count == 0 {
            getCashFlowFromInvestement(in: patrimoine,
                                       "",
                                       year,
                                       &amountRemainingToRemove,
                                       &totalTaxableInterests,
                                       &lifeInsuranceRebate,
                                       &taxes)
        }
        
        if amountRemainingToRemove > 0.0 {
            // on a pas pu retirer suffisament pour couvrir le déficit de cash de l'année
            throw CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
        }
        
        return totalTaxableInterests
    }
    // swiftlint:enable function_parameter_count

}
