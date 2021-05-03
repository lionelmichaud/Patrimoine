//
//  LayOffTaxes.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 12/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Charges sociales sur l'indemnité de licenciement
// https://www.service-public.fr/particuliers/vosdroits/F987
struct LayOffTaxes: Codable {
    
    // MARK: - Nested types

    struct SocialTaxes: Codable {
        var PASS          : Double? // injecté à l'initialization par le père FiscalModel
        let maxRebateCoef : Double // 2 x PASS
        var maxRebate     : Double {
            maxRebateCoef * PASS!
        }
        let rate          : Double // 13 % (le même que sur le salaire)
    }
    struct CsgCrds: Codable {
        let rateDeductible    : Double // 6.5 %
        let rateNonDeductible : Double // 2.9 %
        var total             : Double {
            rateDeductible + rateNonDeductible
        }
    }
    struct Model: BundleCodable, Versionable {
        static var defaultFileName : String = "LayOffTaxesModel.json"
        
        var version     : Version
        var socialTaxes : SocialTaxes
        let csgCrds     : CsgCrds
    }
    
    // MARK: - Properties

    var model: Model
    
    // MARK: - Methods
    
    /// Initializer les paramètres calculés pour les tranches d'imposition à partir des seuils et des taux
    mutating func initialize(PASS: Double) {
        model.socialTaxes.PASS = PASS
    }
    
    /// Calcul des charges sociales dûes sur une indemnité de licenciement
    /// - Parameters:
    ///   - compensationConventional: indemnité conventionnelle
    ///   - compensationBrut: indemnité réelle brute
    ///   - compensationTaxable: indemnité réelle taxable
    ///   - irppDiscount: la part de l'indemnité exonérée d’impôt sur le revenu
    /// - Returns: indemnité de licenciement nette de charges et cotisations siciales
    /// - Note:
    ///  - [imposition](https://www.service-public.fr/particuliers/vosdroits/F408)
    ///  - [charges sociales](https://www.cadremploi.fr/editorial/conseils/droit-du-travail/detail/article/les-charges-sociales-sur-les-indemnites-de-licenciement.html)
    func net(compensationConventional : Double,
             compensationBrut         : Double,
             compensationTaxable      : inout Double,
             irppDiscount             : Double) -> Double {
        var net = compensationBrut
        
        // 1) cotisations sociales:
        // Une indemnité de licenciement supra-légale (c’est-à-dire supérieure au minimum légal ou conventionnel.
        // Elle fait partie de ce que vous pouvez négocier de plus lors d’un licenciement) est exonérée de cotisations sociales
        // à hauteur du plus faible montant entre :
        //   - le montant exonéré d’impôt sur le revenu ;
        //   - 2 fois le montant annuel du plafond de la Sécurité sociale soit 82 272 € en 2021.
        //  1.1) base de calcul des cotisations sociales:
        let discountSocialtaxes = min(model.socialTaxes.maxRebate, irppDiscount)
        let baseSocialtaxes = zeroOrPositive(compensationBrut - discountSocialtaxes)
        //  1.2) montant des charges sociales à payer
        let socialTaxes = baseSocialtaxes * model.socialTaxes.rate / 100
        //  1.3) net de charges sociales
        net -= socialTaxes
        
        // 2) contributions sociales (CSG + CRDS)
        // L'indemnité de licenciement est exonérée partiellement des contributions sociales
        // (l’autre composante des charges sociales) suivantes : CSG (Contribution Sociale Généralisée)
        // et CRDS (Contribution au Remboursement de la Dette Sociale).
        // Elle est exonérée à hauteur de la plus petite des 2 limites suivantes :
        //   - le montant de l'indemnité légale ou conventionnelle de licenciement dû au salarié licencié ;
        //   - le montant de l'indemnité exonéré de cotisations sociales. En effet, la fraction assujettie à CSG CRDS ne peut pas être inférieure à celle assujettie à cotisations sociales.
        //  2.1) Montant de l'indemnité légale ou conventionnelle de licenciement dû au salarié licencié
        let discount1 = compensationConventional
        //  2.2) Montant de l'indemnité exonéré de cotisations sociales
        let discount2 = discountSocialtaxes
        // 2.3) plus petite des 2 limites
        let discountCsgCrds = min(discount1, discount2)
        // base de calcul de la CSG et du CRDS
        let baseCsgCrds = zeroOrPositive(compensationBrut - discountCsgCrds)
        // montant de la CSG et du CRDS à payer
        let csgCrds = baseCsgCrds * model.csgCrds.total / 100
        
        net -= csgCrds
        
        // retirer du montant de l'indemnité taxable à l'IRPP la part déductibe de la CSG
        let csgDeductible = zeroOrPositive(baseCsgCrds * model.csgCrds.rateDeductible / 100)
        compensationTaxable = zeroOrPositive(compensationTaxable - csgDeductible)
        
        return net
    }
}
