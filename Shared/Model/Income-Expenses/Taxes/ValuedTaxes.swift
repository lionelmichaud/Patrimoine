//
//  Taxes.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/08/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - agrégat des taxes

struct ValuedTaxes {

    // properties
    
    let name = "TAXES"
    var perCategory: [TaxeCategory: NamedValueTable] = [:]
    var familyQuotient: Double = 0.0

    /// total de tous les revenus nets de l'année versé en compte courant avant taxes et impots
    var total: Double {
        perCategory.reduce(.zero, { result, element in result + element.value.total } )
    }
    
    /// tableau des noms de catégories et valeurs total des taxes de cette catégorie
    var namedValueTable: NamedValueTable {
        var table = NamedValueTable(name: name)
        
        // itérer sur l'enum pour préserver l'ordre
        for category in TaxeCategory.allCases {
            if let element = perCategory[category] {
                table.values.append((name  : element.name,
                                     value : element.total))
            }
        }
        return table
    }
    
    /// tableau détaillé des noms des revenus: concaténation des catégories
    var headersDetailedArray: [String] {
        var headers: [String] = [ ]
        perCategory.forEach { element in
            headers += element.value.headersArray
        }
        return headers
    }
    /// tableau détaillé des valeurs des revenus: concaténation des catégories
    var valuesDetailedArray: [Double] {
        var values: [Double] = [ ]
        perCategory.forEach { element in
            values += element.value.valuesArray
        }
        return values
    }
    
    // initialization
    
    /// Initializer toutes les catéogires (avec des tables vides de revenu)
    init() {
        for category in TaxeCategory.allCases {
            perCategory[category] = NamedValueTable(name: category.displayString)
        }
    }
    
    // methods
    
    func print(level: Int = 0) {
        let h = String(repeating: StringCst.header, count: level)
        Swift.print(h + name + ":    ")
        
        for category in TaxeCategory.allCases {
            perCategory[category]?.print(level: level)
        }
        
        // total des revenus
        Swift.print(h + StringCst.header + "TOTAL:", total)
    }
}
