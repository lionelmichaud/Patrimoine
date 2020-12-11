//
//  Economy.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 12/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Economy Model

struct Economy {
    
    // MARK: - Nested Types

    enum RandomVariable: String, PickableEnum, CaseIterable {
        case inflation    = "Inflation"
        case longTermRate = "Rendements Sûrs"
        case stockRate    = "Rendements Actions"
        
        var pickerString: String {
            return self.rawValue
        }
    }
    
    typealias DictionaryOfRandomVariable = [RandomVariable: Double]
    
    struct Model: Codable {
        var inflation    : ModelRandomizer<BetaRandomGenerator>
        var longTermRate : ModelRandomizer<BetaRandomGenerator>
        var stockRate    : ModelRandomizer<BetaRandomGenerator>
        
        init() {
            self = Bundle.main.decode(Model.self,
                                      from                 : "EconomyModelConfig.json",
                                      dateDecodingStrategy : .iso8601,
                                      keyDecodingStrategy  : .useDefaultKeys)
            inflation.rndGenerator.initialize()
            longTermRate.rndGenerator.initialize()
            stockRate.rndGenerator.initialize()
        }

        func storeItemsToFile(fileNamePrefix: String = "") {
            // encode to JSON file
            Bundle.main.encode(self,
                               to                   : "EconomyModelConfig.json",
                               dateEncodingStrategy : .iso8601,
                               keyEncodingStrategy  : .useDefaultKeys)
        }
        
        mutating func resetRandomHistory() {
            inflation.resetRandomHistory()
            longTermRate.resetRandomHistory()
            stockRate.resetRandomHistory()
        }
        
        mutating func next() -> DictionaryOfRandomVariable {
            var dicoOfRandomVariable = DictionaryOfRandomVariable()
            dicoOfRandomVariable[.inflation]    = inflation.next()
            dicoOfRandomVariable[.longTermRate] = longTermRate.next()
            dicoOfRandomVariable[.stockRate]    = stockRate.next()
            return dicoOfRandomVariable
        }
        
        /// Définir une valeur pour la variable aléaoitre avant un rejeu
        /// - Parameter value: nouvelle valeure à rejouer
        mutating func setRandomValue(to values: DictionaryOfRandomVariable) {
            inflation.setRandomValue(to: values[.inflation]!)
            longTermRate.setRandomValue(to: values[.longTermRate]!)
            stockRate.setRandomValue(to: values[.stockRate]!)
        }
        
        func randomHistories() -> [RandomVariable: [Double]?] {
            var dico = [RandomVariable: [Double]?]()
            for randomVariable in RandomVariable.allCases {
                switch randomVariable {
                    case .inflation:
                        dico[randomVariable] = inflation.randomHistory
                    case .longTermRate:
                        dico[randomVariable] = longTermRate.randomHistory
                    case .stockRate:
                        dico[randomVariable] = stockRate.randomHistory
                }
            }
            return dico
        }
    }
    
    // MARK: - Static Properties
    
    static var model: Model = Model()
}
