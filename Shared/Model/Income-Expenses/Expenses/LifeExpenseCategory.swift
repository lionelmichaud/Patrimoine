//
//  LifeExpenseCategory.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Catégories de Dépenses

/// Catégories de dépenses
enum LifeExpenseCategory: Int, PickableEnum, Codable {
    case abonnements
    case vehicules
    case autres
    case cadeaux
    case educationFamille
    case logement
    case loisirs
    case sante
    case services
    case vieQuotidienne
    case voyageTransport
    
    // MARK: - Type Properties

    static var allDisplayStrings: [String] {
        allCases.map {
            $0.displayString
        }
    }
    
    // MARK: - Computed Properties
    
    var pickerString: String {
        displayString
    }
    
    var id: Int {
        return self.rawValue
    }
    
    var displayString: String {
        switch self {
            case .abonnements:
                return "Abonnements"
            case .vehicules:
                return "Véhicules"
            case .autres:
                return "Autres"
            case .cadeaux:
                return "Cadeaux"
            case .educationFamille:
                return "Education Famille"
            case .logement:
                return "Logement"
            case .loisirs:
                return "Loisirs"
            case .sante:
                return "Santé"
            case .services:
                return "Services"
            case .vieQuotidienne:
                return "Vie Quotidienne"
            case .voyageTransport:
                return "Voyage Transport"
        }
    }
    
    // MARK: - Type Methods

    /// Cherche l'Enum correspondant au nom de la catégorie
    /// - Parameter name: nom de la catégorie (displayString)
    /// - Returns: Enum
    static func category(of name: String) -> LifeExpenseCategory? {
        for category in LifeExpenseCategory.allCases where category.displayString == name {
            return category
        }
        return nil
    }
}
