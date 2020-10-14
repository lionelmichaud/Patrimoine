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
    
    struct Model: Codable {
        var pensionDevaluationRate     : ModelRandomizer<BetaRandomGenerator>
        var nbTrimTauxPlein            : ModelRandomizer<DiscreteRandomGenerator>
        var expensesUnderEvaluationrate: ModelRandomizer<BetaRandomGenerator>

        init() {
            self = Bundle.main.decode(Model.self,
                                      from                 : "SocioEconomyModelConfig.json",
                                      dateDecodingStrategy : .iso8601,
                                      keyDecodingStrategy  : .useDefaultKeys)
            pensionDevaluationRate.distribution.initialize()
            nbTrimTauxPlein.distribution.initialize()
            expensesUnderEvaluationrate.distribution.initialize()
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
