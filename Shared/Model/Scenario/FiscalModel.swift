//
//  Taxes.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct Fiscal: Codable {
    
    // nested types
    
    struct Model: Codable, Versionable {
        var version                        : Version
        var PASS                           : Double // Plafond Annuel de la Sécurité Sociale
        var irppOnEstateCapitalGain        : IrppOnRealEstateCapitalGain
        var socialTaxesOnEstateCapitalGain : SocialTaxesOnRealEstateCapitalGain
        var pensionTaxes                   : PensionTaxes
        var socialTaxesOnFinancialRevenu   : SocialTaxesOnFinancialRevenu
        var socialTaxesOnTurnover          : SocialTaxesOnTurnover
        var socialTaxesOnAllocationChomage : SocialTaxesOnAllocationChomage
        var layOffTaxes                    : LayOffTaxes
        var lifeInsuranceTaxes             : LifeInsuranceTaxes
        var incomeTaxes                    : IncomeTaxes
        var isf                            : IsfModel
        var companyProfitTaxes             : CompanyProfitTaxes
        var demembrement                   : DemembrementModel
        var inheritanceDonation            : InheritanceDonation
        var lifeInsuranceInheritance       : LifeInsuranceInheritance
    }
    
    // static method
    
    static func initializedModel() -> Model {
        var model = Bundle.main.decode(Model.self,
                                       from                 : "FiscalModelConfig.json",
                                       dateDecodingStrategy : .iso8601,
                                       keyDecodingStrategy  : .useDefaultKeys)
        model.incomeTaxes.initialize()
        model.isf.initialize()
        model.inheritanceDonation.initialize()
        model.lifeInsuranceInheritance.initialize()
        return model
    }
    
    // static properties
    
    static var model: Model = Fiscal.initializedModel()
}

// MARK: - Impôts sur plus-values immobilières
/// impôts sur plus-values immobilières
struct IrppOnRealEstateCapitalGain: Codable {
    
    // nested types
    
    // tranche de barême de l'IRPP
    struct ExonerationSlice: Codable {
        let floor        : Int // year
        let discountRate : Double // % par année de détention au-delà de floor
        let prevDiscount : Double // % cumul des tranches précédentes
    }
    
    struct Model: Codable, Versionable {
        var version : Version
        let exoGrid : [ExonerationSlice]
        let irpp    : Double // 19.0 // %
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
        let floor        : Int    // 0 // year
        let discountRate : Double // 0.0 // % par année de détention au-delà de floor
        let prevDiscount : Double // 0.0 // % cumul des tranches précédentes
    }
    
    // barême de l'exoneration de charges sociale sur les plus-values immobilières
    //    static let exoGrid : [ExonerationSlice] =
    //        [ExonerationSlice(floor:  5, discountRate: 1.65, prevDiscount: 0.0),
    //         ExonerationSlice(floor: 21, discountRate: 1.60, prevDiscount: (21-5)*1.65),
    //         ExonerationSlice(floor: 22, discountRate: 9.00, prevDiscount: (21-5)*1.65 + (22-21)*1.6),
    //         ExonerationSlice(floor: 30, discountRate: 0.00, prevDiscount: (21-5)*1.65 + (22-21)*1.6 + (30-22)*9.0)]
    //static let detentionDurationExonartion : Int = 30 // ans
    
    struct Model: Codable, Versionable {
        var version      : Version
        let exoGrid      : [ExonerationSlice]
        let CRDS         : Double // 0.5 // %
        let CSG          : Double // 9.2 // %
        let prelevSocial : Double // 7.5 // %
        var total        : Double {
            CRDS + CSG + prelevSocial // %
        }
    }
    
    // properties
    
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
    
    // nested types
    
    struct Model: Codable, Versionable {
        var version           : Version
        let rebate            : Double // 10.0 // %
        let minRebate         : Double // 393   // € par déclarant
        let maxRebate         : Double // 3_850 // € par foyer fiscal
        let CSGdeductible     : Double // 5.9 // %
        let CRDS              : Double // 0.5 // %
        let CSG               : Double // 8.3 // %
        let additionalContrib : Double // 0.3 // %
        let healthInsurance   : Double // 1.0 // %
        var total             : Double {
            CRDS + CSG + additionalContrib + healthInsurance // %
        }
    }
    
    // properties
    
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
    /// - Reference: https://www.l-expert-comptable.com/a/532523-csg-deductible-en-2018.html
    func taxable(from brut: Double) -> Double {
        let base   = net(brut) + csgNonDeductibleDeIrpp(brut)
        // TODO: - il faudrait prendre en compte que le rabais maxi est par foyer et non pas par personne
        let rebate = (base * model.rebate / 100.0).clamp(low: model.minRebate, high: model.maxRebate)
        return max (0, base - rebate)
    }
    
    // TODO: - Prendre en compte la CSG déductible du revenu imposable sur le revenu 5.9%
    /// Calcule le montant de CSG NON déductible du revenu imposable
    /// - Parameter brut: pension brute
    /// - Returns: fraction de la pension NON déductible du revenu imposable
    /// - Reference: https://www.l-expert-comptable.com/a/532523-csg-deductible-en-2018.html
    func csgNonDeductibleDeIrpp(_ brut: Double) -> Double {
        brut * (model.CSG - model.CSGdeductible) / 100.0
    }
}

// MARK: - Charges sociales sur revenus financiers (dividendes, plus values, loyers...)
// charges sociales sur revenus financiers (dividendes, plus values, loyers...)
struct SocialTaxesOnFinancialRevenu: Codable {
    
    //    static let CRDS         : Double = 0.5 // %
    //    static let CSG          : Double = 9.2 // %
    //    static let prelevSocial : Double = 7.5 // %
    //    static let total = CRDS + CSG + prelevSocial // %
    
    // nested types
    
    struct Model: Codable, Versionable {
        var version      : Version
        let CRDS         : Double // 0.5 // %
        let CSG          : Double // 9.2 // %
        let prelevSocial : Double // 7.5  // %
        var total        : Double {
            CRDS + CSG + prelevSocial // %
        }
    }
    
    // properties
    
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
    
    // nested types
    
    struct Model: Codable, Versionable {
        var version: Version
        let URSSAF : Double // 24 // %
        var total  : Double {
            URSSAF // %
        }
    }
    
    // properties
    
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

// MARK: - Charges sociales sur l'indemnité de licenciement
// https://www.service-public.fr/particuliers/vosdroits/F987
struct LayOffTaxes: Codable {
    
    // nested types
    
    struct SocialTaxes: Codable {
        let maxRebateCoef : Double // 2 x PASS
        var maxRebate     : Double {
            maxRebateCoef * Fiscal.model.PASS
        }
        let rate          : Double // 13 % (le même que sur le salaire)
    }
    struct CsgCrds: Codable {
        let rateDeductible    : Double // 6.5 %
        let rateNonDeductible : Double // 2.9 %
        var rateTotal         : Double {
            rateDeductible + rateNonDeductible
        }
    }
    struct Model: Codable, Versionable {
        var version     : Version
        let socialTaxes : SocialTaxes
        let csgCrds     : CsgCrds
    }
    
    // properties
    
    var model: Model
    
    // methods
    
    func net(compensationConventional  : Double,
             compensationBrut          : Double,
             compensationTaxable : inout Double,
             irppDiscount              : Double) -> Double {
        var net = compensationBrut
        
        // La fraction de l'indemnité de licenciement exonérée d'impôt sur le revenu est également exonérée de cotisations sociales, dans la limite de 82 272 €.
        // base de calcul des charges sociales
        let discountSocialtaxes = min(model.socialTaxes.maxRebate, irppDiscount)
        let baseSocialtaxes = max(compensationBrut - discountSocialtaxes, 0.0)
        // montant des charges sociaes à payer
        let socialTaxes = baseSocialtaxes * model.socialTaxes.rate / 100
        
        net -= socialTaxes
        
        // L'indemnité de licenciement est exonérée de CSG et CRDS à hauteur de la plus petite des 2 limites suivantes:
        //  - Montant de l'indemnité légale ou conventionnelle de licenciement dû au salarié licencié
        let discount1 = compensationConventional
        //  - Montant de l'indemnité exonéré de cotisations sociales
        let discount2 = discountSocialtaxes
        // plus petite des 2 limites
        let discountCsgCrds = min(discount1, discount2)
        // base de calcul de la CSG et du CRDS
        let baseCsgCrds = max(compensationBrut - discountCsgCrds, 0.0)
        // montant de la CSG et du CRDS à payer
        let csgCrds = baseCsgCrds * model.csgCrds.rateTotal / 100
        
        net -= csgCrds
        
        // retirer du montant de l'indemnité taxable à l'IRPP la part déductibe de la CSG
        let csgDeductible = max(baseCsgCrds * model.csgCrds.rateDeductible / 100, 0)
        compensationTaxable = max(compensationTaxable - csgDeductible, 0)
        
        return net
    }
}
// MARK: - Charges sociales sur allocation chomage
// charges sociales sur chiffre d'affaire
struct SocialTaxesOnAllocationChomage: Codable {
    
    // nested types
    
    struct Model: Codable, Versionable {
        var version      : Version
        let seuilCsgCrds : Double // 50.0 // €, pas cotisation en deça
        let CRDS         : Double // 0.5 * 0.9825 // %
        let CSG          : Double // 6.2 // %
        let retraiteCompl: Double // 3.0 // % du salaire journalier de référence
    }
    
    // properties
    
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
            cotisation += brut * model.CRDS / 100 + brut * model.CSG / 100
        }
        // cotisation au régime complémentaire de retraite
        cotisation += SJR * model.retraiteCompl / 100
        return cotisation
    }
}

// MARK: - Impôt sur les plus-values d'assurance vie-Assurance vies
// Assurance vies
struct LifeInsuranceTaxes: Codable {
    
    // nested types
    
    struct Model: Codable, Versionable {
        var version        : Version
        let rebatePerPerson: Double // 4800.0 // euros
    }
    
    // properties
    
    var model: Model
}

// MARK: - Impôts sur le revenu

struct IncomeTaxes: Codable {
    
    // nested types
    
    typealias IRPP = (amount         : Double,
                      familyQuotient : Double,
                      marginalRate   : Double,
                      averageRate    : Double)
    
    typealias SlicedIRPP = [(size                : Double,
                             sizeithChildren     : Double,
                             sizeithoutChildren  : Double,
                             rate                : Double,
                             irppMax             : Double,
                             irppWithChildren    : Double,
                             irppWithoutChildren : Double)]
    
    // tranche de barême de l'IRPP
    struct IrppSlice: Codable {
        let floor : Double // euro
        let rate  : Double // %
        var disc  : Double // euro
    }
    
    struct Model: Codable, Versionable {
        var version        : Version
        var irppGrid       : [IrppSlice]
        let turnOverRebate : Double // 34.0 // %
        let salaryRebate   : Double // 10.0 // %
        let minRebate      : Double // 441 // €
        let maxRebate      : Double // 12_627 // €
        let childRebate    : Double // 1_512.0 // €
    }
    
    // properties
    
    // barême de l'exoneration de charges sociale sur les plus-values immobilières
    var model: Model
    
    // methods
    
    /// Initializer les paramètres calculés pour les tranches d'imposition à partir des seuils et des taux
    mutating func initialize() {
        for idx in model.irppGrid.startIndex ..< model.irppGrid.endIndex {
            if idx == 0 {
                model.irppGrid[idx].disc = model.irppGrid[idx].floor * (model.irppGrid[idx].rate - 0)
            } else {
                model.irppGrid[idx].disc =
                    model.irppGrid[idx-1].disc +
                    model.irppGrid[idx].floor * (model.irppGrid[idx].rate - model.irppGrid[idx-1].rate)
            }
        }
    }
    
    /// Quotion familial
    /// - Parameters:
    ///   - nbAdults: nombre d'adultes
    ///   - nbChildren: nombre d'enfants
    /// - Returns: Quotion familial
    func familyQuotient(nbAdults: Int, nbChildren: Int) -> Double {
        Double(nbAdults) + Double(nbChildren) / 2.0
    }
    
    /// Calcul du revenu imposable
    /// - Parameter personalIncome: revenus
    /// - Returns: revenu imposable
    func taxableIncome(from personalIncome: WorkIncomeType) -> Double {
        switch personalIncome {
            case .salary(_, let taxableSalary, _, _, _):
                // application du rabais sur le salaire imposable
                let rebate = (taxableSalary * Fiscal.model.incomeTaxes.model.salaryRebate / 100.0).clamp(low : model.minRebate,
                                                                                                         high: model.maxRebate)
                return taxableSalary - rebate
                
            case .turnOver(let BNC, _):
                return BNC * (1 - Fiscal.model.incomeTaxes.model.turnOverRebate / 100.0)
        }
    }
    
    func slicedIrpp(taxableIncome : Double,
                    nbAdults      : Int,
                    nbChildren    : Int) -> SlicedIRPP {
        guard nbAdults != 0 else {
            return []
        }
        
        let familyQuotient = self.familyQuotient(nbAdults  : nbAdults,
                                                 nbChildren: nbChildren)
        let taxableIncomeWithChildren = taxableIncome / familyQuotient
        guard let irppSliceIdx = model.irppGrid.lastIndex(where: { $0.floor < taxableIncomeWithChildren}) else {
            return []
        }
        
        let QuotientWithoutChildren = self.familyQuotient(nbAdults  : nbAdults,
                                                          nbChildren: 0)
        let taxableIncomeWithoutChildren = taxableIncome / QuotientWithoutChildren
        guard let irppSliceIdx2 = model.irppGrid.lastIndex(where: { $0.floor < taxableIncomeWithoutChildren}) else {
            return []
        }

        var slices = SlicedIRPP()
        for idx in 0 ..< model.irppGrid.count {
            var size               : Double
            var irppMax            : Double
            var sizeithChildren    : Double
            var sizeithoutChildren : Double
            let rate = model.irppGrid[idx].rate
            
            if idx == model.irppGrid.endIndex - 1 {
                size    = 10000
                irppMax = 0
            } else {
                size    = model.irppGrid[idx+1].floor - model.irppGrid[idx].floor
                irppMax = model.irppGrid[idx].rate * size
            }
            
            var irppWithChildren: Double
            switch idx {
                case 0 ..< irppSliceIdx:
                    sizeithChildren  = size
                    irppWithChildren = irppMax

                case irppSliceIdx:
                    sizeithChildren = taxableIncomeWithChildren - model.irppGrid[idx].floor
                    irppWithChildren = rate * sizeithChildren

                case irppSliceIdx... :
                    sizeithChildren  = 0
                    irppWithChildren = 0

                default:
                    sizeithChildren  = 0
                    irppWithChildren = 0
            }

            var irppWithoutChildren: Double
            switch idx {
                case 0 ..< irppSliceIdx2:
                    sizeithoutChildren  = size
                    irppWithoutChildren = irppMax

                case irppSliceIdx2:
                    sizeithoutChildren  = taxableIncomeWithoutChildren - model.irppGrid[idx].floor
                    irppWithoutChildren = rate * sizeithoutChildren

                case irppSliceIdx2... :
                    sizeithoutChildren  = 0
                    irppWithoutChildren = 0

                default:
                    sizeithoutChildren  = 0
                    irppWithoutChildren = 0
            }

            slices.append((size               : size,
                           sizeithChildren    : sizeithChildren,
                           sizeithoutChildren : sizeithoutChildren,
                           rate                  : rate,
                           irppMax               : irppMax,
                           irppWithChildren      : irppWithChildren,
                           irppWithoutChildren   : irppWithoutChildren))
        }
        
        return slices
    }
    
    /// Impôt sur le revenu
    /// - Parameters:
    ///   - taxableIncome: revenu imposable
    ///   - nbAdults: nombre d'adulte dans la famille
    ///   - nbChildren: nombre d'enfant dans la famille
    /// - Returns: Impôt sur le revenu
    func irpp (taxableIncome : Double,
               nbAdults      : Int,
               nbChildren    : Int) -> IRPP {
        guard nbAdults != 0 else {
            return (amount         : 0.0,
                    familyQuotient : 0.0,
                    marginalRate   : 0.0,
                    averageRate    : 0.0)
        }
        
        // FIXME: Vérifier calcul
        let familyQuotient = self.familyQuotient(nbAdults  : nbAdults,
                                                 nbChildren: nbChildren)
        if let irppSlice = model.irppGrid.last(where: { $0.floor < taxableIncome / familyQuotient}) {
            // calcul de l'impot avec les parts des enfants
            let taxWithChildren = taxableIncome * irppSlice.rate - familyQuotient * irppSlice.disc
            //print("impot avec les parts des enfants =",taxWithChildren)
            // calcul de l'impot sans les parts des enfants
            let QuotientWithoutChildren = self.familyQuotient(nbAdults  : nbAdults,
                                                              nbChildren: 0)
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
                if gain > maxGain {
                    let irpp = taxWithoutChildren - maxGain
                    return (amount         : irpp,
                            familyQuotient : familyQuotient,
                            marginalRate   : irppSlice.rate,
                            averageRate    : irpp / taxableIncome)
                } else {
                    let irpp = taxWithChildren
                    return (amount         : irpp,
                            familyQuotient : familyQuotient,
                            marginalRate   : irppSlice.rate,
                            averageRate    : irpp / taxableIncome)
                }
            } else {
                fatalError()
            }
        }
        return (amount         : 0.0,
                familyQuotient : familyQuotient,
                marginalRate   : 0.0,
                averageRate    : 0.0)
    }
}

// MARK: - Impôts sur la fortune

struct IsfModel: Codable {
    
    // nested types
    
    typealias ISF = (amount       : Double,
                     taxable      : Double,
                     marginalRate : Double)
    
    typealias SlicedISF = [(size                : Double,
                            sizeithChildren     : Double,
                            sizeithoutChildren  : Double,
                            rate                : Double,
                            irppMax             : Double,
                            irppWithChildren    : Double,
                            irppWithoutChildren : Double)]
    
    // tranche de barême de l'ISF
    struct IsfSlice: Codable {
        let floor : Double // euro
        let rate  : Double // %
        var disc  : Double // euro
    }
    
    struct Model: Codable, Versionable {
        var version         : Version
        var isfGrid         : [IsfSlice]
        let seuil           : Double // 1_300_000 // €
        var seuil2          : Double // 1_400_000 // €
        // Un système de décote a été mis en place pour les patrimoines nets taxables compris entre 1,3 million et 1,4 million d’euros.
        // Le montant de la décote est calculé selon la formule 17 500 – (1,25 % x montant du patrimoine net taxable).
        let decote€         : Double // 17_500 // €
        let decoteCoef      : Double // 1.25 // %
        // décote sur la résidence principale
        let decoteResidence : Double // 30% // %
        // décote d'un bien en location
        let decoteLocation  : Double // 10% à 30% // %
        // décote d'un bien en location
        let decoteIndivision: Double // 30% // %
    }
    
    // properties
    
    // barême de l'exoneration de charges sociale sur les plus-values immobilières
    var model: Model
    
    // methods
    
    /// Initializer les paramètres calculés pour les tranches d'imposition à partir des seuils et des taux
    mutating func initialize() {
        for idx in model.isfGrid.startIndex ..< model.isfGrid.endIndex {
            if idx == 0 {
                model.isfGrid[idx].disc = model.isfGrid[idx].floor * (model.isfGrid[idx].rate - 0)
            } else {
                model.isfGrid[idx].disc =
                    model.isfGrid[idx-1].disc +
                    model.isfGrid[idx].floor * (model.isfGrid[idx].rate - model.isfGrid[idx-1].rate)
            }
        }
        model.seuil2 = model.decote€ / (model.decoteCoef/100.0)
    }
    
    /// Impôt sur le revenu
    /// - Parameters:
    ///   - taxableAsset: actif net imposable en €
    ///   - inhabitedAsset: valeur nette de la résidence principale en €
    /// - Returns: Impôt sur le revenu
    func isf (taxableAsset : Double) -> ISF {
        // seuil d'imposition
        guard taxableAsset > model.seuil else {
            return (amount       : 0,
                    taxable      : taxableAsset,
                    marginalRate : 0)
        }
        
        if let isfSlice = model.isfGrid.last(where: { $0.floor < taxableAsset }) {
            let marginalRate = isfSlice.rate
            var isf = taxableAsset * isfSlice.rate - isfSlice.disc
            // decote sur le montant de l'impot
            isf -= max(model.decote€ - taxableAsset * model.decoteCoef/100.0, 0.0)
            return (amount       : isf,
                    taxable      : taxableAsset,
                    marginalRate : marginalRate)
        } else {
            fatalError()
        }
    }
}

// MARK: - Impots sur les sociétés (SCI)
// impots sur les sociétés (SCI)
struct CompanyProfitTaxes: Codable {
    
    // nested types
    
    struct Model: Codable, Versionable {
        var version : Version
        let rate    : Double // 15.0 // %
    }
    
    // properties
    
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

// MARK: - Démembrement de propriété
///  - Note: [Reference](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000006310173/)

struct DemembrementModel: Codable {
    // nested types
    
    // tranche de barême de l'IRPP
    struct slice: Codable {
        let floor    : Int // ans
        let usuFruit : Double // %
        var nueProp  : Double // %
    }
    
    struct Model: Codable, Versionable {
        var version : Version
        var grid    : [slice]
    }
    
    // properties
    
    var model: Model
    
    // methods
    
    /// Calcule les valeurs démembrées d'un bien en fonction de l'age de l'usufruitier
    /// - Parameters:
    ///   - assetValue: valeur du bien en pleine propriété
    ///   - usufruitierAge: age de l'usufruitier
    /// - Returns: velurs de l'usufruit et de la nue-propriété
    func demembrement(of assetValue  : Double,
                      usufruitierAge : Int)
    -> (usufructValue : Double,
        bareValue     : Double) {
        
        if let slice = model.grid.last(where: { $0.floor < usufruitierAge }) {
            return (usufructValue : assetValue * slice.usuFruit,
                    bareValue     : assetValue * slice.nueProp)
        } else {
            fatalError()
        }
    }
}

// MARK: - Droits de succession en ligne directe et de donation au conjoint
///  - Note: [Reference](https://www.service-public.fr/particuliers/vosdroits/F14198)
struct InheritanceDonation: Codable {
    // nested types
    
    // tranche de barême
    struct slice: Codable {
        let floor : Double // €
        let rate  : Double // %
        var disc  : Double // euro
    }
    
    struct Model: Codable, Versionable {
        var version              : Version
        var gridDonationConjoint : [slice]
        var abatConjoint         : Double //  80_724€
        var gridLigneDirecte     : [slice]
        var abatLigneDirecte     : Double // 100_000€
        let fraisFunéraires      : Double //   1_500€
        let decoteResidence      : Double // 20% // %
    }
    
    // properties
    
    var model: Model
    
    // methods
    
    /// Initializer les paramètres calculés pour les tranches d'imposition à partir des seuils et des taux
    mutating func initialize() {
        for idx in model.gridLigneDirecte.startIndex ..< model.gridLigneDirecte.endIndex {
            if idx == 0 {
                model.gridLigneDirecte[idx].disc = model.gridLigneDirecte[idx].floor * (model.gridLigneDirecte[idx].rate - 0)
            } else {
                model.gridLigneDirecte[idx].disc =
                    model.gridLigneDirecte[idx-1].disc +
                    model.gridLigneDirecte[idx].floor * (model.gridLigneDirecte[idx].rate - model.gridLigneDirecte[idx-1].rate)
            }
        }
        for idx in model.gridDonationConjoint.startIndex ..< model.gridDonationConjoint.endIndex {
            if idx == 0 {
                model.gridDonationConjoint[idx].disc = model.gridDonationConjoint[idx].floor * (model.gridDonationConjoint[idx].rate - 0)
            } else {
                model.gridDonationConjoint[idx].disc =
                    model.gridDonationConjoint[idx-1].disc +
                    model.gridDonationConjoint[idx].floor * (model.gridDonationConjoint[idx].rate - model.gridDonationConjoint[idx-1].rate)
            }
        }
   }
    
    func heritageToChild(partSuccession: Double)
    -> (netAmount : Double,
        taxe      : Double) {
        // abattement avant application du barême
        let taxable = partSuccession - model.abatLigneDirecte
        
        // application du barême
        if let slice = model.gridLigneDirecte.last(where: { $0.floor < taxable }) {
            let taxe = taxable * slice.rate - slice.disc
            let net  = taxable - taxe
            return (netAmount : net,
                    taxe      : taxe)
        } else {
            fatalError()
        }
    }
    
    func donationToConjoint(donation: Double)
    -> (netAmount : Double,
        taxe      : Double) {
        // abattement avant application du barême
        let taxable = donation - model.abatConjoint
        
        // application du barême
        if let slice = model.gridLigneDirecte.last(where: { $0.floor < taxable }) {
            let taxe = taxable * slice.rate - slice.disc
            let net  = taxable - taxe
            return (netAmount : net,
                    taxe      : taxe)
        } else {
            fatalError()
        }
    }
}

// MARK: - Droits de succession sur assurance vie
///  - Note: [Reference](https://www.impots.gouv.fr/portail/international-particulier/questions/comment-sont-imposees-les-assurances-vie-en-cas-de-deces-du)
struct LifeInsuranceInheritance: Codable {
    // nested types
    
    // tranche de barême
    struct slice: Codable {
        let floor : Double // €
        let rate  : Double // %
        var disc  : Double // euro
    }
    
    struct Model: Codable, Versionable {
        var version    : Version
        var grid       : [slice]
    }
    
    // properties
    
    var model: Model
    
    // methods
    
    /// Initializer les paramètres calculés pour les tranches d'imposition à partir des seuils et des taux
    mutating func initialize() {
        for idx in model.grid.startIndex ..< model.grid.endIndex {
            if idx == 0 {
                model.grid[idx].disc = model.grid[idx].floor * (model.grid[idx].rate - 0)
            } else {
                model.grid[idx].disc =
                    model.grid[idx-1].disc +
                    model.grid[idx].floor * (model.grid[idx].rate - model.grid[idx-1].rate)
            }
        }
    }
    
    func heritageToChild(partSuccession: Double)
    -> (netAmount : Double,
        taxe      : Double) {
        // application du barême
        if let slice = model.grid.last(where: { $0.floor < partSuccession }) {
            let taxe = partSuccession * slice.rate - slice.disc
            let net  = partSuccession - taxe
            return (netAmount : net,
                    taxe      : taxe)
        } else {
            fatalError()
        }
    }
    
    func heritageToConjoint(partSuccession: Double)
    -> (netAmount : Double,
        taxe      : Double) {
        // les sommes héritées par le conjoint, par le partenaire pacsé et sous certaines conditions
        // par les frères et sœurs, sont totalement exonérées de droits de succession.
        return (netAmount : partSuccession,
                taxe      : 0.0)
    }
    
}
