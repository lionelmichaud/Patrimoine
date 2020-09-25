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
enum LiabilitiesCategory: Int, PickableEnum, Codable {
    case debts
    case loans
    
    // properties
    
    var id: Int {
        return self.rawValue
    }
    
    var pickerString: String {
        switch self {
            case .debts:
                return "Dettes"
            case .loans:
                return "Emprunts"
        }
    }
    
    // type methods
    
    /// Cherche l'Enum correspondant au nom de la catégorie
    /// - Parameter name: nom de la catégorie (displayString)
    /// - Returns: Enum
    static func category(of name: String) -> LiabilitiesCategory? {
        for category in LiabilitiesCategory.allCases {
            if category.displayString == name {
                return category
            }
        }
        return nil
    }
}

