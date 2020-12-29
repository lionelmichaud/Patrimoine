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
struct PeriodicInvestement: Identifiable, Codable, NameableValuable, Ownable {
    
    // MARK: - Static Properties
    
    static var simulationMode : SimulationModeEnum = .deterministic
    
    // MARK: - Static Methods
    
    static var inflation: Double { // %
        Economy.model.inflation.value(withMode: simulationMode)
    }
    
    /// taux à long terme - rendement d'un fond en euro
    private static var securedRate: Double { // %
        Economy.model.securedRate.value(withMode: simulationMode)
    }
    
    /// rendement des actions
    private static var stockRate: Double { // %
        Economy.model.stockRate.value(withMode: simulationMode)
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
    var interestRateType: InterestRateType // type de taux de rendement
    var interestRate    : Double {// % avant charges sociales si prélevées à la source annuellement
        switch interestRateType {
            case .contractualRate( let fixedRate):
                return fixedRate - PeriodicInvestement.inflation
                
            case .marketRate(let stockRatio):
                let stock = stockRatio / 100.0
                // taux d'intérêt composite fonction de la composition du portefeuille
                let rate = stock * PeriodicInvestement.stockRate + (1.0 - stock) * PeriodicInvestement.securedRate
                return rate - PeriodicInvestement.inflation
        }
    }
    var interestRateNet : Double { // % fixe après charges sociales si prélevées à la source annuellement
        switch type {
            case .lifeInsurance(let periodicSocialTaxes, _):
                // si assurance vie: le taux net est le taux brut - charges sociales si celles-ci sont prélèvées à la source anuellement
                return (periodicSocialTaxes ?
                            Fiscal.model.socialTaxesOnFinancialRevenu.net(interestRate) :
                            interestRate)
            default:
                // dans tous les autres cas: pas de charges sociales prélevées à la source anuellement (capitalisation et taxation à la sortie)
                return interestRate
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
    
    /// Versement annuel
    /// - Parameter year: année
    /// - Returns: versement, frais de souscription inclus
    func yearlyTotalPayement(atEndOf year: Int) -> Double {
        guard (firstYear...lastYear).contains(year) else {
            return 0
        }
        return yearlyPayement + yearlyCost
    }
    /// Valeur capitalisée à la date spécifiée
    /// - Parameter year: fin de l'année
    func value (atEndOf year: Int) -> Double {
        guard (firstYear...lastYear).contains(year) else {
            return 0.0
        }
        return futurValue(payement     : yearlyPayement,
                          interestRate : interestRateNet/100,
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
    func ownedValue(by ownerName     : String,
                    atEndOf year     : Int,
                    evaluationMethod : EvaluationMethod) -> Double {
        var evaluatedValue : Double
//        Swift.print("  Actif: \(name)")

        switch evaluationMethod {
            case .inheritance:
                // le bien est-il une assurance vie ?
                switch type {
                    case .lifeInsurance:
                        // les assurance vie ne sont pas inclues car hors succession
//                        Swift.print("  valeur: 0")
                        return 0
                        
                    default:
                        // le défunt est-il usufruitier ?
                        if ownership.isAnUsufructOwner(ownerName: ownerName) {
                            // si oui alors l'usufruit rejoint la nu-propriété sans droit de succession
                            // l'usufruit n'est donc pas intégré à la masse successorale du défunt
//                            Swift.print("  valeur: 0")
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
//        Swift.print("  valeur: \(value)")
        return value
    }
    
    /// Intérêts capitalisés à la date spécifiée
    /// - Parameter year: fin de l'année
    func cumulatedInterests(atEndOf year: Int) -> Double {
        guard (firstYear...lastYear).contains(year) else {
            return 0.0
        }
        return initialInterest + value(atEndOf: year) - (initialValue + yearlyPayement * Double(year - firstYear))
    }
    
    /// valeur liquidative à la date de liquidation
    /// - Parameter year: fin de l'année
    /// - Returns:
    /// revenue : produit de la vente
    /// interests : intérêts bruts avant prélèvements sociaux et IRPP
    /// netInterests : intérêts nets de prélèvements sociaux
    /// taxableInterests : intérêts nets de prélèvements sociaux et taxables à l'IRPP
    /// socialTaxes : prélèvements sociaux
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
                netInterests     = (periodicSocialTaxes ? cumulatedInterest : Fiscal.model.socialTaxesOnFinancialRevenu.net(cumulatedInterest))
                taxableInterests = netInterests
            case .pea:
                netInterests     = Fiscal.model.socialTaxesOnFinancialRevenu.net(cumulatedInterest)
                taxableInterests = 0.0
            case .other:
                netInterests     = Fiscal.model.socialTaxesOnFinancialRevenu.net(cumulatedInterest)
                taxableInterests = netInterests
        }
        return (revenue              : value(atEndOf: year),
                interests            : cumulatedInterest,
                netInterests         : netInterests,
                taxableIrppInterests : taxableInterests,
                socialTaxes          : cumulatedInterest - netInterests)
    }
    
    func print() {
        Swift.print("    ", name)
        Swift.print("       type", type)
        Swift.print("       first year:        ", firstYear, "last year: ", lastYear)
        Swift.print("       initial Value:     ", initialValue, "initial Interests: ", initialInterest)
        Swift.print("       yearly Payement:   ", yearlyPayement.rounded(), "interest Rate Brut: ", interestRate, "%", "interest Rate Net: ", interestRateNet, "%")
        Swift.print("       liquidation value: ", value(atEndOf: lastYear).rounded(), "cumulated interests: ", cumulatedInterests(atEndOf: lastYear).rounded())
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
        return """
        \(name)
        valeur:            \(value(atEndOf: Date.now.year).€String)
        type:              \(type)
        first year:        \(firstYear) last year: \(lastYear)
        initial Value:     \(initialValue.€String) initial Interests: \(initialInterest.€String)
        yearly Payement:   \(yearlyPayement.€String)
        liquidation value: \(value(atEndOf: lastYear).€String) cumulated interests: \(cumulatedInterests(atEndOf: lastYear).€String)
        interest Rate Brut:\(interestRate) % interest Rate Net:\(interestRateNet) %
        
        """
    }
}
