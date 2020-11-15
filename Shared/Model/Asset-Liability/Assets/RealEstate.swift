//
//  RealEstate.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

typealias RealEstateArray = ItemArray<RealEstateAsset>

// MARK: - Actif immobilier physique
struct RealEstateAsset: Identifiable, Codable, NameableValuable {
    
    // MARK: - Static Properties
    
    static var simulationMode : SimulationModeEnum = .deterministic
    
    // MARK: - Static Methods
    
    // pas utilisé
    // on suppose que les loyers des biens immobiliers physiques sont réévalués de l'inflation
    // on suppose que les valeurs de vente des biens immobiliers physiques et papier sont réévalués de l'inflation
    static var inflation: Double { // %
        Economy.model.inflation.value(withMode: simulationMode)
    }
    
    // MARK: - Properties

    var id                   = UUID()
    var name                 : String
    var note                 : String
    // achat
    var buyingDate           : Date {
        willSet {
            if !willBeSold { sellingDate = newValue } // valeur par défaut
            if !willBeInhabited { inhabitedFromDate = newValue } // valeur par défaut
            if !willBeRented { rentalFromDate = newValue } // valeur par défaut
        }
    }
    var buyingPrice          : Double
    var yearlyTaxeHabitation : Double
    var yearlyTaxeFonciere   : Double
    // vente
    var willBeSold            : Bool   = false
    var sellingDate           : Date   = 100.years.fromNow! 
    var sellingNetPrice       : Double = 0.0
    var sellingPriceAfterTaxes: Double {
        let detentionDuration = sellingDate.year - buyingDate.year
        let capitalGain       = self.sellingNetPrice - buyingPrice
        let socialTaxes       = Fiscal.model.socialTaxesOnEstateCapitalGain.socialTaxes (capitalGain: max(capitalGain,0.0), detentionDuration: detentionDuration)
        let irpp              = Fiscal.model.irppOnEstateCapitalGain.irpp (capitalGain: max(capitalGain,0.0), detentionDuration: detentionDuration)
        return self.sellingNetPrice - socialTaxes - irpp
    }
    // habitation
    var willBeInhabited   : Bool = false
    var inhabitedFromDate : Date = Date.now
    var inhabitedToDate   : Date = 100.years.fromNow!
    // location
    var willBeRented            : Bool   = false
    var rentalFromDate          : Date   = Date.now
    var rentalToDate            : Date   = 100.years.fromNow!
    var monthlyRentAfterCharges : Double = 0.0 // frais agence, taxe foncière et assurance déduite
    var yearlyRentAfterCharges  : Double {
        return monthlyRentAfterCharges * 12
    }
    var yearlyRentTaxableIrpp   : Double { // même base que pour le calcul des charges sociales
        return yearlyRentAfterCharges
    }
    var yearlyRentSocialTaxes   : Double { // même base que pour le calcul de l'IRPP
        return Fiscal.model.socialTaxesOnFinancialRevenu.socialTaxes(yearlyRentAfterCharges)
    }
    var profitability           : Double { // profitabilité nette de charges (frais agence, taxe foncière et assurance)
        return yearlyRentAfterCharges / (willBeSold ? sellingNetPrice : buyingPrice)
    }
    
    // initialization
    
    // methods
    
    /// Valeur à la date spécifiée
    /// - Parameter year: fin de l'année
    func value(atEndOf year: Int) -> Double {
        if isOwned(before: year) {
            return (sellingNetPrice == 0 ? buyingPrice : sellingNetPrice)
        } else {
            return 0.0
        }
    }
    
    /// Définir la période d'habitation
    /// - Parameter fromDateComp: date de début de la période d'habitation
    /// - Parameter toDateComp: date de fin de la période d'habitation
    /// - Parameter yearlyLocalTaxes: impôts locaux annuels
    mutating func setInhabitationPeriod(fromDate: Date, toDate: Date) {
        self.willBeInhabited   = true
        self.inhabitedFromDate = fromDate
        self.inhabitedToDate   = toDate
    }
    
    /// Définir la période de location
    /// - Parameter fromDateComp: date de début de la période de location
    /// - Parameter toDateComp: date de fin de la période de location
    /// - Parameter monthlyRentAfterCharges: loyer mensuel charges déduites
    mutating func setRentalPeriod(fromDate: Date, toDate: Date,
                                         monthlyRentAfterCharges: Double) {
        self.willBeRented            = true
        self.rentalFromDate          = fromDate
        self.rentalToDate            = toDate
        self.monthlyRentAfterCharges = monthlyRentAfterCharges
    }
    
    /// Définir les conditions de vente
    /// - Parameter sellingDateComp: date de la vente
    /// - Parameter sellingNetPrice: produit net de la vente
    mutating func setSale(sellingDate: Date, sellingNetPrice: Double) {
        self.willBeSold      = true
        self.sellingDate     = sellingDate
        self.sellingNetPrice = sellingNetPrice
    }
    
    /// true si year est dans la période d'habitation
    /// - Parameter year: année
    func isInhabited(during year: Int) -> Bool {
        guard willBeInhabited && !isSold(before: year) else {
            return false
        }
        return (inhabitedFromDate.year...inhabitedToDate.year).contains(year) // (inhabitedFromDate.year <= year) && (year <= inhabitedToDate.year)
    }
    
    /// Impôts locaux
    /// - Parameter year: année
    func yearlyLocalTaxes (during year: Int) -> Double {
        guard !isSold(before: year) else {
            return 0.0 // la maison est vendue
        }
        if isRented(during: year) { // la maison est louée
            // le proprio ne paye que la taxe foncière
            return self.yearlyTaxeFonciere
        } else { // la maison n'est pas vendue et n'est pas louée
            return self.yearlyTaxeFonciere + self.yearlyTaxeHabitation
        }
    }
    
    /// true si year est dans la période de location
    /// - Parameter year: année
    func isRented(during year: Int) -> Bool {
        guard willBeRented && !isSold(before: year) else {
            return false
        }
        return (rentalFromDate.year...rentalToDate.year).contains(year) // (rentalFromDate.year <= year) && (year <= rentalToDate.year)
    }
    
    /// Revenus de location si year est dans la période de location
    /// - Parameter year: année
    /// - Parameter revenue: loyer après charges déductibles (agence, assurance, taxe fonçière)
    /// - Parameter taxableIrpp: loyer imposable à l'IRPP
    /// - Parameter socialTaxes: charges sociales payées sur le loyer
    func yearlyRent(during year: Int) -> (revenue: Double, taxableIrpp: Double, socialTaxes: Double) {
        if isRented(during: year) {
            return (revenue:     self.yearlyRentAfterCharges,
                    taxableIrpp: self.yearlyRentTaxableIrpp,
                    socialTaxes: self.yearlyRentSocialTaxes)
        } else {
            return (0.0, 0.0, 0.0)
        }
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
        } else if year >= buyingDate.year {
            // le bien est déjà acheté
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
     - Parameter netRevenue: produit de la vente net de frais d'agence, de charges sociales et d'impôt sur la plus-value
     - Parameter socialTaxes: charges sociales payées sur sur la plus-value
     - Parameter irpp: impôt sur le revenu payé sur sur la plus-value
     **/
    func liquidatedValue (_ year: Int) ->
        (revenue: Double, capitalGain: Double, netRevenue: Double, socialTaxes: Double, irpp: Double) {
            guard (willBeSold && year == sellingDate.year) else {
                return (0,0,0,0,0)
            }
            let detentionDuration = sellingDate.year - buyingDate.year
            let capitalGain       = self.sellingNetPrice - buyingPrice
            let socialTaxes       = Fiscal.model.socialTaxesOnEstateCapitalGain.socialTaxes (capitalGain: max(capitalGain,0.0),
                                                                                    detentionDuration: detentionDuration)
            let irpp              = Fiscal.model.irppOnEstateCapitalGain.irpp (capitalGain: max(capitalGain,0.0),
                                                                      detentionDuration: detentionDuration)
            return (revenue     : self.sellingNetPrice,
                    capitalGain : capitalGain,
                    netRevenue  : self.sellingNetPrice - socialTaxes - irpp,
                    socialTaxes : socialTaxes,
                    irpp        : irpp)
    }
    
    func print() {
        Swift.print("    ", name)
        Swift.print("       buying price: ", buyingPrice, "euro - date: ", buyingDate.stringShortDate)
        if willBeInhabited {
            Swift.print("       inhabited:")
            Swift.print("         from:", inhabitedFromDate.stringShortDate)
            Swift.print("         to:  ", inhabitedToDate.stringShortDate)
            Swift.print("         local taxes: ", yearlyLocalTaxes, "euro")
        }
        if willBeRented {
            Swift.print("       rented:")
            Swift.print("         from:", rentalFromDate.stringShortDate)
            Swift.print("         to:  ", rentalToDate.stringShortDate)
            Swift.print("         monthly rental:        ", monthlyRentAfterCharges, "euro",
                        "         yearly rental:         ", yearlyRentAfterCharges, "euro",
                        "         yearly rental taxable: ", yearlyRentTaxableIrpp, "euro")
        }
        if willBeSold {
            Swift.print("       selling price: \(sellingNetPrice) euro - date: \(sellingDate.stringShortDate)")
        }
    }
}

// MARK: Extensions
extension RealEstateAsset: Comparable {
    static func < (lhs: RealEstateAsset, rhs: RealEstateAsset) -> Bool {
        return (lhs.name < rhs.name)
    }
}

extension RealEstateAsset: CustomStringConvertible {
    var description: String {
        let s1 = """
        \(name)
        buying price: \(buyingPrice.€String) date: \(buyingDate.stringShortDate) /n
        """
        var s2: String = ""
        if willBeInhabited {
            s2 = """
                inhabited:
            from:" \(inhabitedFromDate.stringShortDate)
            to:  " \(inhabitedToDate.stringShortDate)
                    local taxes: \(yearlyLocalTaxes(during: Date.now.year).€String) \n
            """
        }

        var s3: String = ""
        if willBeRented {
            s3 = """
                rented:
            from: \(rentalFromDate.stringShortDate)
            to:   \(rentalToDate.stringShortDate)
                    monthly rental:        \(monthlyRentAfterCharges.€String)
                    yearly rental:         \(yearlyRentAfterCharges.€String)
                    yearly rental taxable: \(yearlyRentTaxableIrpp.€String) \n
            """
        }

        var s4: String = ""
        if willBeSold {
            s4 = "    selling price: \(sellingNetPrice.€String) date: \(sellingDate.stringMediumDate) \n"
        }

        return s1 + s2 + s3 + s4
    }
}

