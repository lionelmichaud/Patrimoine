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

    enum ModelEnum: Int, PickableEnum {
        case inflation
        case longTermRate
        case stockRate
        
        var id: Int {
            return self.rawValue
        }
        var pickerString: String {
            switch self {
                case .inflation:
                    return "Inflation"
                case .longTermRate:
                    return "Rendements des Placements Sûrs"
                case .stockRate:
                    return "Rendements des Actions"
            }
        }
    }
    
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
        
        mutating func next() {
            inflation.next()
            longTermRate.next()
            stockRate.next()
        }
    }
    
    // MARK: - Static Properties
    
    static var model: Model = Model()
}
