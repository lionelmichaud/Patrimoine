//
//  Config.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 11/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct Config {
    static let imageDir = "image/"
    static let csvDir   = "csv/"

    static func csvPath(_ simulationTitle: String) -> String {
        simulationTitle + "/" + Config.csvDir
    }
    
    static func imagePath(_ simulationTitle: String) -> String {
        simulationTitle + "/" + Config.imageDir
    }
    
}
