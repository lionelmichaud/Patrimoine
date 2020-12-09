//
//  Financial.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

fileprivate let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.FreeInvestement")

typealias FreeInvestmentArray = ItemArray<FreeInvestement>

// MARK: - Placement à versement et retrait variable et à taux fixe

/// Placement à versement et retrait libres et à taux fixe
/// Les intérêts sont capitalisés lors de l'appel à capitalize()
struct FreeInvestement: Identifiable, Codable, NameableValuable, Ownable {
    
    // nested types
    
    /// Situation annuelle de l'investissement
    struct State: Codable, Equatable {
        var year       : Int
        var interest   : Double // portion of interests included in the Value
        var investment : Double // portion of investment included in the Value
        var value      : Double { interest + investment } // valeur totale
    }
    
    // MARK: - Static Properties
    
    static var simulationMode : SimulationModeEnum = .deterministic
    
    // MARK: - Static Methods
    
    private static var inflation: Double { // %
        Economy.model.inflation.value(withMode: simulationMode)
    }
    
    /// taux à long terme - rendement d'un fond en euro
    private static var longTermRate: Double { // %
        Economy.model.longTermRate.value(withMode: simulationMode)
    }
    
    /// rendement des actions
    private static var stockRate: Double { // %
        Economy.model.stockRate.value(withMode: simulationMode)
    }
    
    // MARK: - Properties

    var id                   = UUID()
    var name                 : String
    var note                 : String
    // propriétaires
    // attention: par défaut la méthode delegate pour ageOf = nil
    // c'est au créateur de l'objet (View ou autre objet du Model) de le faire
    var ownership            : Ownership = Ownership()
    var type                 : InvestementType // type de l'investissement
    var interestRateType     : InterestRateType // type de taux de rendement
    var interestRate         : Double {// % avant charges sociales si prélevées à la source annuellement
        switch interestRateType {
            case .contractualRate( let fixedRate):
                return fixedRate - FreeInvestement.inflation
                
            case .marketRate(let stockRatio):
                let stock = stockRatio / 100.0
                // taux d'intérêt composite fonction de la composition du portefeuille
                let rate = stock * FreeInvestement.stockRate + (1.0 - stock) * FreeInvestement.longTermRate
                return rate - FreeInvestement.inflation
        }
    }
    var interestRateNet      : Double { // % fixe après charges sociales si prélevées à la source annuellement
        switch type {
            case .lifeInsurance(let periodicSocialTaxes):
                // si assurance vie: le taux net est le taux brut - charges sociales si celles-ci sont prélèvées à la source anuellement
                return (periodicSocialTaxes ?
                            Fiscal.model.socialTaxesOnFinancialRevenu.net(interestRate) :
                            interestRate)
            default:
                // dans tous les autres cas: pas de charges sociales prélevées à la source anuellement (capitalisation et taxation à la sortie)
                return interestRate
        }
    }
    var initialState         : State {// dernière constitution du capital connue
        didSet {
            resetCurrentState()
        }
    }
    private var currentState : State // constitution du capital à l'instant présent
    var cumulatedInterests   : Double { currentState.interest } // intérêts cumulés au cours du temps jusqu'à à l'instant présent
    var yearlyInterest       : Double { // intérêts anuels du capital accumulé à l'instant présent
        currentState.value * interestRateNet / 100.0
    }
    
    // MARK: - Initialization

    init(year             : Int,
         name             : String,
         note             : String,
         type             : InvestementType,
         interestRateType : InterestRateType,
         initialValue     : Double = 0.0,
         initialInterest  : Double = 0.0) {
        self.name             = name
        self.note             = note
        self.type             = type
        self.interestRateType = interestRateType
        self.initialState     = State(year       : year,
                                      interest   : initialInterest,
                                      investment : initialValue - initialInterest)
        self.currentState     = self.initialState
    }
    
    // MARK: - Methods

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
            // revaloriser la valeur par extrapolation à partir de la situation initiale
            return futurValue(payement     : 0,
                              interestRate : interestRateNet/100,
                              nbPeriod     : year - initialState.year,
                              initialValue : initialState.value)
        }
        // valeur de la dernière année simulée
        return currentState.value
    }
    
    /// Calcule la valeur d'un bien possédée par un personne donnée à une date donnée
    /// selon la régle générale ou selon la règle de l'IFI, de l'ISF, de la succession...
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - year: date d'évaluation
    ///   - evaluationMethod: méthode d'évaluation de la valeure des bien
    /// - Returns: valeur du bien possédée (part d'usufruit + part de nue-prop)
    /// - Warning: les assurance vie ne sont pas inclues car hors succession
    func ownedValue(by ownerName     : String,
                    atEndOf year     : Int,
                    evaluationMethod : EvaluationMethod) -> Double {
        var evaluatedValue : Double
        Swift.print("  Actif: \(name)")

        switch evaluationMethod {
            case .inheritance:
                // le bien est-il une assurance vie ?
                switch type {
                    case .lifeInsurance( _):
                        // les assurance vie ne sont pas inclues car hors succession
                        Swift.print("  valeur: 0")
                        return 0

                    default:
                        // le défunt est-il usufruitier ?
                        if ownership.isAnUsufructOwner(ownerName: ownerName) {
                            // si oui alors l'usufruit rejoint la nu-propriété sans droit de succession
                            // l'usufruit n'est donc pas intégré à la masse successorale du défunt
                            Swift.print("  valeur: 0")
                            return 0
                        }
                        // pas de décote
                        evaluatedValue = value(atEndOf: year)
                }

            default:
                // pas de décote
                evaluatedValue = value(atEndOf: year)
        }
        // calculer la part de propriété
        let value = evaluatedValue == 0 ? 0 : ownership.ownedValue(by               : ownerName,
                                                                   ofValue          : evaluatedValue,
                                                                   atEndOf          : year,
                                                                   evaluationMethod : evaluationMethod)
        Swift.print("  valeur: \(value)")
        return value
    }
    
    /// Réaliser un versement
    /// - Parameter amount: montant du versement
    mutating func add(_ amount: Double) {
        currentState.investment += amount
    }
    
    //
    /// Pour obtenir un retrait netAmount NET de charges sociales
    /// - Parameter netAmount: retrait net de charges sociales souhaité
    /// - Returns:
    /// revenue:             retrait net de charges sociales réellement obtenu (= netAmount si le capital est suffisant, moins sinon)
    /// interests:           intérêts bruts avant charges sociales
    /// netInterests:        intérêts nets de charges sociales
    /// taxableInterests:    part des netInterests imposable à l'IRPP
    /// socialTaxes:         charges sociales sur les intérêts
    mutating func remove(netAmount: Double)
    -> (revenue: Double,
        interests: Double,
        netInterests: Double,
        taxableInterests: Double,
        socialTaxes: Double) {
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
    mutating func resetCurrentState() {
        // calculer la valeur de currentState à la date de fin d'année passée
        let estimationYear = Date.now.year - 1
        if estimationYear == initialState.year {
            currentState = initialState
            
        } else if estimationYear > initialState.year {
            // revaloriser la valeure par extrapolation à partir de la situation initiale
            let futurVal = futurValue(payement     : 0,
                                      interestRate : interestRateNet/100,
                                      nbPeriod     : estimationYear - initialState.year,
                                      initialValue : initialState.value)
            currentState.year       = estimationYear
            currentState.investment = initialState.investment
            currentState.interest   = initialState.interest + (futurVal - initialState.value)
            
        } else {
            // on ne remonte pas le temps
            customLog.log(level: .fault,
                          "didSet: estimationYear (\(estimationYear, privacy: .public)) < initialState.year")
            fatalError("didSet: estimationYear (\(estimationYear)) < initialState.year (\(initialState.year))")
        }
//        currentState = initialState
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
          type:          \(type)
          valeur:        \(value(atEndOf: Date.now.year).€String)
          initial state: (year: \(initialState.year), interest: \(initialState.interest.€String), invest: \(initialState.investment.€String), Value: \(initialState.value.€String))
          current state: (year: \(currentState.year), interest: \(currentState.interest.€String), invest: \(currentState.investment.€String), Value: \(currentState.value.€String))
          interest Rate: \(interestRate) %
          yearly interest: \(yearlyInterest.€String)

        """
    }
}

