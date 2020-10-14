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

    struct Model: Codable {
        var inflation    : ModelRandomizer<BetaRandomGenerator>
        var longTermRate : ModelRandomizer<BetaRandomGenerator>
        var stockRate    : ModelRandomizer<BetaRandomGenerator>
        
        init() {
            self = Bundle.main.decode(Model.self,
                                      from                 : "EconomyModelConfig.json",
                                      dateDecodingStrategy : .iso8601,
                                      keyDecodingStrategy  : .useDefaultKeys)
            inflation.distribution.initialize()
            longTermRate.distribution.initialize()
            stockRate.distribution.initialize()
        }

        mutating func next() {
            inflation.next()
            longTermRate.next()
            stockRate.next()
        }
    }
    
    // MARK: - Static Properties
    
    static var model: Model = Model()
}
