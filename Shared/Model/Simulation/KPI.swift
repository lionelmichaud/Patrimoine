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
    /// Est-ce que tous les objectifs sont atteints ?
    /// - Warning: Retourne nil si au moins une des valeurs n'est pas définie
    var allObjectivesAreReached : Bool? {
        var result = true
        for kpi in self {
            if let objectiveIsReached = kpi.objectiveIsReached {
                result = result && objectiveIsReached
            } else {
                // un résultat est inconnu
                return nil
            }
        }
        // tous les résultats sont connus
        return result
    }
    
    /// remettre à zéro l'historique des KPI (Histogramme)
    func resetCopy() -> KpiArray {
        self.map {
            var newKPI = $0
            newKPI.reset()
            return newKPI
        }
    }
    
    /// remettre à zéro l'historique des KPI (Histogramme)
    static func reset(theseKPIs: inout KpiArray) {
        theseKPIs = theseKPIs.map {
            var newKPI = $0
            newKPI.reset()
            return newKPI
        }
    }
    
    /// Initialise les cases de l'histogramme et range les échantillons dans les cases
    ///
    /// - Warning: les échantillons doivent avoir été enregistrées au préalable
    ///
    static func sortHistograms(ofTheseKPIs: inout KpiArray) {
        ofTheseKPIs = ofTheseKPIs.map {
            var newKPI = $0
            newKPI.sortHistogram()
            return newKPI
        }
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
///       kpi.record(kpiSample1)
///       kpi.record(kpiSample2)
///
///       // récupère la valeur déterministe du KPI
///       // ou valeur du KPI atteinte avec la proba objectif
///       let kpiValue = kpi.value()
///
///       // valeur du KPI atteinte avec la proba 95%
///       let kpiValue = kpi.value(for: 0.95)
///
///       // remet à zéro l'historique du KPI
///       kpi.reset()
/// ```
///
struct KPI: Identifiable {
    
    // MARK: - Static Properties
    
    static let nbBucketsInHistograms = 50
    
    // MARK: - Properties
    
    var id = UUID()
    var name: String
    // objectif à atteindre
    var objective       : Double
    // probability d'atteindre l'objectif
    var probaObjective  : Double
    // valeur déterministe
    private var valueKPI: Double?
    // histogramme des valeurs du KPI
    var histogram: Histogram
    // true si l'objectif de valeur est atteint
    var objectiveIsReached: Bool? {
        guard let value = self.value() else {
            return nil
        }
        return value >= objective
    }
    
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
    
    mutating func record(_ value: Double) {
        switch simulationMode.mode {
            case .deterministic:
                self.valueKPI = value
                
            case .random:
                histogram.record(value)
        }
    }
    
    /// remettre à zéero l'historique du KPI (Histogramme)
    mutating func reset() {
        switch simulationMode.mode {
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
        switch simulationMode.mode {
            case .deterministic:
                ()
                
            case .random:
                histogram.sort(distributionType : .continuous,
                               openEnds         : true,
                               bucketNb         : KPI.nbBucketsInHistograms)
        }
    }
    
    func value() -> Double? {
        switch simulationMode.mode {
            case .deterministic:
                return valueKPI
                
            case .random:
                return histogram.percentile(for: probaObjective)
        }
    }

    func value(for probability: Double) -> Double? {
        switch simulationMode.mode {
            case .deterministic:
                return nil
                
            case .random:
                return histogram.percentile(for: probability)
        }
    }
}
