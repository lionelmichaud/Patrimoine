//
//  ISF.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Impôts sur la fortune

struct IsfModel: Codable {
    
    // MARK: - Nested types
    
    enum ModelError: Error {
        case outOfBounds
        case irppSlicesIssue
    }
    
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
    
    struct Model: Codable, Versionable, RateGridable {
        var version         : Version
        var grid            : RateGrid // barême de l'ISF
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
    
    // MARK: - Properties
    
    // barême de l'exoneration de charges sociale sur les plus-values immobilières
    var model: Model
    
    // MARK: - Methods

    /// Initializer les paramètres calculés pour les tranches d'imposition à partir des seuils et des taux
    mutating func initialize() throws {
        try model.initializeGrid()
        model.seuil2 = model.decote€ / (model.decoteCoef/100.0)
    }

    /// Impôt sur le revenu
    /// - Parameters:
    ///   - taxableAsset: actif net imposable en €
    ///   - inhabitedAsset: valeur nette de la résidence principale en €
    /// - Returns: Impôt sur le revenu
    /// - Note: [reference](https://www.impots.gouv.fr/portail/particulier/calcul-de-lifi)
    func isf (taxableAsset : Double) throws -> ISF {
        // seuil d'imposition
        guard taxableAsset > model.seuil else {
            return (amount       : 0,
                    taxable      : 0,
                    marginalRate : 0)
        }
        
        if let isfSlice = model.slice(containing: taxableAsset) {
            let marginalRate = isfSlice.rate
            var isf = try! isfSlice.tax(for: taxableAsset)
            // decote sur le montant de l'impot
            isf -= max(model.decote€ - taxableAsset * model.decoteCoef/100.0, 0.0)
            return (amount       : isf,
                    taxable      : taxableAsset,
                    marginalRate : marginalRate)
        } else {
            throw ModelError.irppSlicesIssue
        }
    }
}
