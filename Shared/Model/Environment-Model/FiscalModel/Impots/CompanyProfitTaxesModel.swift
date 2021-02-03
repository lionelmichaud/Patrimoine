//
//  CompanyProfitTaxesModel.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Impots sur les sociétés (SCI)
struct CompanyProfitTaxesModel: Codable {
    
    // MARK: Nested types
    
    struct Model: BundleCodable, Versionable {
        static var defaultFileName : String = "CompanyProfitTaxesModel.json"
        var version : Version
        let rate    : Double // 15.0 // %
    }
    
    // MARK: Properties
    
    var model: Model
    
    // MARK: Methods
    
    /// bénéfice net
    /// - Parameter brut: bénéfice brut
    func net(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut - IS(brut)
    }
    
    /// impôts sur les bénéfices
    /// - Parameter brut: bénéfice brut
    func IS(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut * model.rate / 100.0
    }
}
