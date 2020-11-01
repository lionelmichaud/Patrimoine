//
//  SimulationResultTable.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 28/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - KPI results

struct KpiResult: Hashable {
    var value              : Double
    var objectiveIsReached : Bool
}

typealias DictionaryOfKpiResults = Dictionary<SimulationKPIEnum, KpiResult>
extension DictionaryOfKpiResults {
    func runResult() -> RunResult {
        for kpi in SimulationKPIEnum.allCases {
            if let objectiveIsReached = self[kpi]?.objectiveIsReached {
                if !objectiveIsReached {
                    return .someObjectiveMissed
                }
            } else {
                // un résultat inconnu
                return .someObjectiveUndefined
            }
        }
        return .allObjectivesReached
    }
}

enum KpiSortCriteriaEnum {
    case byRunNumber
    case byKpi1
    case byKpi2
    case byKpi3
}

// MARK: - Runs results

enum RunResult {
    case allObjectivesReached
    case someObjectiveMissed
    case someObjectiveUndefined
}

enum RunFilterEnum {
    case all
    case someBad
    case somUnknown
}

// MARK: - Propriétés aléatoires d'un Adult

struct AdultRandomProperties: Hashable {
    var ageOfDeath           : Int
    var nbOfYearOfDependency : Int
}
typealias DictionaryOfAdultRandomProperties = Dictionary<String, AdultRandomProperties>

// MARK: - Synthèse d'un Run de Simulation

struct SimulationResultLine: Hashable {
    var runNumber                         : Int
    var dicoOfAdultsRandomProperties      : DictionaryOfAdultRandomProperties
    var dicoOfEconomyRandomVariables      : Economy.DictionaryOfRandomVariable
    var dicoOfSocioEconomyRandomVariables : SocioEconomy.DictionaryOfRandomVariable
    var dicoOfKpiResults                  : DictionaryOfKpiResults
}

typealias SimulationResultTable = Array<SimulationResultLine>
extension SimulationResultTable {
    func filtered(with filter: RunFilterEnum = .all) -> SimulationResultTable {
        switch filter {
            case .all:
                return self
            case .someBad:
                return self.filter { $0.dicoOfKpiResults.runResult() == .someObjectiveMissed }
            case .somUnknown:
                return self.filter { $0.dicoOfKpiResults.runResult() == .someObjectiveUndefined }
        }
    }
    
    func sorted(by criteria    : KpiSortCriteriaEnum,
                with sortOrder : SortingOrder = .ascending) -> SimulationResultTable {
        switch criteria {
            case .byRunNumber:
                return self.sorted(by: {
                    switch sortOrder {
                        case .ascending:
                            return $1.runNumber > $0.runNumber
                        case .descending:
                            return $1.runNumber < $0.runNumber
                    }
                })
            case .byKpi1:
                return self.sorted(by: {
                    switch sortOrder {
                        case .ascending:
                            return ($1.dicoOfKpiResults[.minimumAsset]?.value ?? 0) > ($0.dicoOfKpiResults[.minimumAsset]?.value ?? 0)
                        case .descending:
                            return ($1.dicoOfKpiResults[.minimumAsset]?.value ?? 0) < ($0.dicoOfKpiResults[.minimumAsset]?.value ?? 0)
                    }
                })
            case .byKpi2:
                return self.sorted(by: {
                    switch sortOrder {
                        case .ascending:
                            return ($1.dicoOfKpiResults[.assetAt1stDeath]?.value ?? 0) > ($0.dicoOfKpiResults[.assetAt1stDeath]?.value ?? 0)
                        case .descending:
                            return ($1.dicoOfKpiResults[.assetAt1stDeath]?.value ?? 0) < ($0.dicoOfKpiResults[.assetAt1stDeath]?.value ?? 0)
                    }
                })
            case .byKpi3:
                return self.sorted(by: {
                    switch sortOrder {
                        case .ascending:
                            return ($1.dicoOfKpiResults[.assetAt2ndtDeath]?.value ?? 0) > ($0.dicoOfKpiResults[.assetAt2ndtDeath]?.value ?? 0)
                        case .descending:
                            return ($1.dicoOfKpiResults[.assetAt2ndtDeath]?.value ?? 0) < ($0.dicoOfKpiResults[.assetAt2ndtDeath]?.value ?? 0)
                    }
                })
        }
    }
    
}
