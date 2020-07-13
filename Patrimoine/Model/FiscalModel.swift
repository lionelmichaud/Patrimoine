//
//  Taxes.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct Fiscal: Codable {
    struct Model: Codable {
        var irppOnEstateCapitalGain        : IrppOnRealEstateCapitalGain
        var socialTaxesOnEstateCapitalGain : SocialTaxesOnRealEstateCapitalGain
        var pensionTaxes                   : PensionTaxes
        var socialTaxesOnFinancialRevenu   : SocialTaxesOnFinancialRevenu
        var socialTaxesOnTurnover          : SocialTaxesOnTurnover
        var socialTaxesOnAllocationChomage : SocialTaxesOnAllocationChomage
        var lifeInsuranceTaxes             : LifeInsuranceTaxes
        var incomeTaxes                    : IncomeTaxes
        var companyProfitTaxes             : CompanyProfitTaxes
    }
    
    static var model: Model  =
            Bundle.main.decode(Model.self,
                               from                 : "FiscalModel.json",
                               dateDecodingStrategy : .iso8601,
                               keyDecodingStrategy  : .useDefaultKeys)
}

// MARK: - Impôts sur plus-values immobilières
/// impôts sur plus-values immobilières
struct IrppOnRealEstateCapitalGain: Codable {
    
    // nested types
    
    // tranche de barême de l'IRPP
    struct ExonerationSlice: Codable {
        var floor        : Int    = 0 // year
        var discountRate : Double = 0.0 // % par année de détention au-delà de floor
        var prevDiscount : Double = 0.0 // % cumul des tranches précédentes
    }
    
    struct Model: Codable {
        let exoGrid : [ExonerationSlice]
        let irpp    : Double = 19.0 // %
    }
    
    // properties
    
    // barême de l'exoneration de charges sociale sur les plus-values immobilières
    var model: Model
    
    // methods
    
    /**
     Impôt sur le revenu dû sur la plus-value immobilièrae
     La plus-value est taxée au titre de l’impôt sur le revenu au taux forfaitaire actuel de 19 % (avec un abattement linéaire de 6 % à partir de la 6ème année)
     et au titre des prélèvements sociaux au taux actuel de 17,2 % (avec un abattement progressif à partir de la 6ème année).
     Le montant de l’impôt sera prélevé par le notaire sur le prix de vente lors de la signature de l’acte authentique et versé par ses soins à l’administration fiscale.
     
     - Parameter capitalGain: plus-value immobilière
     - Parameter detentionDuration: durée de la détention du bien
     
     - Returns: Impôt sur le revenu dû sur la plus-value immobilièrae
     **/
    func irpp (capitalGain       : Double,
               detentionDuration : Int) -> Double {
        // exoneration partielle ou totale de charges sociales en fonction de la durée de détention
        var discount = 0.0
        if let slice = model.exoGrid.last(where: { $0.floor < detentionDuration}) {
            discount = min(slice.prevDiscount + slice.discountRate * Double(detentionDuration - slice.floor), 100.0)
        }
        return capitalGain * (1.0 - discount / 100.0) * model.irpp / 100.0
    }
}

// MARK: - Charges sociales sur plus-values immobilières
/// Charges sociales sur plus-alues immobilières
struct SocialTaxesOnRealEstateCapitalGain: Codable {
    
    // nested types
    
    // tranche de barême de l'IRPP
    struct ExonerationSlice: Codable {
        var floor        : Int    = 0 // year
        var discountRate : Double = 0.0 // % par année de détention au-delà de floor
        var prevDiscount : Double = 0.0 // % cumul des tranches précédentes
    }
    
    // properties
    
    // barême de l'exoneration de charges sociale sur les plus-values immobilières
    //    static let exoGrid : [ExonerationSlice] =
    //        [ExonerationSlice(floor:  5, discountRate: 1.65, prevDiscount: 0.0),
    //         ExonerationSlice(floor: 21, discountRate: 1.60, prevDiscount: (21-5)*1.65),
    //         ExonerationSlice(floor: 22, discountRate: 9.00, prevDiscount: (21-5)*1.65 + (22-21)*1.6),
    //         ExonerationSlice(floor: 30, discountRate: 0.00, prevDiscount: (21-5)*1.65 + (22-21)*1.6 + (30-22)*9.0)]
    //static let detentionDurationExonartion : Int = 30 // ans
    
    struct Model: Codable {
        let exoGrid      : [ExonerationSlice]
        let CRDS         : Double = 0.5 // %
        let CSG          : Double = 9.2 // %
        let prelevSocial : Double = 7.5 // %
        var total        : Double {
            CRDS + CSG + prelevSocial // %
        }
    }
    
    var model: Model
    
    // methods
    
    /**
     Charges sociales dûes sur la plus-value immobilièrae
     La plus-value est taxée au titre de l’impôt sur le revenu au taux forfaitaire actuel de 19 % (avec un abattement linéaire de 6 % à partir de la 6ème année)
     et au titre des prélèvements sociaux au taux actuel de 17,2 % (avec un abattement progressif à partir de la 6ème année).
     Le montant de l’impôt sera prélevé par le notaire sur le prix de vente lors de la signature de l’acte authentique et versé par ses soins à l’administration fiscale.
     
     - Parameter capitalGain: plus-value immobilière
     - Parameter detentionDuration: durée de la détention du bien
     
     - Returns: Charges sociales dûes sur la plus-value immobilièrae
     **/
    func socialTaxes (capitalGain       : Double,
                      detentionDuration : Int) -> Double {
        // exoneration partielle ou totale de charges sociales en fonction de la durée de détention
        var discount = 0.0
        if let slice = model.exoGrid.last(where: { $0.floor < detentionDuration}) {
            discount = min(slice.prevDiscount + slice.discountRate * Double(detentionDuration - slice.floor), 100.0)
        }
        return capitalGain * (1.0 - discount / 100.0) * model.total / 100.0
    }
}

// MARK: - Charges sociales sur pensions de retraite
/// https://www.service-public.fr/particuliers/vosdroits/F2971
/// Charges sociales sur pensions de retraite
struct PensionTaxes: Codable {
    
    // properties
    
    struct Model: Codable {
        let rebate            : Double = 10.0 // %
        let minRebate         : Double = 393   // € par déclarant
        let maxRebate         : Double = 3_850 // € par foyer fiscal
        let CSGdeductible     : Double = 5.9 // %
        let CRDS              : Double = 0.5 // %
        let CSG               : Double = 8.3 // %
        let additionalContrib : Double = 0.3 // %
        let healthInsurance   : Double = 1.0 // %
        var total             : Double {
            CRDS + CSG + additionalContrib + healthInsurance // %
        }
    }
    
    var model: Model
    
    // methods
    
    /// pension nette de charges sociales
    /// - Parameter brut: pension brute
    func net(_ brut: Double) -> Double {
        brut * (1.0 - model.total / 100.0)
    }
    
    /// charges sociales sur une pension brute
    /// - Parameter brut: pension brute
    func socialTaxes(_ brut: Double) -> Double {
        brut * model.total / 100.0
    }
    
    /// Calcule la pension taxable à l'IRPP en applicant un abattement plafonné
    /// - Parameter net: pension nette de charges sociales
    /// - Returns: pension taxable à l'IRPP
    func taxable(from net: Double) -> Double {
        let rebate = (net * model.rebate / 100.0).clamp(low: model.minRebate, high: model.maxRebate)
        return net - rebate
    }
    
    // TODO: - Taux CSG déductible de l'impôt sur le revenu 5.9%
    func csgDeductibleDeIrpp(_ brut: Double) -> Double {
        brut * model.CSGdeductible
    }
}

// MARK: - Charges sociales sur revenus financiers (dividendes, plus values, loyers...)
// charges sociales sur revenus financiers (dividendes, plus values, loyers...)
struct SocialTaxesOnFinancialRevenu: Codable {
    
    // properties
    
    //    static let CRDS         : Double = 0.5 // %
    //    static let CSG          : Double = 9.2 // %
    //    static let prelevSocial : Double = 7.5 // %
    //    static let total = CRDS + CSG + prelevSocial // %
    
    struct Model: Codable {
        let CRDS         : Double = 0.5 // %
        let CSG          : Double = 9.2 // %
        let prelevSocial : Double = 7.5  // %
        var total        : Double {
            CRDS + CSG + prelevSocial // %
        }
    }
    
    var model: Model
    
    // methods
    
    /// revenus financiers nets de charges sociales
    /// - Parameter brut: revenus financiers bruts
    func net(_ brut: Double) -> Double {
        brut * (1.0 - model.total / 100.0)
    }
    
    /// charges sociales sur les revenus financiers
    /// - Parameter brut: revenus financiers bruts
    func socialTaxes(_ brut: Double) -> Double {
        brut * model.total / 100.0
    }
    
    /// revenus financiers bruts avant charges sociales
    /// - Parameter net: revenus financiers nets
    func brut(_ net: Double) -> Double {
        net / (1.0 - model.total / 100.0)
    }
}

// MARK: - Charges sociales sur chiffre d'affaire
// charges sociales sur chiffre d'affaire
struct SocialTaxesOnTurnover: Codable {
    
    // properties
    
    struct Model: Codable {
        let URSSAF : Double = 24 // %
        var total  : Double {
            URSSAF // %
        }
    }
    
    var model: Model
    
    // methods
    
    /// chiffre d'affaire net de charges sociales
    /// - Parameter brut: chiffre d'affaire brut
    func net(_ brut: Double) -> Double {
        brut * (1.0 - model.URSSAF / 100.0)
    }
    
    /// charges sociales sur le chiffre d'affaire brut
    /// - Parameter brut: chiffre d'affaire brut
    func socialTaxes(_ brut: Double) -> Double {
        brut * model.URSSAF / 100.0
    }
}

// MARK: - Charges sociales sur allocation chomage
// charges sociales sur chiffre d'affaire
struct SocialTaxesOnAllocationChomage: Codable {
    
    // properties
    
    struct Model: Codable {
        let seuilCsgCrds : Double = 50.0 // €, pas cotisation en deça
        let CRDS         : Double = 0.5 * 0.9825 // %
        let CSG          : Double = 6.2 // %
        let retraiteCompl: Double = 3.0 // % du salaire journalier de référence
    }
    
    var model: Model
    
    // methods
    
    /// Allocation chomage journalière nette de charges sociales
    /// - Parameters:
    ///   - brut: allocation chomage journalière brute
    ///   - SJR: Salaire Journilier de Référence
    /// - Returns: allocation chomage journalière nette de charges sociales
    func net(brut: Double, SJR: Double) -> Double {
        brut - socialTaxes(brut: brut, SJR: SJR)
    }
    
    /// Charges sociales dur l'allocation chomage journalière brute
    /// - Parameters:
    ///   - brut: allocation chomage journalière brute
    ///   - SJR: Salaire Journilier de Référence
    /// - Returns: montant des charges sociales
    func socialTaxes(brut: Double, SJR: Double) -> Double {
        var cotisation = 0.0
        // CSG et CRDS
        if brut >= model.seuilCsgCrds {
            cotisation += brut * model.CRDS + brut * model.CSG
        }
        // cotisation au régime complémentaire de retraite
        cotisation += SJR * model.retraiteCompl
        return cotisation
    }
}

// MARK: - Impôt sur les plus-values d'assurance vie-Assurance vies
// Assurance vies
struct LifeInsuranceTaxes: Codable {
    
    struct Model: Codable {
        let rebatePerPerson: Double = 4800.0 // euros
    }
    
    var model: Model
}

// MARK: - Impôts sur le revenu
// impots sur le revenu
struct IncomeTaxes: Codable {
    
    // nested types
    
    // tranche de barême de l'IRPP
    struct IrppSlice: Codable {
        var floor : Double = 0.0 // euro
        var rate  : Double = 0.0 // %
        var disc  : Double = 0.0 // euro
    }
    
    struct Model: Codable {
        let irppGrid       : [IrppSlice]
        let turnOverRebate : Double = 34.0 // %
        let salaryRebate   : Double = 10.0 // %
        let minSalaryRebate: Double = 441 // €
        let maxSalaryRebate: Double = 12_627 // €
        let childRebate    : Double = 1_512.0 // €
    }
    
    // properties
    
    // barême de l'exoneration de charges sociale sur les plus-values immobilières
    var model: Model
    
    // methods
    
    /// Quotion familial
    /// - Parameters:
    ///   - nbAdults: nombre d'adultes
    ///   - nbChildren: nombre d'enfants
    /// - Returns: Quotion familial
    func familyQuotient(nbAdults: Int, nbChildren: Int) -> Double {
        Double(nbAdults) + Double(nbChildren) / 2.0
    }
    func netAndTaxableIncome(from personalIncome: PersonalIncomeType) -> (netIncome: Double, taxableIncome: Double) {
        switch personalIncome {
            case .salary(let netSalary, let charge):
                let netIncome = netSalary - charge
                let rebate = (netSalary * Fiscal.model.incomeTaxes.model.salaryRebate / 100.0).clamp(low : model.minSalaryRebate,
                                                                                                     high: model.maxSalaryRebate)
                let taxableIncome = netSalary - rebate
                return (netIncome: netIncome, taxableIncome: taxableIncome)
            
            case .turnOver(let BNC, let charge):
                let net = Fiscal.model.socialTaxesOnTurnover.net(BNC)
                let netIncome = net - charge
                let taxableIncome = BNC * (1 - Fiscal.model.incomeTaxes.model.turnOverRebate / 100.0)
                return (netIncome: netIncome, taxableIncome: taxableIncome)
        }
    }
    /// Impôt sur le revenu
    /// - Parameters:
    ///   - taxableIncome: revenu imposable
    ///   - nbAdults: nombre d'adulte dans la famille
    ///   - nbChildren: nombre d'enfant dans la famille
    /// - Returns: Impôt sur le revenu
    func irpp (taxableIncome : Double,
               nbAdults      : Int,
               nbChildren    : Int) -> Double {
        // FIXME: Vérifier calcul
        let familyQuotient = self.familyQuotient(nbAdults: nbAdults,
                                                        nbChildren: nbChildren)
        if let irppSlice = model.irppGrid.last(where: { $0.floor < taxableIncome / familyQuotient}) {
            // calcul de l'impot avec les parts des enfants
            let taxWithChildren = taxableIncome * irppSlice.rate - familyQuotient * irppSlice.disc
            //print("impot avec les parts des enfants =",taxWithChildren)
            // calcul de l'impot sans les parts des enfants
            let QuotientWithoutChildren = familyQuotient - Double(nbChildren)/2.0
            if let irppSlice2 = model.irppGrid.last(where: { $0.floor < taxableIncome / QuotientWithoutChildren}) {
                let taxWithoutChildren = taxableIncome * irppSlice2.rate - QuotientWithoutChildren * irppSlice2.disc
                //print("impot sans les parts des enfants =",taxWithoutChildren)
                // gain lié aux parts des enfants
                let gain = taxWithoutChildren - taxWithChildren
                //print("gain =",gain)
                // plafond de gain
                let maxGain = Double(nbChildren) * model.childRebate
                //print("gain max=",maxGain)
                // plafonnement du gain lié aux parts des enfants
                return (gain > maxGain ? taxWithoutChildren - maxGain : taxWithChildren)
            }
            return 0.0
        }
        return 0.0
    }
}

// MARK: - Impots sur les sociétés (SCI)
// impots sur les sociétés (SCI)
struct CompanyProfitTaxes: Codable {
    
    // properties
    
    struct Model: Codable {
        let rate: Double = 15.0 // %
    }
    
    var model: Model
    
    // methods
    
    /// bénéfice net
    /// - Parameter brut: bénéfice brut
    func net(_ brut: Double) -> Double {
        brut * (1.0 - model.rate / 100.0)
    }
    /// impôts sur les bénéfices
    /// - Parameter brut: bénéfice brut
    func IS(_ brut: Double) -> Double {
        brut * model.rate / 100.0
    }
}
