//
//  KPI.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

typealias KpiArray = [KPI]
extension KpiArray {
    /// remettre à zéero l'historique des KPI (Histogramme)
    mutating func resetCopy() -> KpiArray {
        self.map {
            var newKPI = $0
            newKPI.reset()
            return newKPI
        }
    }
}

/// KPI
///
/// Usage:
/// ```
///var kpi = KPI(name            : "My KPI",
///               objective       : 100_000.0,
///               withProbability : 0.95)
///
///// ajoute un échantillon à l'histogramme
///kpi.record(kpiSample1)
///kpi.record(kpiSample2)
///
///// récupère la valeur déterministe du KPI
///// ou valeur du KPI atteinte avec la proba objectif
///let kpiValue = kpi.value()
///
///// valeur du KPI atteinte avec la proba 95%
///let kpiValue = kpi.value(for: 0.95)
///
///// remet à zéro l'historique du KPI
///kpi.reset()
/// ```
///
struct KPI: Identifiable {
    
    // MARK: - Properties
    
    var id = UUID()
    var name: String
    // objectif à atteindre
    var objective: Double
    // probability d'atteindre l'objectif
    var probaObjective: Double
    // valeur déterministe
    private var valueKPI: Double?
    // histogramme des valeurs du KPI
    private var histogram: Histogram
    
    // MARK: - Initializers
    
    internal init(name            : String,
                  objective       : Double,
                  withProbability : Double) {
        self.name           = name
        self.objective      = objective
        self.probaObjective = withProbability
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
                self.valueKPI = 0.0
                
            case .random:
                histogram.reset()
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
