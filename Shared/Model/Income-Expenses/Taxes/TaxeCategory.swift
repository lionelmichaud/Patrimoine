//
//  TaxesCategory.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/08/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Catégories de taxe

/// Catégories de dépenses
enum TaxeCategory: String, PickableEnum, Codable, Hashable {
    case irpp         = "IRPP"
    case isf          = "ISF"
    case succession   = "Droits Succes. Légale"
    case liSuccession = "Droits Succes. Ass. Vie"
    case socialTaxes  = "Prélev Sociaux"
    case localTaxes   = "Taxes Locales"

    // properties
    
    var pickerString: String {
        return self.rawValue
    }
}
