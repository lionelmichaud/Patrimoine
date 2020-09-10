//
//  Scenario.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 09/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

typealias ScenarioArray = [Scenario]

struct Scenario: Identifiable, Codable, Equatable {

    // properties
    
    let id           = UUID()
    // nom du scénario = nom du répertoire dans lequel on stocke les fichiers définissant le scénario
    var name         : String
    // description du scénario
    var description  : String
    // date de création du scénario
    var dateCreated  : Date
    var dateModified : Date
    
    static func == (lhs: Scenario, rhs: Scenario) -> Bool {
        return lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.description == rhs.description &&
            lhs.dateCreated == rhs.dateCreated &&
            lhs.dateModified == rhs.dateModified
    }

    // liste des noms des fichiers JSON à charger pour initialiser une simulation
    //  - la famille : ses actifs, passifs, revenus, dépenses,
    //                 certains choix comme louer, vendre...
    //  - les paramètres macro-économiques: taux d'intérêts, inflation
    //  - les paramètres socio-économiques: pensions, taxes, IRPP
}
