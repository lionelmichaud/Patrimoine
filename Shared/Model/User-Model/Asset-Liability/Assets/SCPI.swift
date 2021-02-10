//
//  SCPI.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

typealias ScpiArray = ItemArray<SCPI>

// MARK: - SCPI à revenus périodiques, annuels et fixes

struct SCPI: Identifiable, Codable, Ownable {
    
    // MARK: - Static Properties
    
    private static var saleCommission    : Double                    = 10.0 // %
    private static var simulationMode    : SimulationModeEnum        = .deterministic
    // dependencies
    private static var inflationProvider : InflationProviderProtocol = Economy.model
    private static var fiscalModel       : Fiscal.Model              = Fiscal.model

    // MARK: - Static Methods
    
    /// Dependency Injection: Setter Injection
    static func setInflationProvider(_ inflationProvider : InflationProviderProtocol) {
        SCPI.inflationProvider = inflationProvider
    }

    /// Dependency Injection: Setter Injection
    static func setFiscalModelProvider(_ fiscalModel : Fiscal.Model) {
        SCPI.fiscalModel = fiscalModel
    }

    static func setSimulationMode(to simulationMode: SimulationModeEnum) {
        SCPI.simulationMode = simulationMode
    }

    // tous ces actifs sont dépréciés de l'inflation
    private static var inflation: Double { // %
        SCPI.inflationProvider.inflation(withMode: simulationMode)
    }
    
    // MARK: - Properties
    
    var id           = UUID()
    var name         : String
    var note         : String = ""
    // propriétaires
    // attention: par défaut la méthode delegate pour ageOf = nil
    // c'est au créateur de l'objet (View ou autre objet du Model) de le faire
    var ownership    : Ownership = Ownership()
    // achat
    var buyingDate   : Date
    var buyingPrice  : Double = 0.0
    // rendement
    var interestRate : Double = 0.0 // %
    var revaluatRate : Double = 0.0 // %
    // vente
    var willBeSold   : Bool = false
    var sellingDate  : Date = 100.years.fromNow!

    // MARK: - Methods

    /// Valeur capitalisée à la date spécifiée
    /// - Parameter year: fin de l'année
    func value(atEndOf year: Int) -> Double {
        if isOwned(before: year) {
            return try! futurValue(payement     : 0,
                                   interestRate : (revaluatRate - SCPI.inflation) / 100.0,
                                   nbPeriod     : year - buyingDate.year,
                                   initialValue : buyingPrice) * (1.0 - SCPI.saleCommission / 100.0)
        } else {
            return 0.0
        }
    }
    
    /// Revenus annuels
    /// - Parameter year: fin de l'année
    /// - Parameter revenue: revenus inscrit en compte courant avant prélèvements sociaux et IRPP
    /// - Parameter taxableIrpp: part des revenus inscrit en compte courant imposable à l'IRPP (après charges sociales)
    func yearlyRevenue(atEndOf year: Int)
    -> (revenue    : Double,
        taxableIrpp: Double,
        socialTaxes: Double) {
        let revenue     = (isOwned(before: year) ?
                            buyingPrice * (interestRate - SCPI.inflation) / 100.0 :
                            0.0)
        let taxableIrpp = SCPI.fiscalModel.financialRevenuTaxes.net(revenue)
        return (revenue    : revenue,
                taxableIrpp: taxableIrpp,
                socialTaxes: revenue - taxableIrpp)
    }
    
    /// true si l'année est postérieure à l'année de vente
    /// - Parameter year: année
    func isSold(before year: Int) -> Bool {
        guard willBeSold else {
            return false
        }
        return year > sellingDate.year
    }
    
    /// true si le bien est en possession
    /// - Parameter year: année
    func isOwned(before year: Int) -> Bool {
        if isSold(before: year) {
            // le bien est vendu
            return false
        } else if (buyingDate.year...).contains(year) {
            return true
        } else {
            // le bien n'est pas encore acheté
            return false
        }
    }
    
    /**
     Produit de la vente l'année de la vente
     
     - Parameter revenue: produit de la vente net de frais d'agence
     - Parameter capitalGain: plus-value réalisée lors de la vente
     - Parameter netRevenue: produit de la vente net de charges sociales et d'impôt sur la plus-value
     - Parameter socialTaxes: charges sociales payées sur sur la plus-value
     - Parameter irpp: impôt sur le revenu payé sur sur la plus-value
     **/
    func liquidatedValue (_ year: Int)
    -> (revenue    : Double,
        capitalGain: Double,
        netRevenue : Double,
        socialTaxes: Double,
        irpp       : Double) {
        guard willBeSold && year == sellingDate.year else {
            return (0, 0, 0, 0, 0)
        }
        let detentionDuration = sellingDate.year - buyingDate.year
        let currentValue      = value(atEndOf: sellingDate.year)
        let capitalGain       = currentValue - buyingPrice
        let socialTaxes       =
            SCPI.fiscalModel.estateCapitalGainTaxes.socialTaxes(
                capitalGain      : max(capitalGain, 0.0),
                detentionDuration: detentionDuration)
        let irpp              =
            SCPI.fiscalModel.estateCapitalGainIrpp.irpp(
                capitalGain      : max(capitalGain, 0.0),
                detentionDuration: detentionDuration)
        return (revenue     : currentValue,
                capitalGain : capitalGain,
                netRevenue  : currentValue - socialTaxes - irpp,
                socialTaxes : socialTaxes,
                irpp        : irpp)
    }
    
    func print() {
        Swift.print("    ", name)
        Swift.print("       buying price: ", buyingPrice, "euro - date: ", buyingDate.stringShortDate)
        Swift.print("       interest Rate:     ", interestRate - SCPI.inflation, "%  revaluation rate: ", revaluatRate - SCPI.inflation, "%")
        if willBeSold {
            Swift.print("       selling price: \(value(atEndOf: sellingDate.year)) euro - date: \(sellingDate.stringShortDate)")
        }
    }
}

// MARK: Extensions
extension SCPI: Comparable {
    static func < (lhs: SCPI, rhs: SCPI) -> Bool {
        return (lhs.name < rhs.name)
    }
}
