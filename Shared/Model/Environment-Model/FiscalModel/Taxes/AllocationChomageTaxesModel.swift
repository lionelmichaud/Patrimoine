//
//  AllocationChomageTaxesModel.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Charges sociales sur allocation chomage
struct AllocationChomageTaxesModel: Codable {
    
    // MARK: Nested types
    
    enum ModelError: Error {
        case outOfBounds
    }
    
    struct Model: BundleCodable, Versionable {
        static var defaultFileName : String = "AllocationChomageTaxesModel.json"
        var version       : Version
        let assiette      : Double // 98.5 // % du brut
        let seuilCsgCrds  : Double // 50.0 // €, pas cotisation en deça
        let CRDS          : Double // 0.5 // %
        let CSG           : Double // 6.2 // %
        let retraiteCompl : Double // 3.0 // % du salaire journalier de référence
        let seuilRetCompl : Double // 29.26 // €
    }
    
    // MARK: Properties
    
    var model: Model
    
    // MARK: Methods
    
    /// Allocation chomage journalière nette de charges sociales
    /// - Parameters:
    ///   - brut: allocation chomage journalière brute
    ///   - SJR: Salaire Journilier de Référence
    /// - Returns: allocation chomage journalière nette de charges sociales
    func net(brut: Double, SJR: Double) throws -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        let socialTaxe = try socialTaxes(brut: brut, SJR: SJR)
        return brut - socialTaxe
    }
    
    /// Charges sociales sur l'allocation chomage journalière brute
    /// - Parameters:
    ///   - brut: allocation chomage journalière brute
    ///   - SJR: Salaire Journilier de Référence
    /// - Returns: montant des charges sociales
    /// - Note:
    ///   - [exemples de calcul](https://www.unedic.org/indemnisation/fiches-thematiques/retenues-sociales-sur-les-allocations)
    ///   - [pôle emploi](https://www.pole-emploi.fr/candidat/mes-droits-aux-aides-et-allocati/lessentiel-a-savoir-sur-lallocat/quelle-somme-vais-je-recevoir/quelles-retenues-sociales-sont-a.html)
    ///   - [service-public](https://www.service-public.fr/particuliers/vosdroits/F2971)
    func socialTaxes(brut: Double, SJR: Double) throws -> Double {
        guard brut > 0.0 else {
            return 0.0
        }
        guard SJR >= 0.0 else {
            throw ModelError.outOfBounds
        }
        var cotisation = 0.0
        var brut2: Double
        // 1) cotisation au régime complémentaire de retraite
        let cotRetraiteCompl = SJR * model.retraiteCompl / 100
        if brut - cotRetraiteCompl >= model.seuilRetCompl {
            cotisation += cotRetraiteCompl
            brut2 = brut - cotRetraiteCompl
        } else {
            brut2 = brut
        }
        // 2) CSG et CRDS
        if brut2 >= model.seuilCsgCrds {
            cotisation += model.assiette / 100.0 * brut * (model.CRDS + model.CSG) / 100
        }
        return cotisation
    }
}
