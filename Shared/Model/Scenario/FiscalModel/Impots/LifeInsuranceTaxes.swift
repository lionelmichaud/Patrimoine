//
//  LifeInsuranceTaxes.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Impôt sur les plus-values d'assurance vie-Assurance vies
struct LifeInsuranceTaxes: Codable {
    
    // MARK: Nested types
    
    struct Model: Codable, Versionable {
        var version        : Version
        let rebatePerPerson: Double // 4800.0 // euros
    }
    
    // MARK: Properties
    
    var model: Model
}
