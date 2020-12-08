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
struct RealEstateAsset: Identifiable, Codable, Equatable, NameableValuable, Ownable {
    
    // MARK: - Static Properties
    
//    static var simulationMode : SimulationModeEnum = .deterministic
    
    // MARK: - Static Methods
    
    // pas utilisé
    // on suppose que les loyers des biens immobiliers physiques sont réévalués de l'inflation
    // on suppose que les valeurs de vente des biens immobiliers physiques et papier sont réévalués de l'inflation
//    static var inflation: Double { Economy.model.inflation.value(withMode: simulationMode) }
    
    // MARK: - Properties
    
    var id                   = UUID()
    var name                 : String
    var note                 : String = ""
    // propriétaires
    // attention: par défaut la méthode delegate pour ageOf = nil
    // c'est au créateur de l'objet (View ou autre objet du Model) de le faire
    var ownership            : Ownership = Ownership()
    // achat
    var buyingYear           : DateBoundary = DateBoundary.empty // première année de possession (inclue)
    var buyingPrice          : Double = 0.0
    var yearlyTaxeHabitation : Double = 0.0
    var yearlyTaxeFonciere   : Double = 0.0
    // valeur vénale estimée courante
    var estimatedValue       : Double = 0.0
    // vente
    var willBeSold              : Bool   = false
    var sellingYear             : DateBoundary = DateBoundary.empty // dernière année de possession (inclue)
    var sellingNetPrice         : Double = 0.0
    var sellingPriceAfterTaxes  : Double {
        guard let sellingDate = sellingYear.year, let buyingDate = buyingYear.year else { return 0 }
        let detentionDuration = sellingDate - buyingDate
        let capitalGain       = self.sellingNetPrice - buyingPrice
        let socialTaxes       = Fiscal.model.socialTaxesOnEstateCapitalGain.socialTaxes (capitalGain: max(capitalGain,0.0), detentionDuration: detentionDuration)
        let irpp              = Fiscal.model.irppOnEstateCapitalGain.irpp (capitalGain: max(capitalGain,0.0), detentionDuration: detentionDuration)
        return self.sellingNetPrice - socialTaxes - irpp
    }
    // habitation
    var willBeInhabited         : Bool = false
    var inhabitedFrom           : DateBoundary = DateBoundary.empty // année inclue
    var inhabitedTo             : DateBoundary = DateBoundary.empty // année exclue
    // location
    var willBeRented            : Bool = false
    var rentalFrom              : DateBoundary = DateBoundary.empty // année inclue
    var rentalTo                : DateBoundary = DateBoundary.empty // année exclue
    var monthlyRentAfterCharges : Double = 0.0 // frais agence, taxe foncière et assurance déduite
    var yearlyRentAfterCharges  : Double {
        return monthlyRentAfterCharges * 12
    }
    // même base que pour le calcul des charges sociales
    var yearlyRentTaxableIrpp   : Double {
        return yearlyRentAfterCharges
    }
    // même base que pour le calcul de l'IRPP
    var yearlyRentSocialTaxes   : Double {
        return Fiscal.model.socialTaxesOnFinancialRevenu.socialTaxes(yearlyRentAfterCharges)
    }
    // profitabilité nette de charges (frais agence, taxe foncière et assurance)
    var profitability           : Double {
        return yearlyRentAfterCharges / (estimatedValue == 0 ? buyingPrice : estimatedValue)
    }
    
    // MARK: - Initializers
    
    
    // MARK: - Methods
    
    
    /// Valeur à la date spécifiée
    /// - Parameter year: fin de l'année
    func value(atEndOf year: Int) -> Double {
        if isOwned(before: year) {
            return (estimatedValue == 0 ? buyingPrice : estimatedValue)
        } else {
            return 0.0
        }
    }
    
    /// calcule la valeur d'un bien à l'IFI ou à l'ISF
    ///  - Note:
    ///  Pour l'IFI:
    ///
    ///  Valeur retenue:
    ///  - la résidence principale faire l’objet d’une décote de 30 %
    ///  - les immeubles que vous donnez en location peuvent faire l’objet d’une décote de 10 % à 30 % environ
    ///  - en indivision : dans ce cas, ils sont imposables à hauteur de votre quote-part minorée d’une décote de l’ordre de 30 % pour tenir compte des contraintes liées à l’indivision)
    func ifiValue(atEndOf year: Int) -> Double {
        if self.isInhabited(during: year) {
            // decote de la résience principale
            return value(atEndOf: year) * (1.0 - Fiscal.model.isf.model.decoteResidence/100.0)

        } else if self.isRented(during: year) {
            // decote d'un bien en location
            return value(atEndOf: year) * (1.0 - Fiscal.model.isf.model.decoteLocation/100.0)

        } else {
            return value(atEndOf: year)
        }
    }
    
    func ownedValue(by ownerName     : String,
                    atEndOf year     : Int,
                    evaluationMethod : EvaluationMethod) -> Double {
        var evaluatedValue : Double

        switch evaluationMethod {
            case .ifi, .isf:
                evaluatedValue = ifiValue(atEndOf: year)
            default:
                evaluatedValue = value(atEndOf: year)
        }
        return evaluatedValue == 0 ? 0 : ownership.ownedValue(by               : ownerName,
                                                              ofValue          : evaluatedValue,
                                                              atEndOf          : year,
                                                              evaluationMethod : evaluationMethod)
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
        guard willBeSold, let sellingDate = sellingYear.year else {
            return false
        }
        return year > sellingDate
    }
    
    /// true si le bien est en possession
    /// - Parameter year: année
    func isOwned(before year: Int) -> Bool {
        guard let buyingDate = buyingYear.year else {
            return false
        }
        if isSold(before: year) {
            // le bien est vendu
            return false
        } else if year >= buyingDate {
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
    (revenue: Double,
     capitalGain: Double,
     netRevenue: Double,
     socialTaxes: Double,
     irpp: Double) {
        guard (willBeSold && year == sellingYear.year!) else {
            return (0,0,0,0,0)
        }
        let detentionDuration = sellingYear.year! - buyingYear.year!
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

