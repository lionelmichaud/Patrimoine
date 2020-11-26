//
//  Config.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 11/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct AppSettings: Decodable {
    
    // MARK: - Singleton
    
    static let shared = AppSettings()
    
    // MARK: - Properties
    
    var appVersion : Version
    var imageDir   : String = "image/"
    var tableDir   : String = "csv/"

    // MARK: - Static Methods
    
    static func csvPath(_ simulationTitle: String) -> String {
        simulationTitle + "/" + AppSettings.shared.tableDir
    }
    
    static func imagePath(_ simulationTitle: String) -> String {
        simulationTitle + "/" + AppSettings.shared.imageDir
    }

    init() {
        self = Bundle.main.decode(AppSettings.self,
                                  from                 : "AppSettings.json",
                                  dateDecodingStrategy : .iso8601,
                                  keyDecodingStrategy  : .useDefaultKeys)
    }
}
