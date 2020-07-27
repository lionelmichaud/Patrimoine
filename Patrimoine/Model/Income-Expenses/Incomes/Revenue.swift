//
//  Revenue.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 27/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

/// Table des revenus (perçu, taxable) d'une catégorie nommée donnée
struct Revenue {
    
    // properties
    
    /// nom de la catégorie de revenus
    let name: String
    
    /// table des revenus versés en compte courant avant taxes, prélèvements sociaux et impots
    var credits      = NamedValueTable(name: "PERCU")
    
    /// table des fractions de revenus versés en compte courant qui est imposable à l'IRPP
    var taxablesIrpp = NamedValueTable(name: "TAXABLE")
    
    // methods
    
    func print(level: Int = 0) {
        let h = String(repeating: StringCst.header, count: level)
        Swift.print(h + name)
        Swift.print(h + StringCst.header + "credits:      ", credits, "total:", credits.total)
        Swift.print(h + StringCst.header + "taxables IRPP:", taxablesIrpp, "total:", taxablesIrpp.total)
    }
}

