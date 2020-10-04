//
//  KPI.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

typealias kpiArray = [KPI]

struct KPI {

    // MARK: - Properties
    
    var name: String
    // objectif à atteindre
    var objective: Double
    // probability d'atteindre l'objectif
    var probaObjective: Double
    // valeur déterministe
    private var valueKPI: Double?
    // histogramme des valeurs du KPI
    private var histogram = Histogram()
    
    // MARK: - Methods
    
    mutating func record(_ value: Double) {
        switch simulationMode.mode {
            case .deterministic:
                self.valueKPI = value
                
            case .random:
                histogram.record(value)
        }
    }

    func value() -> Double? {
        switch simulationMode.mode {
            case .deterministic:
                return valueKPI
                
            case .random:
                return histogram.percentile(probability: probaObjective)
        }
    }

}
