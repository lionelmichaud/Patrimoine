//
//  SimulationResultTable.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 28/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Disk

// MARK: - KPI results

struct KpiResult: Hashable, Codable {
    var value              : Double
    var objectiveIsReached : Bool
}

typealias DictionaryOfKpiResults = [SimulationKPIEnum: KpiResult]
extension DictionaryOfKpiResults {
    func runResult() -> RunResult {
        for kpi in SimulationKPIEnum.allCases {
            if let objectiveIsReached = self[kpi]?.objectiveIsReached {
                if !objectiveIsReached {
                    // un résultat est défini avec un objectif non atteint
                    return .someObjectiveMissed
                }
            } else {
                // un résultat non défini
                return .someObjectiveUndefined
            }
        }
        // tous les résultats sont définis et les objectifs sont toujours atteints
        return .allObjectivesReached
    }
}

enum KpiSortCriteriaEnum: String, Codable {
    case byRunNumber
    case byKpi1
    case byKpi2
    case byKpi3
}

// MARK: - Runs results

enum RunResult: String, Codable {
    case allObjectivesReached
    case someObjectiveMissed
    case someObjectiveUndefined
}

enum RunFilterEnum: String, Codable {
    case all
    case someBad
    case somUnknown
}

// MARK: - Propriétés aléatoires d'un Adult

struct AdultRandomProperties: Hashable, Codable {
    var ageOfDeath           : Int
    var nbOfYearOfDependency : Int
}
typealias DictionaryOfAdultRandomProperties = [String: AdultRandomProperties]

// MARK: - Synthèse d'un Run de Simulation

struct SimulationResultLine: Hashable {
    var runNumber                         : Int
    var dicoOfAdultsRandomProperties      : DictionaryOfAdultRandomProperties
    var dicoOfEconomyRandomVariables      : Economy.DictionaryOfRandomVariable
    var dicoOfSocioEconomyRandomVariables : SocioEconomy.DictionaryOfRandomVariable
    var dicoOfKpiResults                  : DictionaryOfKpiResults
    var valuesCSV: String {
        let separator = "; "
        var line = String(runNumber) + separator
        // propriétés aléatoires des adultes
        for name in dicoOfAdultsRandomProperties.keys.sorted() {
            line += String(dicoOfAdultsRandomProperties[name]!.ageOfDeath) + separator
            line += String(dicoOfAdultsRandomProperties[name]!.nbOfYearOfDependency) + separator
        }
        // valeurs aléatoires de conditions économiques
        for variableEnum in Economy.RandomVariable.allCases {
            line += (dicoOfEconomyRandomVariables[variableEnum]?.percentString(digit: 1) ?? "") + separator
        }
        // valeurs aléatoires de conditions socio-économiques
        for variableEnum in SocioEconomy.RandomVariable.allCases {
            switch variableEnum {
                case .nbTrimTauxPlein:
                    line += dicoOfSocioEconomyRandomVariables[variableEnum]!.roundedString + separator
                    
                default:
                    line += dicoOfSocioEconomyRandomVariables[variableEnum]!.percentString(digit: 1) + separator
            }
        }
        // valeurs résultantes des KPIs
        for kpiEnum in SimulationKPIEnum.allCases {
            if let kpiResult = dicoOfKpiResults[kpiEnum] {
                line += kpiResult.value.roundedString + separator
            } else {
                line += "indéfini" + separator
            }
        }
        return line
    }
}

typealias SimulationResultTable = [SimulationResultLine]
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
    // swiftlint:disable:next cyclomatic_complexity
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
    
    func save(simulationTitle: String) {
        let separator = "; "
        let lineBreak = "\n"
        
        func header() -> String {
            var header = "Run" + separator
            // propriétés aléatoires des adultes
            for name in self.first!.dicoOfAdultsRandomProperties.keys.sorted() {
                header += "Durée de Vie " + name + separator
                header += "Dépendance " + name + separator
            }
            // valeurs aléatoires de conditions économiques
            for variableEnum in Economy.RandomVariable.allCases {
                header += variableEnum.pickerString + separator
            }
            // valeurs aléatoires de conditions socio-économiques
            for variableEnum in SocioEconomy.RandomVariable.allCases {
                header += variableEnum.pickerString + separator
            }
            // valeurs résultantes des KPIs
            for variableEnum in SimulationKPIEnum.allCases {
                header += variableEnum.pickerString + separator
            }
            return header
        }
        
        guard !self.isEmpty else { return }
        
        let csvString = self.reduce(header() + lineBreak, { result, element in result + element.valuesCSV + lineBreak })
//        print(csvString)

        #if DEBUG
        // sauvegarder le fichier dans le répertoire Bundle/csv
        do {
            try csvString.write(to: SocialAccounts.cashFlowFileUrl!,
                                atomically: true ,
                                encoding: .utf8)
        } catch {
            print("error creating file: \(error)")
        }
        #endif
        
        // sauvegarder le fichier dans le répertoire documents/csv
        let fileName = "Monté-Carlo Kpi.csv"
        do {
            try Disk.save(Data(csvString.utf8),
                          to: .documents,
                          as: AppSettings.csvPath(simulationTitle) + fileName)
            #if DEBUG
            Swift.print("saving 'Monté-Carlo Kpi.csv' to file: ", AppSettings.csvPath(simulationTitle) + fileName)
            #endif
        } catch let error as NSError {
            fatalError("""
                Domain         : \(error.domain)
                Code           : \(error.code)
                Description    : \(error.localizedDescription)
                Failure Reason : \(error.localizedFailureReason ?? "")
                Suggestions    : \(error.localizedRecoverySuggestion ?? "")
                """)
        }
    }
}
