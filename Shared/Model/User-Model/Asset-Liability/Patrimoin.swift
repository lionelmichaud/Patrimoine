//
//  Patrimoine.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 10/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.Patrimoin")

// MARK: - Patrimoine constitué d'un Actif et d'un Passif
final class Patrimoin: ObservableObject {
    
    // MARK: - Static properties
    
    // doit être injecté depuis l'extérieur avant toute instanciation de la classe
    static var family: Family?

    // MARK: - Nested Type

    struct Memento {
        private(set) var assets      : Assets
        private(set) var liabilities : Liabilities
        init(assets      : Assets,
             liabilities : Liabilities) {
            self.assets      = assets
            self.liabilities = liabilities
        }
    }

    // MARK: - Static Methods
    
    /// Définir le mode de simulation à utiliser pour tous les calculs futurs
    /// - Parameter simulationMode: mode de simulation à utiliser
    static func setSimulationMode(to simulationMode : SimulationModeEnum) {
        Assets.setSimulationMode(to: simulationMode)
    }
    
    // MARK: - Properties

    @Published var assets      : Assets
    @Published var liabilities : Liabilities
    var memento: Memento?
    
    // MARK: - Initializers

    init() {
        self.assets      = Assets(with      : Patrimoin.family)
        self.liabilities = Liabilities(with : Patrimoin.family)
        //self.save()
    }

    // MARK: - Methods

    func reload() {
        assets      = Assets(with      : Patrimoin.family)
        liabilities = Liabilities(with : Patrimoin.family)
        memento     = nil
    }
    
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

    /// Sauvegarder l'état courant du Patrimoine
    /// - Warning: Doit être appelée avant toute simulation pouvant affecter le Patrimoine (succession)
    func save() {
        memento = Memento(assets      : assets,
                          liabilities : liabilities)
    }

    /// Recharger les actifs et passifs à partir des de la dernière sauvegarde pour repartir d'une situation initiale sans aucune modification
    /// - Warning: Doit être appelée après toute simulation ayant affectée le Patrimoine (succession)
    func restore() {
        guard let memento = memento else {
            customLog.log(level: .fault, "patrimoine.restore: tentative de restauration d'un patrimoine non sauvegardé")
            fatalError("patrimoine.restore: tentative de restauration d'un patrimoine non sauvegardé")
        }
        assets      = memento.assets
        liabilities = memento.liabilities
    }
    
    /// Capitaliser les intérêts des investissements financiers libres
    /// - Parameters:
    ///   - year: à la fin de cette année
    func capitalizeFreeInvestments(atEndOf year: Int) {
        for idx in 0..<assets.freeInvests.items.count {
            try! assets.freeInvests[idx].capitalize(atEndOf: year)
        }
    }
    
    /// Investir les capitaux dans des actifs financiers détenus en PP par les récipiendaires des capitaux
    /// - Parameters:
    ///   - ownedCapitals: [nom du détenteur, du capital]
    ///   - year: année de l'investissement
    func investCapital(ownedCapitals: [String : Double], // swiftlint:disable:this cyclomatic_complexity
                       atEndOf year : Int) {
        ownedCapitals.forEach { (name, capital) in
            if capital != 0,
               let adult = Patrimoin.family?.member(withName: name) as? Adult,
               adult.isAlive(atEndOf: year) {
                
                // investir en priorité dans une assurance vie
                for idx in 0..<assets.freeInvests.items.count {
                    switch assets.freeInvests[idx].type {
                        case .lifeInsurance(let periodicSocialTaxes, _):
                            if periodicSocialTaxes &&
                                assets.freeInvests[idx].ownership.isAFullOwner(ownerName: name) {
                                // investir la totalité du cash
                                assets.freeInvests[idx].add(capital)
                                return
                            }
                        default: ()
                    }
                }
                for idx in 0..<assets.freeInvests.items.count {
                    switch assets.freeInvests[idx].type {
                        case .lifeInsurance(let periodicSocialTaxes, _):
                            if !periodicSocialTaxes &&
                                assets.freeInvests[idx].ownership.isAFullOwner(ownerName: name) {
                                // investir la totalité du cash
                                assets.freeInvests[idx].add(capital)
                                return
                            }
                        default: ()
                    }
                }
                
                // si pas d'assurance vie alors investir dans un PEA
                for idx in 0..<assets.freeInvests.items.count
                where assets.freeInvests[idx].type == .pea
                    && assets.freeInvests[idx].ownership.isAFullOwner(ownerName: name) {
                    // investir la totalité du cash
                    assets.freeInvests[idx].add(capital)
                    return
                }
                
                // si pas d'assurance vie ni de PEA alors investir dans un autre placement
                for idx in 0..<assets.freeInvests.items.count
                where assets.freeInvests[idx].type == .other
                    && assets.freeInvests[idx].ownership.isAFullOwner(ownerName: name) {
                    // investir la totalité du cash
                    assets.freeInvests[idx].add(capital)
                    return
                }
                
                customLog.log(level: .info, "Il n'y a plus de réceptacle pour receuillir les capitaux reçus par \(name) en \(year)")
                SimulationLogger.shared.log(logTopic: .simulationEvent,
                                            message: "Il n'y a plus de réceptacle pour receuillir les capitaux reçus par \(name) en \(year)")
            }
        }
    }

    /// Ajouter la capacité d'épargne à l'investissement libre de type Assurance vie de meilleur rendement
    /// dont un des adultes est un des PP
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   - amount: capacité d'épargne = montant à investir
    func investNetCashFlow(amount         : Double,
                           for adultsName : [String]) {
        assets.freeInvests.items.sort(by: {$0.averageInterestRate > $1.averageInterestRate})
        
        // investir en priorité dans une assurance vie
        for idx in 0..<assets.freeInvests.items.count {
            switch assets.freeInvests[idx].type {
                case .lifeInsurance(let periodicSocialTaxes, _):
                    if periodicSocialTaxes && amount != 0
                        && assets.freeInvests[idx].isFullyOwned(partlyBy: adultsName) {
                        // investir la totalité du cash
                        assets.freeInvests[idx].add(amount)
                        return
                    }
                default: ()
            }
        }
        for idx in 0..<assets.freeInvests.items.count {
            switch assets.freeInvests[idx].type {
                case .lifeInsurance(let periodicSocialTaxes, _):
                    if !periodicSocialTaxes && amount != 0
                        && assets.freeInvests[idx].isFullyOwned(partlyBy: adultsName) {
                        // investir la totalité du cash
                        assets.freeInvests[idx].add(amount)
                        return
                    }
                default: ()
            }
        }
        
        // si pas d'assurance vie alors investir dans un PEA
        for idx in 0..<assets.freeInvests.items.count
        where assets.freeInvests[idx].type == .pea
            && assets.freeInvests[idx].isFullyOwned(partlyBy: adultsName) {
            // investir la totalité du cash
            assets.freeInvests[idx].add(amount)
            return
        }
        // si pas d'assurance vie ni de PEA alors investir dans un autre placement
        for idx in 0..<assets.freeInvests.items.count
        where assets.freeInvests[idx].type == .other
            && assets.freeInvests[idx].isFullyOwned(partlyBy: adultsName) {
            // investir la totalité du cash
            assets.freeInvests[idx].add(amount)
            return
        }
        
        customLog.log(level: .info, "Il n'y a plus de réceptacle pour receuillir les flux de trésorerie positifs")
        print("Il n'y a plus de réceptacle pour receuillir les flux de trésorerie positifs")
    }
    
    /// Retirer le montant d'un investissement libre: d'abord PEA ensuite Assurance vie puis autre
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   - amount: découvert en fin d'année à combler = montant à désinvestir
    ///   - lifeInsuranceRebate: franchise d'imposition sur les plus values
    ///   - year: année en cours
    /// - Throws: Si pas assez de capital -> CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
    /// - Returns: taxable Interests
    func getCashFromInvestement(thisAmount amount   : Double, // swiftlint:disable:this cyclomatic_complexity
                                atEndOf year        : Int,
                                for adultsName      : [String],
                                taxes               : inout [TaxeCategory: NamedValueTable],
                                lifeInsuranceRebate : inout Double) throws -> Double {
        var amountRemainingToRemove = amount
        var totalTaxableInterests   = 0.0
        
        assets.freeInvests.items.sort(by: {$0.averageInterestRate < $1.averageInterestRate})
        
        // PEA: retirer le montant d'un investissement libre: d'abord le PEA procurant le moins bon rendement
        for idx in 0..<assets.freeInvests.items.count
        where assets.freeInvests[idx].type == .pea
            && (assets.freeInvests[idx].isFullyOwned(partlyBy: adultsName) || adultsName.isEmpty) {
            // tant que l'on a pas retiré le montant souhaité
            // retirer le montant du PEA s'il y en avait assez à la fin de l'année dernière
            if amountRemainingToRemove > 0.0 && assets.freeInvests[idx].value(atEndOf: year-1) > 0.0 {
                let removal = assets.freeInvests[idx].remove(netAmount: amountRemainingToRemove)
                amountRemainingToRemove -= removal.revenue
                // IRPP: les plus values PEA ne sont pas imposables à l'IRPP
                // Prélèvements sociaux: prélevés à la source sur le montant brut du retrait donc pas à payer dans le futur
                if amountRemainingToRemove <= 0.0 { return totalTaxableInterests }
            }
        }
        
        // ASSURANCE VIE: si le solde des PEA n'était pas suffisant alors retirer de l'Assurances vie procurant le moins bon rendement
        for idx in 0..<assets.freeInvests.items.count {
            switch assets.freeInvests[idx].type {
                case .lifeInsurance:
                    // tant que l'on a pas retiré le montant souhaité
                    // retirer le montant de l'Assurances vie s'il y en avait assez à la fin de l'année dernière
                    if amountRemainingToRemove > 0.0 &&
                        assets.freeInvests[idx].value(atEndOf: year-1) > 0.0
                        && (assets.freeInvests[idx].isFullyOwned(partlyBy: adultsName) || adultsName.isEmpty) {
                        let removal = assets.freeInvests[idx].remove(netAmount: amountRemainingToRemove)
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
        
        // AUTRE: retirer le montant d'un investissement libre: d'abord celui procurant le moins bon rendement
        for idx in 0..<assets.freeInvests.items.count
        where assets.freeInvests[idx].type == .other
            && (assets.freeInvests[idx].isFullyOwned(partlyBy: adultsName) || adultsName.isEmpty) {
            // tant que l'on a pas retiré le montant souhaité
            // retirer le montant s'il y en avait assez à la fin de l'année dernière
            if amountRemainingToRemove > 0.0 && assets.freeInvests[idx].value(atEndOf: year-1) > 0.0 {
                let removal = assets.freeInvests[idx].remove(netAmount: amountRemainingToRemove)
                amountRemainingToRemove -= removal.revenue
                // IRPP: les plus values sont imposables à l'IRPP
                totalTaxableInterests += removal.taxableInterests
                // Prélèvements sociaux
                taxes[.socialTaxes]?.namedValues.append((name : assets.freeInvests[idx].name,
                                                         value: removal.socialTaxes))
                
                if amountRemainingToRemove <= 0.0 { return totalTaxableInterests }
            }
        }
        
        if amountRemainingToRemove > 0.0 {
            // on a pas pu retirer suffisament pour couvrir le déficit de cash de l'année
            throw CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
        }
        
        return totalTaxableInterests
    }
}

extension Patrimoin: CustomStringConvertible {
    var description: String {
        """
        PATRIMOINE:
        \(assets.description.withPrefixedSplittedLines("  "))
        \(liabilities.description.withPrefixedSplittedLines("  "))
        """
    }
}
