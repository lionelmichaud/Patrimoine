//
//  PeriodicInvestment.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

typealias PeriodicInvestementArray = ItemArray<PeriodicInvestement>

// MARK: - Placement à versements périodiques, fixes, annuels et à taux fixe

/// Placement à versements périodiques, fixes, annuels et à taux fixe
/// Tous les intérêts sont capitalisés
struct PeriodicInvestement: Identifiable, BundleCodable, FinancialEnvelop {
    
    // MARK: - Static Properties
    
    static var defaultFileName: String = "PeriodicInvestement.json"
    
    private static var simulationMode: SimulationModeEnum = .deterministic
    // dependencies
    private static var economyModel : EconomyModelProviderProtocol = Economy.model
    private static var fiscalModel  : Fiscal.Model                 = Fiscal.model
    
    // tous ces actifs sont dépréciés de l'inflation
    private static var inflation: Double { // %
        PeriodicInvestement.economyModel.inflation(withMode: simulationMode)
    }
    
    /// taux à long terme - rendem
    /// rendement des actions - en moyenne
    private static var rates: (averageSecuredRate: Double, averageStockRate: Double) { // %
        let rates = PeriodicInvestement.economyModel.rates(withMode: simulationMode)
        return (rates.securedRate, rates.stockRate)
    }
    
    // MARK: - Static Methods
    
    /// Dependency Injection: Setter Injection
    static func setEconomyModelProvider(_ economyModel : EconomyModelProviderProtocol) {
        PeriodicInvestement.economyModel = economyModel
    }
    
    /// Dependency Injection: Setter Injection
    static func setFiscalModelProvider(_ fiscalModel : Fiscal.Model) {
        PeriodicInvestement.fiscalModel = fiscalModel
    }
    
    static func setSimulationMode(to thisMode: SimulationModeEnum) {
        PeriodicInvestement.simulationMode = thisMode
    }
    
    private static func rates(in year : Int)
    -> (securedRate : Double,
        stockRate   : Double) {
        PeriodicInvestement.economyModel.rates(in       : year,
                                               withMode : simulationMode)
    }
    
    // MARK: - Properties
    
    var id              = UUID()
    var name            : String
    var note            : String = ""
    // propriétaires
    // attention: par défaut la méthode delegate pour ageOf = nil
    // c'est au créateur de l'objet (View ou autre objet du Model) de le faire
    var ownership       : Ownership = Ownership()
    var type            : InvestementType
    var yearlyPayement  : Double = 0.0 // versements nets de frais
    var yearlyCost      : Double = 0.0 // Frais sur versements
    // Ouverture
    var firstYear       : Int // au 31 décembre
    var initialValue    : Double = 0.0
    var initialInterest : Double = 0.0 // portion of interests included in the initialValue
    // rendement
    var interestRateType       : InterestRateType // type de taux de rendement
    var averageInterestRate    : Double {// % avant charges sociales si prélevées à la source annuellement
        switch interestRateType {
            case .contractualRate( let fixedRate):
                // taux contractuel fixe
                return fixedRate - PeriodicInvestement.inflation
                
            case .marketRate(let stockRatio):
                // taux de marché variable
                let stock = stockRatio / 100.0
                // taux d'intérêt composite fonction de la composition du portefeuille
                let rate = stock * PeriodicInvestement.rates.averageStockRate + (1.0 - stock) * PeriodicInvestement.rates.averageSecuredRate
                return rate - PeriodicInvestement.inflation
        }
    }
    var averageInterestRateNet : Double { // % fixe après charges sociales si prélevées à la source annuellement
        switch type {
            case .lifeInsurance(let periodicSocialTaxes, _):
                // si assurance vie: le taux net est le taux brut - charges sociales si celles-ci sont prélèvées à la source anuellement
                return (periodicSocialTaxes ?
                            PeriodicInvestement.fiscalModel.financialRevenuTaxes.net(averageInterestRate) :
                            averageInterestRate)
            default:
                // dans tous les autres cas: pas de charges sociales prélevées à la source anuellement (capitalisation et taxation à la sortie)
                return averageInterestRate
        }
    }
    // liquidation
    var lastYear        : Int // au 31 décembre

    // MARK: - Initializers
    
    init(name             : String,
         note             : String,
         type             : InvestementType,
         firstYear        : Int,
         lastYear         : Int,
         interestRateType : InterestRateType,
         initialValue     : Double = 0.0,
         initialInterest  : Double = 0.0,
         yearlyPayement   : Double = 0.0,
         yearlyCost       : Double = 0.0) {
        self.name             = name
        self.note             = note
        self.type             = type
        self.firstYear        = firstYear
        self.lastYear         = lastYear
        self.interestRateType = interestRateType
        self.initialValue     = initialValue
        self.initialInterest  = initialInterest
        self.yearlyPayement   = yearlyPayement
        self.yearlyCost       = yearlyCost
    }
    
    // MARK: - Methods
    
    /// Versement annuel, frais de versement inclus
    /// - Parameter year: année
    /// - Returns: versement, frais de versement inclus
    /// - Note: Les première et dernière années sont inclues
    func yearlyTotalPayement(atEndOf year: Int) -> Double {
        guard (firstYear...lastYear).contains(year) else {
            return 0
        }
        return yearlyPayement + yearlyCost
    }
    
    /// Valeur capitalisée à la date spécifiée
    /// - Parameter year: fin de l'année
    /// - Note: Les première et dernière années sont inclues
    func value (atEndOf year: Int) -> Double {
        guard (firstYear...lastYear).contains(year) else {
            return 0.0
        }
        return try! futurValue(payement     : yearlyPayement,
                               interestRate : averageInterestRateNet/100,
                               nbPeriod     : year - firstYear,
                               initialValue : initialValue)
    }
    
    /// Calcule la valeur d'un bien possédée par un personne donnée à une date donnée
    /// selon la régle générale ou selon la règle de l'IFI, de l'ISF, de la succession...
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - year: date d'évaluation
    ///   - evaluationMethod: méthode d'évaluation de la valeure des bien
    /// - Returns: valeur du bien possédée (part d'usufruit + part de nue-prop)
    /// - Warning: les assurance vie ne sont pas inclues car hors succession
    /// - Note: Les première et dernière années sont inclues
    func ownedValue(by ownerName     : String,
                    atEndOf year     : Int,
                    evaluationMethod : EvaluationMethod) -> Double {
        var evaluatedValue : Double

        switch evaluationMethod {
            case .legalSuccession:
                // le bien est-il une assurance vie ?
                switch type {
                    case .lifeInsurance:
                        // les assurance vie ne sont pas inclues car hors succession
                        return 0
                        
                    default:
                        // le défunt est-il usufruitier ?
                        if ownership.isAnUsufructOwner(ownerName: ownerName) {
                            // si oui alors l'usufruit rejoint la nu-propriété sans droit de succession
                            // l'usufruit n'est donc pas intégré à la masse successorale du défunt
                            return 0
                        }
                        // pas de décote
                        evaluatedValue = value(atEndOf: year)
                }
                
            case .lifeInsuranceSuccession:
                // le bien est-il une assurance vie ?
                switch type {
                    case .lifeInsurance:
                        // pas de décote
                        evaluatedValue = value(atEndOf: year)
                        
                    default:
                        // on recherche uniquement les assurances vies
                        return 0
                }
                
            case .ifi, .isf, .patrimoine:
                // pas de décote
                evaluatedValue = value(atEndOf: year)
        }
        // calculer la part de propriété
        let value = evaluatedValue == 0 ? 0 : ownership.ownedValue(by               : ownerName,
                                                                   ofValue          : evaluatedValue,
                                                                   atEndOf          : year,
                                                                   evaluationMethod : evaluationMethod)
        return value
    }
    
    /// Intérêts capitalisés à la date spécifiée
    /// - Parameter year: fin de l'année
    /// - Note: Les première et dernière années sont inclues
    func cumulatedInterests(atEndOf year: Int) -> Double {
        guard (firstYear...lastYear).contains(year) else {
            return 0.0
        }
        return initialInterest + value(atEndOf: year) - (initialValue + yearlyPayement * Double(year - firstYear))
    }
    
    /// valeur liquidative à la date de liquidation
    /// - Parameter year: fin de l'année
    /// - Returns:
    ///   - revenue : produit de la vente
    ///   - interests : intérêts bruts avant prélèvements sociaux et IRPP
    ///   - netInterests : intérêts nets de prélèvements sociaux
    ///   - taxableInterests : intérêts nets de prélèvements sociaux et taxables à l'IRPP
    ///   - socialTaxes : prélèvements sociaux
    /// - Note: Les première et dernière années sont inclues
    func liquidatedValue (atEndOf year: Int)
    -> (revenue              : Double,
        interests            : Double,
        netInterests         : Double,
        taxableIrppInterests : Double,
        socialTaxes          : Double) {
        guard year == lastYear else {
            return (0.0, 0.0, 0.0, 0.0, 0.0)
        }
        let cumulatedInterest = cumulatedInterests(atEndOf: year)
        var netInterests     : Double
        var taxableInterests : Double
        switch type {
            case .lifeInsurance(let periodicSocialTaxes, _):
                // Si les intérêts sont prélevés au fil de l'eau on les prélève pas à la liquidation
                netInterests     = (periodicSocialTaxes ? cumulatedInterest : PeriodicInvestement.fiscalModel.financialRevenuTaxes.net(cumulatedInterest))
                taxableInterests = netInterests
            case .pea:
                netInterests     = PeriodicInvestement.fiscalModel.financialRevenuTaxes.net(cumulatedInterest)
                taxableInterests = 0.0
            case .other:
                netInterests     = PeriodicInvestement.fiscalModel.financialRevenuTaxes.net(cumulatedInterest)
                taxableInterests = netInterests
        }
        return (revenue              : value(atEndOf: year),
                interests            : cumulatedInterest,
                netInterests         : netInterests,
                taxableIrppInterests : taxableInterests,
                socialTaxes          : cumulatedInterest - netInterests)
    }
}

// MARK: - Extensions

extension PeriodicInvestement: Comparable {
    static func < (lhs: PeriodicInvestement, rhs: PeriodicInvestement) -> Bool {
        return (lhs.name < rhs.name)
    }
}

extension PeriodicInvestement: CustomStringConvertible {
    var description: String {
        """
        INVESTISSEMENT PERIODIQUE: \(name)
        - Note:
        \(note.withPrefixedSplittedLines("    "))
        - Type:\(type.description.withPrefixedSplittedLines("  "))
        - Droits de propriété:
        \(ownership.description.withPrefixedSplittedLines("  "))
        - Valeur:            \(value(atEndOf: Date.now.year).€String)
        - Première année:    \(firstYear) dernière année: \(lastYear)
        - Valeur initiale:   \(initialValue.€String) dont intérêts: \(initialInterest.€String)
        - Versement annuel net de frais:  \(yearlyPayement.€String) Frais sur versements annuels: \(yearlyCost.€String)
        - Valeur liquidative: \(value(atEndOf: lastYear).€String) Intérêts cumulés: \(cumulatedInterests(atEndOf: lastYear).€String)
        - \(interestRateType)
        - Taux d'intérêt net d'inflation avant prélèvements sociaux:   \(averageInterestRate) %
        - Taux d'intérêt net d'inflation, net de prélèvements sociaux: \(averageInterestRateNet) %
        """
    }
}
