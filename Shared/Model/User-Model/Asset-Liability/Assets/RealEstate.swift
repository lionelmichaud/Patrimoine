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

struct RealEstateAsset: Identifiable, BundleCodable, Ownable {
    
    // MARK: - Static Properties
    
    static var defaultFileName : String = "RealEstateAsset.json"
    // dependencies
    private static var fiscalModel: Fiscal.Model = Fiscal.model
    //    static var simulationMode : SimulationModeEnum = .deterministic
    
    // MARK: - Static Methods
    
    /// Dependency Injection: Setter Injection
    static func setFiscalModelProvider(_ fiscalModel : Fiscal.Model) {
        RealEstateAsset.fiscalModel = fiscalModel
    }
    
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
        guard willBeSold else { return 0 }
        guard let sellingDate = sellingYear.year, let buyingDate = buyingYear.year else { return 0 }
        let detentionDuration = zeroOrPositive(sellingDate - buyingDate)
        let capitalGain       = sellingNetPrice - buyingPrice
        let socialTaxes       = RealEstateAsset.fiscalModel.estateCapitalGainTaxes.socialTaxes(
            capitalGain      : capitalGain,
            detentionDuration: detentionDuration)
        let irpp              = RealEstateAsset.fiscalModel.estateCapitalGainIrpp.irpp(
            capitalGain      : capitalGain,
            detentionDuration: detentionDuration)
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
        return RealEstateAsset.fiscalModel.financialRevenuTaxes.socialTaxes(yearlyRentAfterCharges)
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
        if isOwned(during: year) {
            return (estimatedValue == 0 ? buyingPrice : estimatedValue)
        } else {
            return 0.0
        }
    }
    
    /// calcule la valeur d'un bien à l'IFI ou à l'ISF
    ///  - Note:
    ///  Valeur retenue:
    ///  - la résidence principale faire l’objet d’une décote de 30 %
    ///  - les immeubles que vous donnez en location peuvent faire l’objet d’une décote de 10 % à 30 % environ
    ///  - en indivision : dans ce cas, ils sont imposables à hauteur de votre quote-part minorée d’une décote de l’ordre de 30 % pour tenir compte des contraintes liées à l’indivision)
    func ifiValue(atEndOf year: Int) -> Double {
        if !isOwned(during: year) {
            return 0.0

        } else if self.isInhabited(during: year) {
            // decote de la résidence principale
            return value(atEndOf: year) * (1.0 - RealEstateAsset.fiscalModel.isf.model.decoteResidence/100.0)
            
        } else if self.isRented(during: year) {
            // decote d'un bien en location
            return value(atEndOf: year) * (1.0 - RealEstateAsset.fiscalModel.isf.model.decoteLocation/100.0)
            
        } else {
            // pas de décote
            return value(atEndOf: year)
        }
    }
    
    /// calcule la valeur d'un bien selon les règle du droit de la succession
    ///  - Note:
    ///  Valeur retenue:
    ///  La maison ou l'appartement, qui était la résidence principale du défunt, bénéficie d'un abattement de 20 %
    ///  de sa valeur.
    ///
    ///  Il devait alors être aussi, le jour du décès, la résidence principale :
    ///   - de l'époux(se) survivant(e)
    ///   - ou du partenaire de Pacs
    ///   - ou de l'enfant (mineur ou majeur protégé) du défunt, de son époux(se) ou partenaire de Pacs
    ///   - ou de l'enfant majeur du défunt, de son époux(se) ou partenaire de Pacs dont l'infirmité physique ou mentale ne lui permettent pas d'avoir un revenu suffisant.
    ///
    ///  - les immeubles que vous donnez en location peuvent faire l’objet d’une décote de 10 % à 30 % environ
    ///  - en indivision : dans ce cas, ils sont imposables à hauteur de votre quote-part minorée d’une décote de l’ordre de 30 % pour tenir compte des contraintes liées à l’indivision)
    func inheritanceValue(atEndOf year: Int) -> Double {
        if !isOwned(during: year) {
            return 0.0

        } else if self.isInhabited(during: year) {
            // decote de la résidence principale
            return value(atEndOf: year) * (1.0 - RealEstateAsset.fiscalModel.inheritanceDonation.model.decoteResidence/100.0)
            
        } else {
            // pas de décote
            return value(atEndOf: year)
        }
    }
    
    /// Calcule la valeur d'un bien possédée par un personne donnée à une date donnée
    /// selon la régle générale ou selon la règle de l'IFI, de l'ISF, de la succession...
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - year: date d'évaluation
    ///   - evaluationMethod: méthode d'évaluation de la valeure des bien
    /// - Returns: valeur du bien possédée (part d'usufruit + part de nue-prop)
    func ownedValue(by ownerName     : String,
                    atEndOf year     : Int,
                    evaluationMethod : EvaluationMethod) -> Double {
        var evaluatedValue : Double
        
        switch evaluationMethod {
            case .ifi, .isf:
                // appliquer la décote IFI
                evaluatedValue = ifiValue(atEndOf: year)
                
            case .legalSuccession:
                // le défunt est-il usufruitier ?
                if ownership.isAnUsufructOwner(ownerName: ownerName) {
                    // si oui alors l'usufruit rejoint la nu-propriété sans droit de succession
                    // l'usufruit n'est donc pas intégré à la masse successorale du défunt
                    return 0
                }
                // appliquer la décote succession
                evaluatedValue = inheritanceValue(atEndOf: year)
                
            case .lifeInsuranceSuccession:
                // on recherche uniquement les assurances vies
                return 0
                
            case .patrimoine:
                // pas de décote
                evaluatedValue = value(atEndOf: year)
        }
        // calculer la part de propriété
        let value = evaluatedValue == 0 ? 0 :
            ownership.ownedValue(by               : ownerName,
                                 ofValue          : evaluatedValue,
                                 atEndOf          : year,
                                 evaluationMethod : evaluationMethod)
        return value
    }
    
    /// True si year est dans la période d'habitation
    /// - Parameter year: année
    /// - Note:
    ///   - la premièe année est inclue
    ///   - la dernière année est exclue
    func isInhabited(during year: Int) -> Bool {
        guard willBeInhabited && !isSold(before: year) else {
            return false
        }
        return (inhabitedFrom.year! ..< inhabitedTo.year!).contains(year)
    }
    
    /// Impôts locaux
    /// - Parameter year: année
    func yearlyLocalTaxes(during year: Int) -> Double {
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
    
    /// True si year est dans la période de location
    /// - Parameter year: année
    /// - Note:
    ///   - la premièe année est inclue
    ///   - la dernière année est exclue
    func isRented(during year: Int) -> Bool {
        guard willBeRented && !isSold(before: year) else {
            return false
        }
        return (rentalFrom.year! ..< rentalTo.year!).contains(year)
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
    
    /// True si l'année est postérieure à l'année de vente
    /// - Parameter year: année
    func isSold(before year: Int) -> Bool {
        guard willBeSold, let sellingDate = sellingYear.year else {
            return false
        }
        return year > sellingDate
    }
    
    /// True si le bien est en possession au moins un jour pendant l'année demandée
    /// - Parameter year: année
    func isOwned(during year: Int) -> Bool {
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
    (revenue     : Double,
     capitalGain : Double,
     netRevenue  : Double,
     socialTaxes : Double,
     irpp        : Double) {
        guard willBeSold && year == sellingYear.year! else {
            return (0, 0, 0, 0, 0)
        }
        let detentionDuration = sellingYear.year! - buyingYear.year!
        let capitalGain       = self.sellingNetPrice - buyingPrice
        let socialTaxes       = RealEstateAsset.fiscalModel.estateCapitalGainTaxes.socialTaxes(
            capitalGain      : zeroOrPositive(capitalGain),
            detentionDuration: detentionDuration)
        let irpp              = RealEstateAsset.fiscalModel.estateCapitalGainIrpp.irpp(
            capitalGain: zeroOrPositive(capitalGain),
            detentionDuration: detentionDuration)
        return (revenue     : self.sellingNetPrice,
                capitalGain : capitalGain,
                netRevenue  : self.sellingNetPrice - socialTaxes - irpp,
                socialTaxes : socialTaxes,
                irpp        : irpp)
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
        let s1 =
        """
        IMMOBILIER: \(name)
        - Acheté en \(buyingYear) au prix de \(buyingPrice.€String)
        - Note:
        \(note.withPrefixedSplittedLines("    "))
        - Droits de propriété:
        \(ownership.description.withPrefixedSplittedLines("  "))
        - Valeur vénale estimée: \(estimatedValue.€String)\n
        """
        var s2: String = ""
        if willBeInhabited {
            s2 =
            """
            - Habité de \(inhabitedFrom) à \(inhabitedTo)
              - Taxe d'habitation: \(yearlyTaxeHabitation.€String)
              - Taxe fonçière:     \(yearlyTaxeFonciere.€String) \n
            """
        }
        
        var s3: String = ""
        if willBeRented {
            s3 =
                """
                - Loué de \(rentalFrom) à \(rentalTo)
                  - Loyer mensuel:        \(monthlyRentAfterCharges.€String)
                  - Loyer annuel:         \(yearlyRentAfterCharges.€String)
                  - Loyer annuel taxable: \(yearlyRentTaxableIrpp.€String)
                  - Profitabilité:        \((profitability*100.0).percentString(digit: 1)) % \n
                """
        }
        
        var s4: String = ""
        if willBeSold {
            s4 =
                """
                - Vendu en \(sellingYear) au prix de \(sellingNetPrice.€String)
                  - Produit de la vente net de taxes \(sellingPriceAfterTaxes.€String)\n
                """
        }

        return s1 + s2 + s3 + s4
    }
}
