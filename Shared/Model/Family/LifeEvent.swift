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
    var fixedYear : Int = 0
    // non nil si la date est liée à un événement de vie d'une personne
    var event : LifeEvent?
    // personne associée à l'évenement
    var name  : String?
    // groupe de personnes associées à l'événement
    var group : GroupOfPersons?
    // date au plus tôt ou au plus tard du groupe
    var order : SoonestLatest?
    // date fixe ou calculée à partir d'un éventuel événement de vie d'une personne
    var year  : Int {
        if let lifeEvent = self.event {
            // la borne temporelle est accrochée à un événement
            var persons: [Person]?
            switch group {
                case nil:
                    // rechercher la personne
                    if let theName = name, let person = LifeExpense.family?.member(withName: theName) {
                        // rechercher l'année de l'événement pour cette personne
                        return person.yearOf(event: lifeEvent) ?? -1
                    } else {
                        // on ne trouve pas le nom de la personne dans la famille
                        return -1
                    }
                    
                case .allAdults:
                    persons = LifeExpense.family?.members.filter {$0 is Adult}
                    
                case .allChildrens:
                    persons = LifeExpense.family?.members.filter {$0 is Child}
                    
                case .allPersons:
                    persons = LifeExpense.family?.members
            }
            if let years = persons?.map({ $0.yearOf(event: lifeEvent)! }) {
                switch order {
                    case .soonest:
                        return years.min()!
                    case .latest:
                        return years.max()!
                    default:
                        return -1
                }
            } else {
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
        self.name      = nil
    }
    
    init(event: LifeEvent?) {
        self.event = event
        self.name  = nil
    }
}

// MARK: - Evénement de vie

enum LifeEvent: String, PickableEnum, Codable {
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

// MARK: - Groupes de personnes

enum GroupOfPersons: String, PickableEnum, Codable {
    case allAdults    = "Tous les Adultes"
    case allChildrens = "Tous les Enfants"
    case allPersons   = "Toutes les Personnes"
    
    var pickerString: String {
        return self.rawValue
    }
}

// MARK: - Date au plus tôt ou au plus tard

enum SoonestLatest: String, PickableEnum, Codable {
    case soonest = "date au plus tôt"
    case latest  = "date au plus tard"
    
    var pickerString: String {
        return self.rawValue
    }
}
