//
//  LifeEvent.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Limite temporelle fixe ou liée à un événement de vie

/// Limite temporelle d'une dépense: début ou fin.
/// Date fixe ou calculée à partir d'un éventuel événement de vie d'une personne
struct DateBoundary: Hashable, Codable {
    
    // MARK: - Properties
    
    // date fixe ou calculée à partir d'un éventuel événement de vie d'une personne
    var fixedYear: Int = 0
    // non nil si la date est liée à un événement de vie d'une personne
    var event    : LifeEvent?
    // personne associée à l'évenement
    var name     : String = ""
    // date fixe ou calculée à partir d'un éventuel événement de vie d'une personne
    var year: Int {
        if let lifeEvent = self.event {
            // rechercher la personne
            if let person = LifeExpense.family?.member(withName: name) {
                // rechercher l'année de l'événement pour cette personne
                return person.yearOf(event: lifeEvent) ?? -1
            } else {
                // on ne trouve pas le nom de la personne dans la famille
                return -1
            }
        } else {
            // pas d'événement, la date est fixe
            return fixedYear
        }
    }

    // MARK: - Initializers
    
    init() {
    }
    
    init(year: Int) {
        self.fixedYear = year
        self.event     = nil
        self.name      = ""
    }
    
    init(event: LifeEvent?) {
        self.event = event
        self.name  = ""
    }
    
    init(name: String) {
        self.name  = name
        self.event = nil
    }
}

// MARK: - Evénement de vie

enum LifeEvent: String, PickableEnum, Codable, Hashable {
    case debutEtude         = "Début étude"
    case independance       = "Indépendance financière"
    case cessationActivite  = "Fin d'activité profesionelle"
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

