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
    
    static let empty: DateBoundary = DateBoundary()

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

    // MARK: - Computed Properties
    
    // date fixe ou calculée à partir d'un événement de vie d'une personne ou d'un groupe
    var year  : Int? {
        if let lifeEvent = self.event {
            // la borne temporelle est accrochée à un événement
            var persons: [Person]?
            switch group {
                case nil:
                    // rechercher la personne
                    if let theName = name, let person = LifeExpense.family?.member(withName: theName) {
                        // rechercher l'année de l'événement pour cette personne
                        return person.yearOf(event: lifeEvent)
                    } else {
                        // on ne trouve pas le nom de la personne dans la famille
                        return nil
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
                        return years.min()
                    case .latest:
                        return years.max()
                    default:
                        return nil
                }
            } else {
                return nil
            }
        } else {
            // pas d'événement, la date est fixe
            return fixedYear
        }
    }

    // MARK: - Initializers
    
    internal init() {
    }
    
    internal init(fixedYear : Int              = 0,
                  event     : LifeEvent?       = nil,
                  name      : String?          = nil,
                  group     : GroupOfPersons?  = nil,
                  order     : SoonestLatest?   = nil) {
        self.fixedYear = fixedYear
        self.event     = event
        self.name      = name
        self.group     = group
        self.order     = order
    }
    
    internal init(year: Int) {
        self.fixedYear = year
        self.event     = nil
        self.name      = nil
    }
    
    internal init(event: LifeEvent?) {
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

    // MARK: - Computed Properties
    
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
    case soonest = "Date au plus tôt"
    case latest  = "Date au plus tard"
    
    var pickerString: String {
        return self.rawValue
    }
}
