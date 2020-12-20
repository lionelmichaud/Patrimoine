//
//  Succession.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 18/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Méthode d'évaluation d'un Patrmoine (régles fiscales à appliquer)
enum EvaluationMethod: String, PickableEnum {
    case ifi         = "IFI"
    case isf         = "ISF"
    case inheritance = "Succession"
    case patrimoine  = "Patrimoniale"
    
    var pickerString: String {
        return self.rawValue
    }
}

// MARK: - Succession d'une personne

struct Succession: Identifiable {
    let id           = UUID()
    // année de la succession
    let yearOfDeath  : Int
    // personne dont on fait la succession
    let decedent     : Person
    // masses successorale
    let taxableValue : Double
    // liste des héritages par héritier
    let inheritances : [Inheritance]
    
    // dictionnaire des héritages net reçu par les enfants dans une succession
    var childrenSuccessorsInheritedNetValue: [String: Double] {
        inheritances.reduce(into: [:]) { counts, inheritance in
            counts[inheritance.person.displayName, default: 0] += inheritance.net
        }
    }
    
    // somme des héritages reçus par les hétritiers dans une succession
    var net: Double {
        inheritances.sum(for: \.net)
    }
    
    // somme des taxes payées par les hétritiers dans une succession
    var tax: Double {
        inheritances.sum(for: \.tax)
    }
}
extension Array where Element == Succession {
    // dictionnaire des héritages net reçu par les enfants sur un ensemble de successions
    var childrenSuccessorsInheritedNetValue: [String: Double] {
        var globalDico: [String: Double] = [:]
        self.forEach { succession in
            let dico = succession.childrenSuccessorsInheritedNetValue
            for name in dico.keys {
                if globalDico[name] != nil {
                    globalDico[name]! += dico[name]!
                } else {
                    globalDico[name] = dico[name]
                }
            }
        }
        return globalDico
    }
}

// MARK: - Héritage d'une personne
struct Inheritance {
    // héritier
    var person  : Person
    // fraction de la masse successorale reçue en héritage
    var percent : Double // [0, 1]
    var brut    : Double
    var net     : Double
    var tax     : Double
}
