//
//  Sociology.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - SocioEconomic Model

struct SocioEconomy {
    
    // MARK: - Nested Types
    
    enum ModelEnum: Int, PickableEnum {
        case pensionDevaluationRate
        case nbTrimTauxPlein
        case expensesUnderEvaluationrate

        var id: Int {
            return self.rawValue
        }
        var pickerString: String {
            switch self {
                case .pensionDevaluationRate:
                    return "Dévaluation de Pension"
                case .nbTrimTauxPlein:
                    return "Nombre de Trimestres"
                case .expensesUnderEvaluationrate:
                    return "Sous-etimation des dépenses"
            }
        }
    }
    
    struct Model: Codable {
        var pensionDevaluationRate     : ModelRandomizer<BetaRandomGenerator>
        var nbTrimTauxPlein            : ModelRandomizer<DiscreteRandomGenerator>
        var expensesUnderEvaluationrate: ModelRandomizer<BetaRandomGenerator>

        init() {
            self = Bundle.main.decode(Model.self,
                                      from                 : "SocioEconomyModelConfig.json",
                                      dateDecodingStrategy : .iso8601,
                                      keyDecodingStrategy  : .useDefaultKeys)
            pensionDevaluationRate.rndGenerator.initialize()
            nbTrimTauxPlein.rndGenerator.initialize()
            expensesUnderEvaluationrate.rndGenerator.initialize()
        }
        
        func storeItemsToFile(fileNamePrefix: String = "") {
            // encode to JSON file
            Bundle.main.encode(self,
                               to                   : "SocioEconomyModelConfig.json",
                               dateEncodingStrategy : .iso8601,
                               keyEncodingStrategy  : .useDefaultKeys)
        }
        
        mutating func resetRandomHistory() {
            pensionDevaluationRate.resetRandomHistory()
            nbTrimTauxPlein.resetRandomHistory()
            expensesUnderEvaluationrate.resetRandomHistory()
        }
        
        mutating func next() {
            pensionDevaluationRate.next()
            nbTrimTauxPlein.next()
            expensesUnderEvaluationrate.next()
        }
    }
    
    // MARK: - Static Properties
    
    static var model: Model = Model()
}
