//
//  SimulationMode.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 30/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

enum SimulationModeEnum: String, PickableEnum, Codable, Hashable {
    case deterministic = "Déterministe"
    case random        = "Aléatoire"
    
    // properties
    
    var pickerString: String {
        return self.rawValue
    }
}
