//
//  LifeEvent.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Evénement de vie
enum LifeEvent: String, PickableEnum, Codable, Hashable {
    case debutEtude         = "Début étude"
    case independance       = "Indépendance financière"
    case cessationActivite  = "Fin d'activité proffesionelle"
    case liquidationPension = "Liquidation de pension"
    case dependence         = "Dépendance"
    case deces              = "Décès"

    var pickerString: String {
        return self.rawValue
    }
    
    var isAdultEvent: Bool {
        switch self {
            case .cessationActivite,
                 .liquidationPension,
                 .dependence:
                return true
            
            default:
                return false
        }
    }

    var isChildEvent: Bool {
        switch self {
            case .debutEtude,
                 .independance:
                return true
            
            default:
                return false
        }
    }
}

