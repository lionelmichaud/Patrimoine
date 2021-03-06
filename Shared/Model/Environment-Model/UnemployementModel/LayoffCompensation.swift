//
//  LayoffCompensation.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 16/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.LayoffCompensation")

// MARK: - Modèle d'Indeminité de licenciement
// https://www.juritravail.com/Actualite/respecter-salaire-minimum/Id/221441
// https://www.service-public.fr/particuliers/vosdroits/F408
// https://www.service-public.fr/particuliers/vosdroits/F987
struct LayoffCompensation: Codable {
    
    // MARK: - Nested types

    struct SliceBase: Codable {
        var nbYears : Int // nb d'année d'ancienneté dans l'entreprise
        var coef    : Double // nb de mois de salaire par année d'ancienneté
    }
    
    struct SliceCorrectionAnciennete: Codable {
        var anciennete : Int // nb d'année d'ancienneté dans l'entreprise
        var majoration : Double // %
        var min        : Int // nb de mois de salaire minimum
        var max        : Int // nb de mois de salaire maximum
    }
    
    struct SliceCorrection: Codable {
        var age                      : Int
        var correctionAncienneteGrid : [SliceCorrectionAnciennete]
    }
    
    struct IrppDiscount: Codable {
        var multipleOfConventionalCompensation : Double = 1.0 // multiple de l'indemnité légale ou conventionnelle
        var multipleOfLastSalaryBrut           : Double = 2.0 // multiple du derneir salaire annuel brut
        var multipleOfActualCompensation       : Double = 0.5// multiple du montant de l'indemnité perçue
        var maxDiscount                        : Double = 246_816 // €
    }
    
    struct Model: BundleCodable, Versionable {
        static var defaultFileName : String = "LayoffCompensationModel.json"
        
        var version           : Version
        let legalGrid         : [SliceBase]
        let metallurgieGrid   : [SliceBase]
        let correctionAgeGrid : [SliceCorrection]
        let irppDiscount      : IrppDiscount
    }
    
    // MARK: - Static Properties

    private static var fiscalModel: Fiscal.Model = Fiscal.model

    // MARK: - Static Methods

    static func setFiscalModel(_ model: Fiscal.Model) {
        fiscalModel = model
    }

    // MARK: - Properties

    var model: Model
    
    // MARK: - Methods

    /// Calcul du nombre de mois de salaire de l'indemnité de licenciement pour une grille donnée
    /// - Parameters:
    ///   - nbYearsSeniority: nombre d'année d'ancienneté au moment du licenciement
    ///   - grid: grille à utiliser
    /// - Returns: nombre de mois de salaire de l'indemnité de licenciement selon la grille
    /// - Note: [travail-emploi.gouv.fr](https://travail-emploi.gouv.fr/droit-du-travail/la-rupture-du-contrat-de-travail/article/l-indemnite-legale-de-licenciement)
    func layoffCompensationInMonth(nbYearsSeniority years : Int,
                                   grid                   : [SliceBase]) -> Double {
        var decompte = years
        let nbMonth: Double = grid.reduce(0.0) { m, slice in
            guard decompte > 0 else { return m }
            // nombre de mois dans la tranche
            let nbMonth = min(decompte, slice.nbYears)
            decompte -= nbMonth
            // application du facteur
            let increment = nbMonth.double() * slice.coef
            // ajout de l'incrément
            return m + increment
        }
        return nbMonth
    }
    
    /// Calcul du nombre de mois de salaire de l'indemnité de licenciement selon le Code du Travail (Légal)
    /// - Parameter nbYearsSeniority: nombre d'année d'ancienneté au moment du licenciement
    /// - Returns: nombre de mois de salaire de l'indemnité de licenciement selon le Code du Travail (Légal)
    /// - Note: [travail-emploi.gouv.fr](https://travail-emploi.gouv.fr/droit-du-travail/la-rupture-du-contrat-de-travail/article/l-indemnite-legale-de-licenciement)
    func layoffCompensationLegalInMonth(nbYearsSeniority years : Int) -> Double {
        layoffCompensationInMonth(nbYearsSeniority: years,
                                  grid: model.legalGrid)
    }
    
    /// Calcul du nombre de mois de salaire de l'indemnité de licenciement selon la Convention de la Métalurgie
    /// - Parameters:
    ///   - age: age au moment du licenciement
    ///   - nbYearsSeniority: nombre d'année d'ancienneté au moment du licenciement
    /// - Returns: nombre de mois de salaire de l'indemnité de licenciement selon la Convention de la Métalurgie
    /// - Note:
    ///   - [juritravail.com](https://www.juritravail.com/Actualite/respecter-salaire-minimum/Id/221441)
    ///   - [editions-tissot.fr](https://www.editions-tissot.fr/actualite/droit-du-travail/indemnite-de-licenciement-des-ingenieurs-et-cadres-de-la-metallurgie-quel-est-le-plafond-d-indemnite-pour-les-salaries-successivement-employes-a-temps-complet-et-a-temps-partiel)
    func layoffCompensationConventionInMonth(age                    : Int,
                                             nbYearsSeniority years : Int) -> Double? {
        let allocLegale      = layoffCompensationInMonth(nbYearsSeniority: years,
                                                         grid: model.legalGrid)
        var allocMetallurgie = layoffCompensationInMonth(nbYearsSeniority: years,
                                                         grid: model.metallurgieGrid)
        // majoration fonction de l'age
        guard let correctionAncienneteGrid = model.correctionAgeGrid.last(\.correctionAncienneteGrid, where: \.age, <=, age) else {
            customLog.log(level: .error, "layoffCompensationConventionInMonth:correctionAncienneteGrid = nil")
            return nil
        }
        // majoration fonction de l'ancienneté
        guard let slice2 = correctionAncienneteGrid.last(where: \.anciennete, <=, years) else {
            customLog.log(level: .error, "layoffCompensationConventionInMonth:slice2 = nil")
            return nil
        }
        // application de la majoration
        allocMetallurgie *= (1 + slice2.majoration / 100)
        
        // seuillage
        allocMetallurgie = allocMetallurgie.clamp(low  : slice2.min.double(),
                                                  high : slice2.max.double())
        
        return max(allocMetallurgie, allocLegale)
    }
    
    /// Calcul de l'indemnité de licenciement selon le Code du travail (Légale)
    /// - Parameters:
    ///   - yearlyWorkIncomeBrut: dernier salaire annuel brut
    ///   - nbYearsSeniority: nombre d'année d'ancienneté au moment du licenciement
    /// - Returns: montant de l'indemnité de licenciement selon le Code du travail (Légale)
    func layoffCompensationLegal(yearlyWorkIncomeBrut   : Double,
                                 nbYearsSeniority years : Int) -> Double {
        let nbMonth = layoffCompensationLegalInMonth(nbYearsSeniority : years)
        // indemnité brute légale basée sur le dernier salaire brut
        return nbMonth * yearlyWorkIncomeBrut / 12.0
    }
    
    /// Calcul de l'indemnité de licenciement selon la Convention de la Métalurgie ou Légale ou Supra-convention
    /// - Parameters:
    ///   - actualCompensationBrut: indemnité licenciement brute si > convention collective
    ///   - causeOfRetirement: cause de la cessation d'activité
    ///   - yearlyWorkIncomeBrut: dernier salaire annuel brut
    ///   - age: age au moment du licenciement
    ///   - nbYearsSeniority: nombre d'année d'ancienneté au moment du licenciement
    /// - Returns: montant de l'indemnité de licenciement selon la Convention de la Métalurgie ou Supra-convention
    func layoffCompensation(actualCompensationBrut : Double? = nil,
                            causeOfRetirement      : Unemployment.Cause,
                            yearlyWorkIncomeBrut   : Double,
                            age                    : Int,
                            nbYearsSeniority years : Int)
    -> (nbMonth : Double,
        brut    : Double,
        net     : Double,
        taxable : Double) {
        
        var taxable      : Double
        var irppDiscount : Double
        // Calcul du nombre de mois d'indemnité de licenciement
        guard let nbMonth = layoffCompensationConventionInMonth(age              : age,
                                                                nbYearsSeniority : years) else {
            customLog.log(level: .error,
                          "layoffCompensation:layoffCompensationConventionInMonth = nil")
            fatalError("layoffCompensation:layoffCompensationConventionInMonth = nil")
        }
        // indemnité brute basée sur le dernier salaire brut
        let brutConventionnel = nbMonth * yearlyWorkIncomeBrut / 12.0
        // indemnité réelle perçue (peut être plus élevée que l'indemnité conventionnelle)
        let brutReel = actualCompensationBrut ?? brutConventionnel
        
        // fraction de l'indemnité taxable à l'IRPP
        switch causeOfRetirement {
            case .planSauvegardeEmploi, .ruptureConventionnelleCollective :
                // exonération totale de l'IRPP
                irppDiscount = brutReel
                
            case .licenciement, .ruptureConventionnelleIndividuelle :
                // Exonération partielle de l'IRPP :
                // 1 x le montant de l'indemnité légale ou conventionnelle
                let discount1 = model.irppDiscount.multipleOfConventionalCompensation * brutConventionnel
                // 2 x le montant de la rémunération brute annuelle que vous avez perçue l'année précédant votre licenciement
                var discount2 = model.irppDiscount.multipleOfLastSalaryBrut * yearlyWorkIncomeBrut
                discount2 = min(discount2, model.irppDiscount.maxDiscount)
                // 0,5 x le montant de l'indemnité perçue
                var discount3 = model.irppDiscount.multipleOfActualCompensation * brutReel
                discount3 = min(discount3, model.irppDiscount.maxDiscount)
                // maximum des 3
                irppDiscount = max(discount1, discount2, discount3)
                irppDiscount = min(irppDiscount, brutReel)
                
            case .demission :
                // pas d'exonération de l'IRPP
                irppDiscount = 0
        }
        taxable = brutReel - irppDiscount
        
        // indemnité nette de charges sociales
        let net = LayoffCompensation.fiscalModel.layOffTaxes.net(
            compensationConventional : brutConventionnel,
            compensationBrut         : brutReel,
            compensationTaxable      : &taxable,
            irppDiscount             : irppDiscount)
        return (nbMonth : nbMonth,
                brut    : brutReel,
                net     : net,
                taxable : taxable)
    }
}
