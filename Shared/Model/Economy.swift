//
//  Economy.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 12/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Model aléatoire

struct RandomModel: Codable, Versionable {
    var version      : Version
    var loiGamma     : LoiGammaNormal
    var defaultValue : Double // valeur par defaut déterministe
    var value        : Double { // valeur soit par défaut soit aléatoire
        switch simulationMode.mode {
            case .deterministic:
                return defaultValue
            case .random:
                return loiGamma.random()
        }
    }
}

// MARK: - Economy Model

struct Economy {
    
    // nested types
    
    struct Model: Codable, Versionable {
        var version      : Version
        var inflation    : RandomModel
        var longTermRate : RandomModel
    }
    
    // static properties
    
    static var model: Model  =
        Bundle.main.decode(Model.self,
                           from                 : "Economy.json",
                           dateDecodingStrategy : .iso8601,
                           keyDecodingStrategy  : .useDefaultKeys)
}
