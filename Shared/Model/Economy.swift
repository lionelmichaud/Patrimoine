//
//  Economy.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 12/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Model aléatoire

struct RandomModel<T: Codable>: Codable, Versionable  where T: Randomizer {
    var version      : Version
    var distribution : T
    var defaultValue : Double // valeur par defaut déterministe
    
    /// Returns a default value or a  random value dependin on the value of simulationMode.mode
    mutating func value() -> Double {
        switch simulationMode.mode {
            case .deterministic:
                return defaultValue
            case .random:
                return distribution.random()
        }
    }
}

// MARK: - Economy Model

struct Economy {
    
    // nested types
    
    struct Model: Codable, Versionable {
        var version      : Version
        var inflation    : RandomModel<LoiGammaNormal>
        var longTermRate : RandomModel<LoiDiscrete>
    }
    
    // static properties
    
    static var model: Model  =
        Bundle.main.decode(Model.self,
                           from                 : "Economy.json",
                           dateDecodingStrategy : .iso8601,
                           keyDecodingStrategy  : .useDefaultKeys)
}
