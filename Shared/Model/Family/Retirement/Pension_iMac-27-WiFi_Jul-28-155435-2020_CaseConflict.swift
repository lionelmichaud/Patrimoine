//
//  Retirement.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// https://www.service-public.fr/particuliers/vosdroits/F21552

struct Pension: Codable {
    
    struct Model: Codable {
        var regimeGeneral: RegimeGeneral
        var regimeAgirc  : RegimeAgirc
    }
    
    static var model: Model =
        Bundle.main.decode(Model.self,
                           from                 : "PensionModel.json",
                           dateDecodingStrategy : .iso8601,
                           keyDecodingStrategy  : .useDefaultKeys)
}
