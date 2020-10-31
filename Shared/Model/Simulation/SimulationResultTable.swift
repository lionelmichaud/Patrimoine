//
//  SimulationResultTable.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 28/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct KpiResult: Hashable {
    var value              : Double
    var objectiveIsReached : Bool
}
typealias DictionaryOfKpiResults = Dictionary<SimulationKPIEnum, KpiResult>

struct AdultRandomProperties: Hashable {
    var ageOfDeath           : Int
    var nbOfYearOfDependency : Int
}
typealias DictionaryOfAdultRandomProperties = Dictionary<String, AdultRandomProperties>

struct SimulationResultLine: Hashable {
    var runNumber                         : Int
    var dicoOfAdultsRandomProperties      : DictionaryOfAdultRandomProperties
    var dicoOfEconomyRandomVariables      : Economy.DictionaryOfRandomVariable
    var dicoOfSocioEconomyRandomVariables : SocioEconomy.DictionaryOfRandomVariable
    var dicoOfKpiResults                  : DictionaryOfKpiResults
}

typealias SimulationResultTable = Array<SimulationResultLine>
