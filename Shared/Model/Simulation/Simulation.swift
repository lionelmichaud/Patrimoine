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

// MARK: - Type mode de simulation

enum SimulationKPIEnum: Int, PickableEnum, Codable, Hashable {
    case minimumAsset = 0
    case assetAt1stDeath
    case assetAt2ndtDeath

    // properties
    
    var id: Int {
        return self.rawValue
    }
    
    var pickerString: String {
        switch self {
            case .minimumAsset:
                return "Actif Financier minimal"
            case .assetAt1stDeath:
                return "Actif au Premier Décès"
            case .assetAt2ndtDeath:
                return "Actif au Dernier Décès"
        }
    }
}

// MARK: - Simulation: une simulation contient: les scénarios, les résultats de simulation

final class Simulation: ObservableObject {
    
    // MARK: - Properties
    
    @Published var mode           : SimulationModeEnum = .deterministic
    @Published var socialAccounts = SocialAccounts()
    @Published var kpis           = KpiArray()
    @Published var title          = "Simulation"
    @Published var isComputed     = false
    @Published var isSaved        = false
    @Published var firstYear      : Int?
    @Published var lastYear       : Int?
    
    // MARK: - Initializers
    
    init() {
        /// initialiser les KPI
        let kpiMinimumCash = KPI(name: SimulationKPIEnum.minimumAsset.displayString,
                                 objective: 200_000.0,
                                 withProbability: 0.98)
        kpis.append(kpiMinimumCash)
        
        let kpiAssetsAtFirstDeath = KPI(name: SimulationKPIEnum.assetAt1stDeath.displayString,
                                        objective: 200_000.0,
                                        withProbability: 0.98)
        kpis.append(kpiAssetsAtFirstDeath)
        
        let kpiAssetsAtLastDeath = KPI(name: SimulationKPIEnum.assetAt2ndtDeath.displayString,
                                       objective: 200_000.0,
                                       withProbability: 0.98)
        kpis.append(kpiAssetsAtLastDeath)
        
        // TODO: - à retirer
        // kpis[0].record(400000)
        // kpis[1].record(250000)
        // kpis[2].record(300000)
    }
    
    // MARK: - Methods
    
    /// Réinitialiser la simulation
    ///
    /// - Note:
    ///   - les comptes sociaux sont réinitialisés
    ///   - les années de début et fin sont réinitialisées à nil
    ///   - les KPI peuvent être réinitialisés
    ///
    /// - Parameters:
    ///   - family: la famille
    ///   - patrimoine: le patrimoine
    ///   - includingKPIs: réinitialiser les KPI (seulement sur le premier run)
    ///
    func reset(withPatrimoine patrimoine : Patrimoin,
               includingKPIs             : Bool = true) {
        // réinitialiser les comptes sociaux du patrimoine de la famille
        socialAccounts.reset(withPatrimoine : patrimoine)
        
        // remettre à zéero l'historique des KPI (Histogramme) au début d'un MontéCarlo seulement
//        if includingKPIs { kpis = kpis.resetCopy() }
        if includingKPIs {
            KpiArray.reset(theseKPIs: &kpis, withMode: mode)
        }

        firstYear  = nil
        lastYear   = nil
        isComputed = false
        isSaved    = false
    }
    
    /// Exécuter une simulation Déterministe ou Aléatoire
    /// - Parameters:
    ///   - nbOfYears: nombre d'années à construire
    ///   - nbOfRuns: nombre de run à calculer (> 1: mode aléatoire)
    ///   - family: la famille
    ///   - patrimoine: le patrimoine
    ///
    func compute(nbOfYears                 : Int,
                 nbOfRuns                  : Int,
                 withFamily family         : Family,
                 withPatrimoine patrimoine : Patrimoin) {
        let monteCarlo = nbOfRuns > 1
        
        // calculer tous les runs
        for run in 1...nbOfRuns {
            // Régénérer les propriétés aléatoires à chaque run si on est en mode Aléatoire
            if monteCarlo {
                // réinitialiser les propriétés aléatoires de la famille
                family.resetRandomProperties()
            }

            // Réinitialiser la simulation
            self.reset(withPatrimoine : patrimoine,
                       includingKPIs  : run == 1 ? true : false)
            
            // construire les comptes sociaux du patrimoine de la famille:
            // - personnes
            // - dépenses
            socialAccounts.build(nbOfYears      : nbOfYears,
                                 withFamily     : family,
                                 withPatrimoine : patrimoine,
                                 withKPIs       : &kpis,
                                 withMode       : mode)
            
            // Dernier run, créer les histogrammes et y ranger
            // les échantillons de KPIs si on est en mode Aléatoire
            if monteCarlo && run == nbOfRuns {
                KpiArray.sortHistograms(ofTheseKPIs: &kpis)
            }
        }
        //propriétés indépendantes du nombre de run
        firstYear  = Date.now.year
        lastYear   = firstYear + nbOfYears - 1
        isComputed = true
        isSaved    = false
    }
    
    /// Sauvegrder les résultats de simulation dans des fchier CSV
    ///
    /// - un fichier pour le Cash Flow
    /// - un fichier pour le Bilan
    ///
    func save() {
        socialAccounts.balanceArray.storeTableCSV(simulationTitle: title)
        socialAccounts.cashFlowArray.storeTableCSV(simulationTitle: title)
    }
}
