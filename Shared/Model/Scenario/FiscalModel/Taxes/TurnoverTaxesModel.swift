//
//  TurnoverTaxesModel.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Charges sociales sur chiffre d'affaire
struct TurnoverTaxesModel: Codable {
    
    // MARK: Nested types
    
    struct Model: BundleCodable, Versionable {
        static var defaultFileName : String = "TurnoverTaxesModelTests.json"
        var version: Version
        let URSSAF : Double // 24 // %
        var total  : Double {
            URSSAF // %
        }
    }
    
    // MARK: Properties
    
    var model: Model
    
    // MARK: Methods
    
    /// chiffre d'affaire net de charges sociales
    /// - Parameter brut: chiffre d'affaire brut
    func net(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut - socialTaxes(brut)
    }
    
    /// charges sociales sur le chiffre d'affaire brut
    /// - Parameter brut: chiffre d'affaire brut
    func socialTaxes(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut * model.URSSAF / 100.0
    }
}
