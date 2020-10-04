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
    
    // nested types
    
    struct Model: Codable {
        var inflation    : ModelRandomizer<BetaRandomGenerator>
        var longTermRate : ModelRandomizer<DiscreteRandomGenerator>
        
        mutating func next() {
            inflation.next()
            longTermRate.next()
        }
    }
    
    // static properties
    
    static var model: Model  =
        Bundle.main.decode(Model.self,
                           from                 : "EconomyModelConfig.json",
                           dateDecodingStrategy : .iso8601,
                           keyDecodingStrategy  : .useDefaultKeys)
}
