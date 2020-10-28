//
//  HumanLifeModel.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Human Life Model

struct HumanLife {
    
    // MARK: - Nested Types
    
    enum RandomVariable: Int, PickableEnum {
        case menLifeEpectation
        case womenLifeExpectation
        case nbOfYearsOfdependency
        
        var id: Int {
            return self.rawValue
        }
        var pickerString: String {
            switch self {
                case .menLifeEpectation:
                    return "Espérance de Vie d'un Homme"
                case .womenLifeExpectation:
                    return "Espérance de Vie d'uns Femme"
                case .nbOfYearsOfdependency:
                    return "Nombre d'années de Dépendance"
            }
        }
    }
    
    struct Model: Codable {
        var menLifeEpectation     : ModelRandomizer<DiscreteRandomGenerator>
        var womenLifeExpectation  : ModelRandomizer<DiscreteRandomGenerator>
        var nbOfYearsOfdependency : ModelRandomizer<DiscreteRandomGenerator>
        
        init() {
            self = Bundle.main.decode(Model.self,
                                      from                 : "HumanLifeModelConfig.json",
                                      dateDecodingStrategy : .iso8601,
                                      keyDecodingStrategy  : .useDefaultKeys)
            menLifeEpectation.rndGenerator.initialize()
            womenLifeExpectation.rndGenerator.initialize()
            nbOfYearsOfdependency.rndGenerator.initialize()
        }
        
        func storeItemsToFile(fileNamePrefix: String = "") {
            // encode to JSON file
            Bundle.main.encode(self,
                               to                   : "HumanLifeModelConfig.json",
                               dateEncodingStrategy : .iso8601,
                               keyEncodingStrategy  : .useDefaultKeys)
        }
        
        mutating func resetRandomHistory() {
            menLifeEpectation.resetRandomHistory()
            womenLifeExpectation.resetRandomHistory()
            nbOfYearsOfdependency.resetRandomHistory()
        }
        
//        mutating func next() {
//            menLifeEpectation.next()
//            womenLifeExpectation.next()
//            nbOfYearsOfdependency.next()
//        }
//
        func randomHistories() -> Dictionary<RandomVariable, [Double]?> {
            var dico = Dictionary<RandomVariable, [Double]?>()
            for randomVariable in RandomVariable.allCases {
                switch randomVariable {
                    case .menLifeEpectation:
                        dico[randomVariable] = menLifeEpectation.randomHistory
                    case .womenLifeExpectation:
                        dico[randomVariable] = womenLifeExpectation.randomHistory
                    case .nbOfYearsOfdependency:
                        dico[randomVariable] = nbOfYearsOfdependency.randomHistory
                }
            }
            return dico
        }    
    }
    
    // MARK: - Static Properties
    
    static var model: Model = Model()
}
