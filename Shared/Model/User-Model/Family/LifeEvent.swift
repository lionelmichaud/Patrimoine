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
}

extension DateBoundary: CustomStringConvertible {
    var description: String {
        if let lifeEvent = self.event {
            return lifeEvent.description
        } else {
            return String(fixedYear)
        }
    }
}

// MARK: - Evénement de vie

enum LifeEvent: String, PickableEnum, Codable, CustomStringConvertible {
    case debutEtude         = "Début des études supérieurs"
    case independance       = "Indépendance financière"
    case cessationActivite  = "Fin d'activité professionnelle"
    case liquidationPension = "Liquidation de pension"
    case dependence         = "Dépendance"
    case deces              = "Décès"

    // MARK: - Computed Properties
    
    var pickerString: String {
        return self.rawValue
    }
    
    var description: String {
        pickerString
    }
    
    // True si l'événement est spécifique des Adultes
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

    // True si l'événement est spécifique des Enfant
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

enum GroupOfPersons: String, PickableEnum, Codable, CustomStringConvertible {
    case allAdults    = "Tous les Adultes"
    case allChildrens = "Tous les Enfants"
    case allPersons   = "Toutes les Personnes"
    
    // MARK: - Computed Properties
    
    var pickerString: String {
        return self.rawValue
    }

    var description: String {
        pickerString
    }
}

// MARK: - Date au plus tôt ou au plus tard

enum SoonestLatest: String, PickableEnum, Codable, CustomStringConvertible {
    case soonest = "Date au plus tôt"
    case latest  = "Date au plus tard"
    
    // MARK: - Computed Properties
    
    var pickerString: String {
        return self.rawValue
    }

    var description: String {
        pickerString
    }
}
