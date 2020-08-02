//
//  LifeExpenseCategory.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Catégories de dépenses

/// Catégories de dépenses
enum LifeExpenseCategory: Int, PickableEnum, Codable, Hashable {
    case alimentation
    case autre
    case vetement

    // properties
    
    var id: Int {
        return self.rawValue
    }
    
    var displayString: String {
        switch self {
            case .alimentation:
                return "Alimentation"
            case .vetement:
                return "Vêtement"
            case .autre:
                return "Autre"
        }
    }
    
    var pickerString: String {
        switch self {
            case .alimentation:
                return "Alimentation"
            case .vetement:
                return "Vetement"
            case .autre:
                return "Autre"
        }
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

