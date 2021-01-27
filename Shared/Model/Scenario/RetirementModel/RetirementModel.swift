//
//  Retirement.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// https://www.service-public.fr/particuliers/vosdroits/F21552

// MARK: - SINGLETON: Modèle de pension de retraite

struct Retirement {
    
    /// Définir le mode de simulation à utiliser pour tous les calculs futurs
    /// - Parameter simulationMode: mode de simulation à utiliser
    static func setSimulationMode(to simulationMode : SimulationModeEnum) {
        // injecter l'inflation dans les Types d'investissements procurant
        // un rendement non réévalué de l'inflation chaque année
        RegimeGeneral.simulationMode = simulationMode
        RegimeAgirc.simulationMode   = simulationMode
    }
    
    // MARK: - Nested types
    
    struct Model: BundleCodable {
        static var defaultFileName : String = "RetirementModelConfig.json"
        var regimeGeneral: RegimeGeneral
        var regimeAgirc  : RegimeAgirc
        var reversion    : PensionReversion
    }
    
    // MARK: - Static properties
    
    static var model: Model = Model()
}
