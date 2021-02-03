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
    struct Model: BundleCodable, Versionable {
        static var defaultFileName : String = "PensionReversionModel.json"

        var version      : Version
        let tauxReversion: Double // [0, 100] // 70% de la somme des deux pensions
    }
    
    // MARK: - Properties
    
    private var model: Model
    
    // MARK: - Initializer
    
    init(model: Model) {
        self.model = model
    }
    
    // MARK: - Methods
    
    /// Encode l'objet dans un fichier stocké dans le Bundle de contenant la définition de la classe aClass
    func saveToBundle(for aClass           : AnyClass,
                      to file              : String?,
                      dateEncodingStrategy : JSONEncoder.DateEncodingStrategy,
                      keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy) {
        model.saveToBundle(for                  : aClass,
                           to                   : file,
                           dateEncodingStrategy : dateEncodingStrategy,
                           keyEncodingStrategy  : keyEncodingStrategy)
    }
    func pensionReversion(pensionDecedent : Double,
                          pensionSpouse   : Double) -> Double {
        (pensionDecedent + pensionSpouse) * model.tauxReversion / 100.0
    }
}
