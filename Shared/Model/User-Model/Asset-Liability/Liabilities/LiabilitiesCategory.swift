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
enum LiabilitiesCategory: String, PickableEnum, Codable {
    case debts = "Dettes"
    case loans = "Emprunts"
    
    // properties
    
    var pickerString: String {
        return self.rawValue
    }
}
