//
//  SimulationResultTable.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 28/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

typealias DictionaryOfKpiResults = Dictionary<SimulationKPIEnum, (value: Double, objeciveReached: Bool)>

struct SimulationResultLine {
    var runNumber                         : Int
    var dicoOfKpiResults                  : DictionaryOfKpiResults
    var dicoOfEconomyRandomVariables      : Economy.DictionaryOfRandomVariable
    var dicoOfSocioEconomyRandomVariables : SocioEconomy.DictionaryOfRandomVariable
    var adultsRandomProperties            : [(name: String, ageOfDeath: Int, nbOfYearOfDependency: Int)]
}

typealias SimulationResultTable = Array<SimulationResultLine>
