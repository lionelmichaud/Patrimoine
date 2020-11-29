//
//  KPI.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - KpiArray : tableau de KPI

typealias KpiArray = [KPI]
extension KpiArray {
    /// remettre à zéro l'historique des KPI (Histogramme)
    static func reset(theseKPIs     : inout KpiArray,
                      withMode mode : SimulationModeEnum) {
        theseKPIs = theseKPIs.map {
            var newKPI = $0
            newKPI.reset(withMode: mode)
            return newKPI
        }
    }
    
    /// Initialise les cases de l'histogramme et range les échantillons dans les cases
    ///
    /// - Warning: les échantillons doivent avoir été enregistrées au préalable
    ///
    static func generateHistograms(ofTheseKPIs: inout KpiArray) {
        ofTheseKPIs = ofTheseKPIs.map {
            var newKPI = $0
            newKPI.sortHistogram()
            return newKPI
        }
    }
    
    /// remettre à zéro l'historique des KPI (Histogramme)
    func resetCopy(withMode mode : SimulationModeEnum) -> KpiArray {
        self.map {
            var newKPI = $0
            newKPI.reset(withMode: mode)
            return newKPI
        }
    }
    
    /// Est-ce que tous les objectifs sont atteints ?
    /// - Warning:
    ///     Retourne nil si au moins une des valeurs n'est pas définie
    ///
    ///     Ne doit être appelées qu'après la fin du dernier Run
    func allObjectivesAreReached(withMode mode : SimulationModeEnum) -> Bool? {
        var result = true
        for kpi in self {
            if let objectiveIsReached = kpi.objectiveIsReached(withMode: mode) {
                result = result && objectiveIsReached
            } else {
                // un résultat est inconnu
                return nil
            }
        }
        // tous les résultats sont connus
        return result
    }
    

}

// MARK: - KPI : indicateur de performance

/// KPI
///
/// Usage:
/// ```
///       var kpi = KPI(name            : "My KPI",
///                      objective       : 100_000.0,
///                      withProbability : 0.95)
///
///       // ajoute un échantillon à l'histogramme
///       kpi.record(kpiSample1, withMode: .random)
///       kpi.record(kpiSample2, withMode: .random)
///       kpi.record(kpiSample3, withMode: .random)
///       objectiveIsReached = kpi.objectiveIsReachedWithLastValue(withMode: .random)
///
///       // récupère la valeur déterministe du KPI
///       // ou valeur du KPI statistique atteinte avec la proba objectif (withProbability)
///       let kpiValue = kpi.value()
///
///       // valeur du KPI atteinte avec la proba 95%
///       let kpiValue = kpi.value(for: 0.95)
///
///       // remet à zéro l'historique du KPI
///       kpi.reset()
/// ```
///
struct KPI: Identifiable, Codable {
    
    // MARK: - Static Properties
    
    static let nbBucketsInHistograms = 50
    
    // MARK: - Properties
    
    var id = UUID()
    var name            : String
    // objectif à atteindre
    var objective       : Double
    // probability d'atteindre l'objectif
    var probaObjective  : Double
    // valeur déterministe
    private var valueKPI: Double?
    // histogramme des valeurs du KPI
    var histogram: Histogram
    
    // MARK: - Initializers
    
    internal init(name            : String,
                  objective       : Double,
                  withProbability : Double) {
        self.name           = name
        self.objective      = objective
        self.probaObjective = withProbability
        // initializer l'histogramme sans les cases
        self.histogram      = Histogram(name: name)
    }
    
    // MARK: - Methods
    
    mutating func record(_ value       : Double,
                         withMode mode: SimulationModeEnum) {
        switch mode {
            case .deterministic:
                self.valueKPI = value
                
            case .random:
                histogram.record(value)
        }
    }
    
    /// remettre à zéero l'historique du KPI (Histogramme)
    mutating func reset(withMode mode: SimulationModeEnum) {
        switch mode {
            case .deterministic:
                self.valueKPI = nil
                
            case .random:
                histogram.reset()
        }
    }
    
    /// Initialise les cases de l'histogramme et range les échantillons dans les cases
    ///
    /// - Warning: les échantillons doivent avoir été enregistrées au préalable
    ///
    mutating func sortHistogram() {
        histogram.sort(distributionType : .continuous,
                       openEnds         : true,
                       bucketNb         : KPI.nbBucketsInHistograms)
    }
    
    /// Retourne true si la valeur du KPI a été définie au cours de la simulation (.deterministic)
    /// ou peut être calculée (.random)
    func hasValue(for mode: SimulationModeEnum) -> Bool {
        value(withMode: mode) != nil
    }
    
    /// Valeur du KPI
    ///
    /// - Note:
    ///     Mode Déterministe:
    ///     - retourne la valeur unique du KPI
    ///
    ///     Mode Aléatoire:
    ///     - retourne la valeur X telle que la probabilité P(X>Objectif)
    ///     est = à la probabilité Pobjectif.
    ///
    ///     P(X>Objectif) = 1 - P(X<=Objectif)
    ///
    func value(withMode mode: SimulationModeEnum) -> Double? {
        switch mode {
            case .deterministic:
                return valueKPI
                
            case .random:
                return percentile(for: 1.0 - probaObjective)
        }
    }
    
    func lastValue(withMode mode: SimulationModeEnum) -> Double? {
        switch mode {
            case .deterministic:
                return valueKPI
                
            case .random:
                return histogram.lastRecordedValue
        }
    }
    
    /// Valeur du KPI avec la probabilité objectif
    ///
    /// Renvoie la valeur x telle que P(X<x) >= probability
    /// - Parameter probability: probabilité
    /// - Returns: x telle que P(X<x) >= probability
    /// - Warning: probability in [0, 1]
    func percentile(for probability: Double) -> Double? {
        histogram.percentile(for: probability)
    }
    
    /// Renvoie la probabilité P telle que CDF(X) >= P
    /// - Parameter value: valeure dont il faut rechercher la probabilité
    /// - Returns: probabilité P telle que CDF(X) >= P
    /// - Warning: x in [Xmin, Xmax]
    func probability(for value: Double) -> Double? {
        histogram.probability(for: value)
    }

    /// Valeur moyenne du KPI
    func average(withMode mode: SimulationModeEnum) -> Double? {
        switch mode {
            case .deterministic:
                return valueKPI
                
            case .random:
                return histogram.average
        }
    }
    
    /// Valeur médianne du KPI
    func median(withMode mode: SimulationModeEnum) -> Double? {
        switch mode {
            case .deterministic:
                return valueKPI
                
            case .random:
                return histogram.median
        }
    }
    
    /// Valeur min du KPI
    func min(withMode mode: SimulationModeEnum) -> Double? {
        switch mode {
            case .deterministic:
                return valueKPI
                
            case .random:
                return histogram.min
        }
    }
    
    /// Valeur max du KPI
    func max(withMode mode: SimulationModeEnum) -> Double? {
        switch mode {
            case .deterministic:
                return valueKPI
                
            case .random:
                return histogram.max
        }
    }
    
    /// Retourrne true si l'objectif de valeur est atteint lors du run unique (.deterministic)
    /// ou statistiquement sur l'ensmeble des runs (.random)
    func objectiveIsReached(withMode mode: SimulationModeEnum) -> Bool? {
        guard let value = self.value(withMode: mode) else {
            return nil
        }
        return value >= objective
    }
    
    /// Retourrne true si l'objectif de valeur est atteint lors du run unique (.deterministic)
    /// ou sur le dernier run (.random)
    func objectiveIsReachedWithLastValue(withMode mode: SimulationModeEnum) -> Bool? {
        guard let lastValue = self.lastValue(withMode: mode) else {
            return nil
        }
        return lastValue >= objective
    }
}
