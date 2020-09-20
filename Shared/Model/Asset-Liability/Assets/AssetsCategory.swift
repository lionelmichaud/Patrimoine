//
//  AssetsCategory.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 19/09/2020.
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
    
    var displayString: String {
        switch self {
            case .periodicInvests:
                return "periodicInvests"
            case .freeInvests:
                return "freeInvests"
            case .realEstates:
                return "realEstates"
            case .scpis:
                return "scpis"
            case .sci:
                return "sci"
        }
    }
    
    var pickerString: String {
        displayString
        
    }
    
    // type methods
    
    /// Cherche l'Enum correspondant au nom de la catégorie
    /// - Parameter name: nom de la catégorie (displayString)
    /// - Returns: Enum
    static func category(of name: String) -> LifeExpenseCategory? {
        for category in LifeExpenseCategory.allCases {
            if category.displayString == name {
                return category
            }
        }
        return nil
    }
}

