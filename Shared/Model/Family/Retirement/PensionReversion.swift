//
//  PensionReversion.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 28/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct PensionReversion: Codable {
    
    // MARK: - Nested types
    
    // https://www.retraite.com/dossier-retraite/pension-de-reversion/evolution-de-la-pension-de-reversion-dans-la-reforme-des-retraites.html
    struct Model: Codable {
        let tauxReversion: Double // 70% de la somme des deux pensions
    }
    
    // MARK: - Properties
    
    var model: Model
    
    // MARK: - Methods
    
}
