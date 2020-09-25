//
//  LiabilitiesCategory.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 25/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Catégories de Actifs

/// Catégories de dépenses
enum AssetsCategory: Int, PickableEnum, Codable {
    case periodicInvests
    case freeInvests
    case realEstates
    case scpis
    case sci
    
    // properties
    
    var id: Int {
        return self.rawValue
    }
    
    var pickerString: String {
        switch self {
            case .periodicInvests:
                return "Invest. périodique"
            case .freeInvests:
                return "Invest. libre"
            case .realEstates:
                return "Immobilier"
            case .scpis:
                return "SCPI"
            case .sci:
                return "SCI"
        }
    }
    
    // type methods
    
    /// Cherche l'Enum correspondant au nom de la catégorie
    /// - Parameter name: nom de la catégorie (displayString)
    /// - Returns: Enum
    static func category(of name: String) -> AssetsCategory? {
        for category in AssetsCategory.allCases {
            if category.displayString == name {
                return category
            }
        }
        return nil
    }
}

