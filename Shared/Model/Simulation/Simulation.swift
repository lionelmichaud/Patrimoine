//
//  Simulation.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 09/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Type mode de simulation

enum SimulationModeEnum: Int, PickableEnum, Codable, Hashable {
    case deterministic
    case random
    
    // properties
    
    var id: Int {
        return self.rawValue
    }
    
    var pickerString: String {
        switch self {
            case .deterministic:
                return "Déterministe"
            case .random:
                return "Aléatoire"
        }
    }
}

// MARK: - Singleton mode de simulation

let simulationMode = SimulationMode.shared

struct SimulationMode {
    static let shared = SimulationMode()
    
    // properties
    
    let mode: SimulationModeEnum
    
    // initializer
    
    private init() { self.mode = .deterministic }
}

// MARK: - Simulation: une simulation contient: les scénarios, les résultats de simulation

final class Simulation: ObservableObject {
    @Published var socialAccounts = SocialAccounts()
    @Published var title          = "Simulation"
    @Published var isComputed     = false
    @Published var isSaved        = false
    @Published var firstYear      : Int?
    @Published var lastYear       : Int?
    
    /// Réinitialiser la simulation
    /// - Parameters:
    ///   - family: la famille
    ///   - patrimoine: le patrimoine
    func reset(withPatrimoine patrimoine : Patrimoin) {
        // réinitialiser les comptes sociaux du patrimoine de la famille
        socialAccounts.reset(withPatrimoine : patrimoine)
        firstYear  = nil
        lastYear   = nil
        isComputed = false
        isSaved    = false
    }
    
    /// Exécuter une simulation
    /// - Parameters:
    ///   - nbOfYears: nombre d'années à construire
    ///   - family: la famille
    ///   - patrimoine: le patrimoine
    ///   - reportProgress: closure pour indiquer l'avancement de la simulation
    func compute(nbOfYears                 : Int,
                 withFamily family         : Family,
                 withPatrimoine patrimoine : Patrimoin) {
        // Réinitialiser la simulation
        self.reset(withPatrimoine : patrimoine)
        
        // construire les comptes sociaux du patrimoine de la famille
        socialAccounts.build(nbOfYears      : nbOfYears,
                             withFamily     : family,
                             withPatrimoine : patrimoine)
        firstYear  = Date.now.year
        lastYear   = firstYear + nbOfYears - 1
        isComputed = true
        isSaved    = false
    }
    
    func save() {
        socialAccounts.balanceArray.storeTableCSV(simulationTitle: title)
        socialAccounts.cashFlowArray.storeTableCSV(simulationTitle: title)
    }
}
