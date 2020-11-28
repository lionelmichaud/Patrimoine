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
enum TaxeCategory: Int, PickableEnum, Codable, Hashable {
    case irpp
    case isf
    case succession
    case socialTaxes
    case localTaxes

    // properties
    
    var id: Int {
        return self.rawValue
    }
    
    var pickerString: String {
        switch self {
            case .irpp:
                return "IRPP"
            case .isf:
                return "ISF"
            case .succession:
                return "Droits Succession"
            case .socialTaxes:
                return "Prélev Sociaux"
            case .localTaxes:
                return "Taxes Locales"
        }
    }
    
    // type methods
    
    /// Cherche l'Enum correspondant au nom de la catégorie
    /// - Parameter name: nom de la catégorie (displayString)
    /// - Returns: Enum
    static func category(of name: String) -> TaxeCategory? {
        for category in TaxeCategory.allCases {
            if category.displayString == name {
                return category
            }
        }
        return nil
    }
}
