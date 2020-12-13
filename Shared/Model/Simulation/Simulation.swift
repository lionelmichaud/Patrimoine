//
//  Simulation.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 09/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Enumération des modes de simulation

enum SimulationModeEnum: String, PickableEnum, Codable, Hashable {
    case deterministic = "Déterministe"
    case random        = "Aléatoire"
    
    // properties
    
    var pickerString: String {
        return self.rawValue
    }
}

// MARK: - Enumération des KPI

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
                return "Actif Financier Minimum"
            case .assetAt1stDeath:
                return "Actif au Premier Décès"
            case .assetAt2ndtDeath:
                return "Actif au Dernier Décès"
        }
    }
}

// MARK: - Simulation: une simulation contient: les scénarios, les résultats de simulation

final class Simulation: ObservableObject {
    
    //#if DEBUG
    /// URL du fichier de stockage du résultat de calcul au format CSV
    static let monteCarloFileUrl = Bundle.main.url(forResource: "Monté-Carlo Kpi.csv", withExtension: nil)
    //#endif

    // MARK: - Properties
    
    @Published var mode           : SimulationModeEnum = .deterministic
    @Published var currentRunNb   : Int = 0
    @Published var socialAccounts = SocialAccounts()
    @Published var kpis           = KpiArray()
    @Published var resultTable    = SimulationResultTable()
    @Published var title          = "Simulation"
    @Published var isComputed     = false
//    @Published var isComputing    = false
    @Published var isSaved        = false
    @Published var firstYear      : Int?
    @Published var lastYear       : Int?
    
    // MARK: - Initializers
    
    init() {
        /// initialiser les KPI
        let kpiMinimumCash = KPI(name            : SimulationKPIEnum.minimumAsset.displayString,
                                 objective       : 200_000.0,
                                 withProbability : 0.98)
        kpis.append(kpiMinimumCash)
        
        let kpiAssetsAtFirstDeath = KPI(name            : SimulationKPIEnum.assetAt1stDeath.displayString,
                                        objective       : 200_000.0,
                                        withProbability : 0.98)
        kpis.append(kpiAssetsAtFirstDeath)
        
        let kpiAssetsAtLastDeath = KPI(name            : SimulationKPIEnum.assetAt2ndtDeath.displayString,
                                       objective       : 200_000.0,
                                       withProbability : 0.98)
        kpis.append(kpiAssetsAtLastDeath)
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
        
        // remettre à zéro l'historique des KPI (Histogramme)
        //  - au début d'un MontéCarlo seulement
        //  - mais pas à chaque Run
        if includingKPIs {
            KpiArray.reset(theseKPIs: &kpis, withMode: mode)
        }
        
        firstYear    = nil
        lastYear     = nil
        isComputed   = false
        isSaved      = false
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
//        isComputing    = true
        let monteCarlo = nbOfRuns > 1
        var dicoOfEconomyRandomVariables      = Economy.DictionaryOfRandomVariable()
        var dicoOfSocioEconomyRandomVariables = SocioEconomy.DictionaryOfRandomVariable()

        // remettre à zéro les historiques des tirages aléatoires
        if monteCarlo {
            HumanLife.model.resetRandomHistory()
            Economy.model.resetRandomHistory()
            SocioEconomy.model.resetRandomHistory()
            resultTable = SimulationResultTable()
        }
        
        // calculer tous les runs
        for run in 1...nbOfRuns {
            currentRunNb = run
            
            // Régénérer les propriétés aléatoires à chaque run si on est en mode Aléatoire
            if monteCarlo {
                // réinitialiser les propriétés aléatoires de la famille
                family.nextRandomProperties()
                // réinitialiser les propriétés aléatoires du modèle macro économique
                dicoOfEconomyRandomVariables      = Economy.model.next()
                // réinitialiser les propriétés aléatoires du modèle socio économique
                dicoOfSocioEconomyRandomVariables = SocioEconomy.model.next()
            }
            
            // Réinitialiser la simulation
            reset(withPatrimoine : patrimoine,
                  includingKPIs  : run == 1 ? true : false)
            
            // construire les comptes sociaux du patrimoine de la famille:
            // - personnes
            // - dépenses
            let dicoOfKpiResults = socialAccounts.build(nbOfYears      : nbOfYears,
                                                        withFamily     : family,
                                                        withPatrimoine : patrimoine,
                                                        withKPIs       : &kpis,
                                                        withMode       : mode)
            if monteCarlo {
                // récupérer les propriétés aléatoires des adultes de la famille
                var dicoOfAdultsRandomProperties = DictionaryOfAdultRandomProperties()
                family.members.forEach { person in
                    if let adult = person as? Adult {
                        dicoOfAdultsRandomProperties[adult.displayName] = AdultRandomProperties(ageOfDeath          : adult.ageOfDeath,
                                                                                                nbOfYearOfDependency: adult.nbOfYearOfDependency)
                    }
                }
                let currentRunResults = SimulationResultLine(runNumber                         : run,
                                                             dicoOfAdultsRandomProperties      : dicoOfAdultsRandomProperties,
                                                             dicoOfEconomyRandomVariables      : dicoOfEconomyRandomVariables,
                                                             dicoOfSocioEconomyRandomVariables : dicoOfSocioEconomyRandomVariables,
                                                             dicoOfKpiResults                  : dicoOfKpiResults)
                resultTable.append(currentRunResults)
                
                // Dernier run, créer les histogrammes et y ranger
                // les échantillons de KPIs si on est en mode Aléatoire
                if run == nbOfRuns {
                    KpiArray.generateHistograms(ofTheseKPIs: &self.kpis)
                }
            }
        }
        //propriétés indépendantes du nombre de run
        firstYear   = Date.now.year
        lastYear    = firstYear + nbOfYears - 1
        isComputed  = true
        isSaved     = false
//        isComputing = false
    }
    
    func replay(thisRun                   : SimulationResultLine,
                withFamily family         : Family,
                withPatrimoine patrimoine : Patrimoin) {
        currentRunNb = 1
        let nbOfYears = lastYear - firstYear + 1
        
        // fixer tous les paramètres du run à rejouer
        Economy.model.setRandomValue(to: thisRun.dicoOfEconomyRandomVariables)
        SocioEconomy.model.setRandomValue(to: thisRun.dicoOfSocioEconomyRandomVariables)
        family.members.forEach { person in
            if let adult = person as? Adult {
                adult.ageOfDeath           = thisRun.dicoOfAdultsRandomProperties[adult.displayName]!.ageOfDeath
                adult.nbOfYearOfDependency = thisRun.dicoOfAdultsRandomProperties[adult.displayName]!.nbOfYearOfDependency
            }
        }
        
        // Réinitialiser la simulation
        self.reset(withPatrimoine : patrimoine,
                   includingKPIs  : false)
        
        // construire les comptes sociaux du patrimoine de la famille:
        // - personnes
        // - dépenses
        _ = socialAccounts.build(nbOfYears      : nbOfYears!,
                                 withFamily     : family,
                                 withPatrimoine : patrimoine,
                                 withKPIs       : &kpis,
                                 withMode       : mode)
        
        // propriétés indépendantes du nombre de run
        firstYear   = Date.now.year
        lastYear    = firstYear + nbOfYears - 1
        isComputed  = true
        isSaved     = false
    }
    
    /// Sauvegarder les résultats de simulation dans des fchier CSV
    func save() {
        /// - un fichier pour le Cash Flow
        /// - un fichier pour le Bilan
        socialAccounts.save(simulationTitle: title)
        
        /// - un fichier pour le tableau de résultat de Monté-Carlo
        if !resultTable.isEmpty {
            resultTable.save(simulationTitle: title)
        }
    }
}
