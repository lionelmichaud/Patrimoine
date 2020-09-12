//
//  Financial.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

typealias FreeInvestmentArray = ItemArray<FreeInvestement>

// MARK: - Placement à versement et retrait variable et à taux fixe
/// Placement à versement et retrait libres et à taux fixe
/// Les intérêts sont capitalisés lors de l'appel à capitalize()
struct FreeInvestement: Identifiable, Codable, NameableAndValueable {
    
    // nested types
    
    /// Situation annuelle de l'investissement
    struct State: Codable, Equatable {
        var year       : Int
        var interest   : Double // portion of interests included in the Value
        var investment : Double // portion of investment included in the Value
        var value      : Double { interest + investment } // valeur totale
    }
    
    // properties
    
    var id                 = UUID()
    var name               : String
    var note               : String
    let type               : InvestementType // type de l'investissement
    let interestRate       : Double // % fixe avant charges sociales si prélevées à la source annuellement
    var interestRateNet    : Double { // % fixe après charges sociales si prélevées à la source annuellement
        switch type {
            case .lifeInsurance(let periodicSocialTaxes):
                // si assurance vie: le taux net est le taux brut - charges sociales si celles-ci sont prélèvées à la source anuellement
                return (periodicSocialTaxes ? Fiscal.model.socialTaxesOnFinancialRevenu.net(interestRate) : interestRate)
            default:
                // dans tous les autres cas: pas de charges sociales prélevées à la source anuellement (capitalisation et taxation à la sortie)
                return interestRate
        }
    }
    let initialState       : State // constitution initiale du capital
    var currentState       : State // constitution du capital à l'instant présent
    var cumulatedInterests : Double { currentState.interest } // intérêts cumulés au cours du temps jusqu'à à l'instant présent
    var yearlyInterest     : Double { // intérêts anuels du capital accumulé à l'instant présent
        currentState.value * interestRateNet / 100.0
    }
    
    // initialization
    
    init(year            : Int,
         name            : String,
         note            : String,
         type            : InvestementType,
         rate            : Double,
         initialValue    : Double = 0.0,
         initialInterest : Double = 0.0) {
        self.name         = name
        self.note         = note
        self.type         = type
        self.interestRate = rate
        self.initialState = State(year       : year,
                                  interest   : initialInterest,
                                  investment : initialValue - initialInterest)
        self.currentState = self.initialState
    }
    
    // methods
    
    /// Fractionnement d'un retrait entre: versements cumulés et intérêts cumulés
    /// - Parameter amount: montant du retrait
    func split(removal amount: Double) -> (investement: Double, interest: Double) {
        let deltaInterest   = amount * (currentState.interest / currentState.value)
        let deltaInvestment = amount - deltaInterest
        return (deltaInvestment, deltaInterest)
    }
    
    /// somme des versements + somme des intérêts
    func value(atEndOf year: Int) -> Double {
        guard year == self.currentState.year else {
            // TODO: - revaloriser les intérêts par extraoplation à partir de la dernière année simulée
            return futurValue(payement     : 0,
                              interestRate : interestRateNet/100,
                              nbPeriod     : year - currentState.year,
                              initialValue : currentState.value)
            //return initialState.value
        }
        // valeur de la dernière année simulée
        return currentState.value
    }
    
    /// Réaliser un versement
    /// - Parameter amount: montant du versement
    mutating func add(_ amount: Double) {
        currentState.investment += amount
    }
    
    // Pour obtenir un retrait netAmount NET de charges sociales
    // netAmount:           retrait net de charges sociales souhaité
    // revenue:             retrait net de charges sociales réellement obtenu (= netAmount si le capital est suffisant, moins sinon)
    // interests:           intérêts bruts avant charges sociales
    // netInterests:        intérêts nets de charges sociales
    // taxableInterests:    part des netInterests imposable à l'IRPP
    // socialTaxes:         charges sociales sur les intérêts
    mutating func remove(netAmount: Double) -> (revenue: Double, interests: Double, netInterests: Double, taxableInterests: Double, socialTaxes: Double) {
        guard currentState.value != 0.0 else {
            // le compte est vide: on ne retire rien
            return (revenue: 0, interests: 0, netInterests: 0, taxableInterests: 0, socialTaxes: 0)
        }
        var revenue = netAmount
        var brutAmount: Double
        var brutAmountSplit: (investement: Double, interest: Double)
        var netInterests: Double        // intérêts nets de charges sociales
        var taxableInterests: Double    // part imposable à l'IRPP des intérêts nets de charges sociales
        var socialTaxes: Double // charges sociales sur les intérêts
        switch type {
            case .lifeInsurance(let periodicSocialTaxes):
                // montant brut à retirer pour obtenir le montant net souhaité
                brutAmount = (periodicSocialTaxes ? netAmount : Fiscal.model.socialTaxesOnFinancialRevenu.brut(netAmount))
                // on ne peut pas retirer plus que la capital présent
                if brutAmount > currentState.value {
                    brutAmount = currentState.value
                    revenue    = (periodicSocialTaxes ? brutAmount : Fiscal.model.socialTaxesOnFinancialRevenu.net(brutAmount))
                }
                // parts d'intérêt et de capital contenues dans le brut retiré
                brutAmountSplit = split(removal: brutAmount)
                // intérêts nets de charges sociales
                if periodicSocialTaxes {
                    netInterests = brutAmountSplit.interest
                    socialTaxes  = 0.0
                } else {
                    netInterests = Fiscal.model.socialTaxesOnFinancialRevenu.net(brutAmountSplit.interest)
                    socialTaxes  = Fiscal.model.socialTaxesOnFinancialRevenu.socialTaxes(brutAmountSplit.interest)
                }
                // Assurance vie: les plus values sont imposables à l'IRPP (mais avec une franchise applicable à la totalité des interets retirés dans l'année: calculé ailleurs)
                taxableInterests = netInterests
            case .pea:
                // montant brut à retirer pour obtenir le montant net souhaité
                brutAmount = Fiscal.model.socialTaxesOnFinancialRevenu.brut(netAmount)
                // on ne peut pas retirer plus que la capital présent
                if brutAmount > currentState.value {
                    brutAmount = currentState.value
                    revenue    = Fiscal.model.socialTaxesOnFinancialRevenu.net(brutAmount)
                }
                // parts d'intérêt et de capital contenues dans le brut retiré
                brutAmountSplit = split(removal: brutAmount)
                // intérêts nets de charges sociales
                netInterests = Fiscal.model.socialTaxesOnFinancialRevenu.net(brutAmountSplit.interest)
                socialTaxes  = Fiscal.model.socialTaxesOnFinancialRevenu.socialTaxes(brutAmountSplit.interest)
                // PEA: les plus values ne sont pas imposables à l'IRPP
                taxableInterests = 0.0
            case .other:
                // montant brut à retirer pour obtenir le montant net souhaité
                brutAmount = Fiscal.model.socialTaxesOnFinancialRevenu.brut(netAmount)
                // on ne peut pas retirer plus que la capital présent
                if brutAmount > currentState.value {
                    brutAmount = currentState.value
                    revenue    = Fiscal.model.socialTaxesOnFinancialRevenu.net(brutAmount)
                }
                // parts d'intérêt et de capital contenues dans le brut retiré
                brutAmountSplit = split(removal: brutAmount)
                // intérêts nets de charges sociales
                netInterests = Fiscal.model.socialTaxesOnFinancialRevenu.net(brutAmountSplit.interest)
                socialTaxes  = Fiscal.model.socialTaxesOnFinancialRevenu.socialTaxes(brutAmountSplit.interest)
                // autre cas: les plus values sont totalement imposables à l'IRPP
                taxableInterests = netInterests
        }
        // décrémenter les intérêts et le capital
        if brutAmount == currentState.value {
            // On a vidé le compte: mettre précisémemnt le compte à 0.0 (attention à l'arrondi sinon)
            currentState.interest   = 0
            currentState.investment = 0
        } else {
            // décrémenter le capital (versement et intérêts) du montant brut retiré pour obtenir le net (de charges sociales) souhaité
            currentState.interest -= brutAmountSplit.interest
            currentState.investment -= brutAmountSplit.investement
        }
        
        return (revenue          : revenue,
                interests        : brutAmountSplit.interest,
                netInterests     : netInterests,
                taxableInterests : taxableInterests,
                socialTaxes      : socialTaxes)
    }
    
    /// Capitaliser les intérêts d'une année: à faire une fois par an et apparaissent dans l'année courante
    mutating func capitalize(atEndOf year: Int) {
        currentState.interest += yearlyInterest
        currentState.year = year
    }
    
    /// Remettre la valeur courante à la valeur initiale
    mutating func resetCurrentValue() {
        currentState = initialState
    }

    func print() {
        Swift.print("    ", name)
        Swift.print("       type", type)
        Swift.print("       interest Rate: ", interestRate, "%")
        Swift.print("       year:     ", currentState.year, "value: ", currentState.value)
        Swift.print("       investement: ", currentState.investment, "interest: ", currentState.interest)
    }
}

// MARK: Extensions
extension FreeInvestement: Comparable {
    static func < (lhs: FreeInvestement, rhs: FreeInvestement) -> Bool {
        return (lhs.name < rhs.name)
    }
}

extension FreeInvestement: CustomStringConvertible {
    var description: String {
        return """
        \(name)
        valeur:        \(value(atEndOf: Date.now.year).euroString)
        type:          \(type)
        year:          \(currentState.year) Value: \(currentState.value.euroString)
        investement:   \(currentState.investment.euroString) interest: \(currentState.interest.euroString)
        interest Rate: \(interestRate) %
        
        """
    }
}

