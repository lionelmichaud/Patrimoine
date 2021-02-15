//
//  FinancialRevenuTaxesModel.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Charges sociales sur revenus financiers (dividendes, plus values, loyers...)
struct FinancialRevenuTaxesModel: Codable {
    
    // MARK: Nested types
    
    struct Model: BundleCodable, Versionable {
        static var defaultFileName : String = "FinancialRevenuTaxesModel.json"
        var version      : Version
        let CRDS         : Double // 0.5 // %
        let CSG          : Double // 9.2 // %
        let prelevSocial : Double // 7.5  // %
        var total        : Double {
            CRDS + CSG + prelevSocial // %
        }
    }
    
    // MARK: Properties
    
    var model: Model
    
    // MARK: Methods
    
    /// revenus financiers nets de charges sociales
    /// - Parameter brut: revenus financiers bruts
    func net(_ brut: Double) -> Double {
        return brut - socialTaxes(brut)
    }
    
    /// charges sociales sur les revenus financiers
    /// - Parameter brut: revenus financiers bruts
    func socialTaxes(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut * model.total / 100.0
    }
    
    /// revenus financiers bruts avant charges sociales
    /// - Parameter net: revenus financiers nets
    func brut(_ net: Double) -> Double {
        guard net >= 0.0 else {
            return net
        }
        return net / (1.0 - model.total / 100.0)
    }
}
