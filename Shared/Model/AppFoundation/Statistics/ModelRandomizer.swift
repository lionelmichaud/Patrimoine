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

    // MARK: - Properties

    var version              : Version
    var name                 : String
    var rndGenerator         : R
    private var defaultValue : Double = 0 // valeur par defaut déterministe
    private var randomValue  : Double = 0 // dernière valeur randomisée
    var randomHistory        : [Double]? // historique des tirages aléatoires
    
    // MARK: - Methods
    
    /// Remettre à zéro les historiques des tirages aléatoires
    mutating func resetRandomHistory() {
        randomHistory = []
    }
    
    /// Générer le nombre aléatoire suivant
    mutating func next() -> Double {
        randomValue = Double(rndGenerator.next())
        if randomHistory == nil {
            randomHistory = []
        }
        randomHistory!.append(randomValue)
        return randomValue
    }
    
    /// Définir une valeur pour la variable aléaoitre avant un rejeu
    /// - Parameter value: nouvelle valeure à rejouer
    mutating func setRandomValue(to value: Double) {
        randomValue = value
    }
    
    /// Returns a default value or a  random value depending on the value of simulationMode.mode
    func value(withMode mode : SimulationModeEnum) -> Double {
        switch mode {
            case .deterministic:
                return defaultValue
                
            case .random:
                return randomValue
        }
    }
}
