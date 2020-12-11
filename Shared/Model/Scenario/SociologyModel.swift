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
    
    enum RandomVariable: String, PickableEnum {
        case pensionDevaluationRate      = "Dévaluation de Pension"
        case nbTrimTauxPlein             = "Trimestres Supplémentaires"
        case expensesUnderEvaluationrate = "Sous-etimation dépenses"

        var pickerString: String {
            return self.rawValue
        }
    }
    
    typealias DictionaryOfRandomVariable = [RandomVariable: Double]

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
        
        mutating func next() -> DictionaryOfRandomVariable {
            var dicoOfRandomVariable = DictionaryOfRandomVariable()
            dicoOfRandomVariable[.pensionDevaluationRate]      = pensionDevaluationRate.next()
            dicoOfRandomVariable[.nbTrimTauxPlein]             = nbTrimTauxPlein.next()
            dicoOfRandomVariable[.expensesUnderEvaluationrate] = expensesUnderEvaluationrate.next()
            return dicoOfRandomVariable
        }
        
        /// Définir une valeur pour la variable aléaoitre avant un rejeu
        /// - Parameter value: nouvelle valeure à rejouer
        mutating func setRandomValue(to values: DictionaryOfRandomVariable) {
            pensionDevaluationRate.setRandomValue(to: values[.pensionDevaluationRate]!)
            nbTrimTauxPlein.setRandomValue(to: values[.nbTrimTauxPlein]!)
            expensesUnderEvaluationrate.setRandomValue(to: values[.expensesUnderEvaluationrate]!)
        }
        
        func randomHistories() -> [RandomVariable: [Double]?] {
            var dico = [RandomVariable: [Double]?]()
            for randomVariable in RandomVariable.allCases {
                switch randomVariable {
                    case .pensionDevaluationRate:
                        dico[randomVariable] = pensionDevaluationRate.randomHistory
                    case .nbTrimTauxPlein:
                        dico[randomVariable] = nbTrimTauxPlein.randomHistory
                    case .expensesUnderEvaluationrate:
                        dico[randomVariable] = expensesUnderEvaluationrate.randomHistory
                }
            }
            return dico
        }
    }
    
    // MARK: - Static Properties
    
    static var model: Model = Model()
}
