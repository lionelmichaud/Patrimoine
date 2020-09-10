//
//  PeriodicInvestment.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

typealias PeriodicInvestmentArray = ItemArray<PeriodicInvestement>

// MARK: - Placement à versements périodiques, fixes, annuels et à taux fixe
/// Placement à versements périodiques, fixes, annuels et à taux fixe
/// Tous les intérêts sont capitalisés
struct PeriodicInvestement: Identifiable, Codable, NameableAndValueable {
    
    // properties
    
    var id              = UUID()
    var name            : String
    var type            : InvestementType
    var yearlyPayement  : Double
    // Ouverture
    var firstYear       : Int // au 31 décembre
    var initialValue    : Double
    var initialInterest : Double // portion of interests included in the initialValue
    // rendement
    var interestRate    : Double // %
    var interestRateNet : Double { // % fixe après charges sociales si prélevées à la source annuellement
        switch type {
            case .lifeInsurance(let periodicSocialTaxes):
                // si assurance vie: le taux net est le taux brut - charges sociales si celles-ci sont prélèvées à la source anuellement
                return (periodicSocialTaxes ? Fiscal.model.socialTaxesOnFinancialRevenu.net(interestRate) : interestRate)
            default:
                // dans tous les autres cas: pas de charges sociales prélevées à la source anuellement (capitalisation et taxation à la sortie)
                return interestRate
        }
    }
    // liquidation
    var lastYear        : Int // au 31 décembre

    // initialization
    
    init(name            : String,
                type            : InvestementType,
                firstYear       : Int,
                lastYear        : Int,
                rate            : Double,
                initialValue    : Double = 0.0,
                initialInterest : Double = 0.0,
                yearlyPayement  : Double = 0.0) {
        self.name            = name
        self.type            = type
        self.firstYear       = firstYear
        self.lastYear        = lastYear
        self.interestRate    = rate
        self.initialValue    = initialValue
        self.initialInterest = initialInterest
        self.yearlyPayement  = yearlyPayement
    }
    
    // methods
    
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
    /// Intérêts capitalisés à la date spécifiée
    /// - Parameter year: fin de l'année
    func cumulatedInterests(atEndOf year: Int) -> Double {
        guard (firstYear...lastYear).contains(year) else {
            return 0.0
        }
        return initialInterest + value(atEndOf: year) - (initialValue + yearlyPayement * Double(year - firstYear))
    }
    // valeur liquidative à la date de liquidation
    // revenue :          produit de la vente
    // interests :        intérêts bruts avant prélèvements sociaux et IRPP
    // netInterests :     intérêts nets de prélèvements sociaux
    // taxableInterests : intérêts nets de prélèvements sociaux et taxables à l'IRPP
    func liquidatedValue (atEndOf year: Int) -> (revenue: Double, interests: Double, netInterests: Double, taxableIrppInterests: Double, socialTaxes: Double) {
        guard year == lastYear else {
            return (0.0, 0.0, 0.0, 0.0, 0.0)
        }
        let cumulatedInterest = cumulatedInterests(atEndOf: year)
        var netInterests: Double
        var taxableInterests: Double
        switch type {
            case .lifeInsurance(let periodicSocialTaxes):
                // Si les intérêts sont prélevés au fil de l'eau on les prélève pas à la liquidation
                netInterests = (periodicSocialTaxes ? cumulatedInterest : Fiscal.model.socialTaxesOnFinancialRevenu.net(cumulatedInterest))
                taxableInterests = netInterests
            case .pea:
                netInterests = Fiscal.model.socialTaxesOnFinancialRevenu.net(cumulatedInterest)
                taxableInterests = 0.0
            case .other:
                netInterests = Fiscal.model.socialTaxesOnFinancialRevenu.net(cumulatedInterest)
                taxableInterests = netInterests
        }
        return (revenue: value(atEndOf: year), interests: cumulatedInterest, netInterests: netInterests,
                taxableIrppInterests: taxableInterests, socialTaxes: cumulatedInterest - netInterests)
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

// MARK: Extensions
extension PeriodicInvestement: Comparable {
    static func < (lhs: PeriodicInvestement, rhs: PeriodicInvestement) -> Bool {
        return (lhs.name < rhs.name)
    }
}

extension PeriodicInvestement: CustomStringConvertible {
    var description: String {
        return """
        \(name)
        valeur:            \(value(atEndOf: Date.now.year).euroString)
        type:              \(type)
        first year:        \(firstYear) last year: \(lastYear)
        initial Value:     \(initialValue.euroString) initial Interests: \(initialInterest.euroString)
        yearly Payement:   \(yearlyPayement.euroString)
        liquidation value: \(value(atEndOf: lastYear).euroString) cumulated interests: \(cumulatedInterests(atEndOf: lastYear).euroString)
        interest Rate Brut:\(interestRate) % interest Rate Net:\(interestRateNet) %
        
        """
    }
}

