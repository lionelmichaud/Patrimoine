//
//  ModelRandomizer.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 26/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Model aléatoire

struct ModelRandomizer<R: RandomGenerator>: Codable, Versionable
where R: Codable,
      R.Number == Double {
    var version      : Version
    var distribution : R
    var defaultValue : Double = 0 // valeur par defaut déterministe
    var randomValue  : Double = 0 // dernière valeur randomisée
    
    mutating func next() {
        randomValue = Double(distribution.next())
    }
    
    /// Returns a default value or a  random value depending on the value of simulationMode.mode
    mutating func value() -> Double {
        switch simulationMode.mode {
            case .deterministic:
                return defaultValue
            case .random:
                return randomValue
        }
    }
}

