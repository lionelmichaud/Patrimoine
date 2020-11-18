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
    
    static let empty: RealEstateAsset = RealEstateAsset(name                 : "",
                                                        note                 : "",
                                                        buyingYear           : Date.now.year,
                                                        buyingPrice          : 0,
                                                        yearlyTaxeHabitation : 0,
                                                        yearlyTaxeFonciere   : 0)
    
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
    var buyingYear           : Int {
        willSet {
            if !willBeSold { sellingYear = newValue } // valeur par défaut
            //if !willBeInhabited { inhabitedFromYear = newValue } // valeur par défaut
//            if !willBeRented { rentalFrom = newValue } // valeur par défaut
        }
    }
    var buyingPrice          : Double
    var yearlyTaxeHabitation : Double
    var yearlyTaxeFonciere   : Double
    // vente
    var willBeSold              : Bool   = false
    var sellingYear             : Int    = Date.now.year + 100
    var sellingNetPrice         : Double = 0.0
    var sellingPriceAfterTaxes  : Double {
        let detentionDuration = sellingYear - buyingYear
        let capitalGain       = self.sellingNetPrice - buyingPrice
        let socialTaxes       = Fiscal.model.socialTaxesOnEstateCapitalGain.socialTaxes (capitalGain: max(capitalGain,0.0), detentionDuration: detentionDuration)
        let irpp              = Fiscal.model.irppOnEstateCapitalGain.irpp (capitalGain: max(capitalGain,0.0), detentionDuration: detentionDuration)
        return self.sellingNetPrice - socialTaxes - irpp
    }
    // habitation
    var willBeInhabited         : Bool         = false
    var inhabitedFrom           : DateBoundary = DateBoundary.empty // année inclue
    var inhabitedTo             : DateBoundary = DateBoundary.empty // année exclue
    // location
    var willBeRented            : Bool   = false
    var rentalFrom              : DateBoundary = DateBoundary.empty // année inclue
    var rentalTo                : DateBoundary = DateBoundary.empty // année exclue
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
    
    // MARK: - Initializers
    

    // MARK: - Methods
    

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
//    mutating func setInhabitationPeriod(fromYear : Int,
//                                        toYear   : Int) {
//        self.willBeInhabited   = true
//        self.inhabitedFromYear = fromYear
//        self.inhabitedToYear   = toYear
//    }
    
    /// Définir la période de location
    /// - Parameter fromDateComp: date de début de la période de location
    /// - Parameter toDateComp: date de fin de la période de location
    /// - Parameter monthlyRentAfterCharges: loyer mensuel charges déduites
//    mutating func setRentalPeriod(fromYear                : Int,
//                                  toYear                  : Int,
//                                  monthlyRentAfterCharges : Double) {
//        self.willBeRented            = true
//        self.rentalFrom          = fromYear
//        self.rentalTo            = toYear
//        self.monthlyRentAfterCharges = monthlyRentAfterCharges
//    }
    
    /// Définir les conditions de vente
    /// - Parameter sellingYearComp: date de la vente
    /// - Parameter sellingNetPrice: produit net de la vente
    mutating func setSale(sellingYear     : Int,
                          sellingNetPrice : Double) {
        self.willBeSold      = true
        self.sellingYear     = sellingYear
        self.sellingNetPrice = sellingNetPrice
    }
    
    /// true si year est dans la période d'habitation
    /// - Parameter year: année
    func isInhabited(during year: Int) -> Bool {
        guard willBeInhabited && !isSold(before: year) else {
            return false
        }
        return (inhabitedFrom.year! ..< inhabitedTo.year!).contains(year) // (inhabitedFromYear.year <= year) && (year <= inhabitedToYear.year)
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
        return (rentalFrom.year! ..< rentalTo.year!).contains(year) // (rentalFromYear.year <= year) && (year <= rentalToYear.year)
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
        return year > sellingYear
    }
    
    /// true si le bien est en possession
    /// - Parameter year: année
    func isOwned(before year: Int) -> Bool {
        if isSold(before: year) {
            // le bien est vendu
            return false
        } else if year >= buyingYear {
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
            guard (willBeSold && year == sellingYear) else {
                return (0,0,0,0,0)
            }
            let detentionDuration = sellingYear - buyingYear
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
        Swift.print("       buying price: ", buyingPrice, "euro - année: ", buyingYear)
        if willBeInhabited {
            Swift.print("       inhabited:")
            Swift.print("         from:", inhabitedFrom)
            Swift.print("         to:  ", inhabitedTo)
            Swift.print("         local taxes: ", yearlyLocalTaxes, "euro")
        }
        if willBeRented {
            Swift.print("       rented:")
            Swift.print("         from:", rentalFrom)
            Swift.print("         to:  ", rentalTo)
            Swift.print("         monthly rental:        ", monthlyRentAfterCharges, "euro",
                        "         yearly rental:         ", yearlyRentAfterCharges, "euro",
                        "         yearly rental taxable: ", yearlyRentTaxableIrpp, "euro")
        }
        if willBeSold {
            Swift.print("       selling price: \(sellingNetPrice) euro - année: \(sellingYear)")
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
        buying price: \(buyingPrice.€String) année: \(buyingYear) /n
        """
        var s2: String = ""
        if willBeInhabited {
            s2 = """
                inhabited:
            from:" \(inhabitedFrom)
            to:  " \(inhabitedTo)
                    local taxes: \(yearlyLocalTaxes(during: Date.now.year).€String) \n
            """
        }

        var s3: String = ""
        if willBeRented {
            s3 = """
                rented:
            from: \(rentalFrom)
            to:   \(rentalTo)
                    monthly rental:        \(monthlyRentAfterCharges.€String)
                    yearly rental:         \(yearlyRentAfterCharges.€String)
                    yearly rental taxable: \(yearlyRentTaxableIrpp.€String) \n
            """
        }

        var s4: String = ""
        if willBeSold {
            s4 = "    selling price: \(sellingNetPrice.€String) année: \(sellingYear) \n"
        }

        return s1 + s2 + s3 + s4
    }
}

