//
//  Economy.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 12/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct Economy {
    struct Model: Codable, Versionable {
        var version   : Version
        var inflation : Double
    }
    
    // properties
    
    static var model: Model  =
        Bundle.main.decode(Model.self,
                           from                 : "Economy.json",
                           dateDecodingStrategy : .iso8601,
                           keyDecodingStrategy  : .useDefaultKeys)
    
    static func randomize() {
        
    }
}
