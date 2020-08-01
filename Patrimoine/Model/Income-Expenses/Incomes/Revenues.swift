//
//  Revenue.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 27/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - agrégat de revenus pour une catégories donnée

struct Revenues {
    
    // properties
    
    let name = "REVENUS HORS SCI"
    var perCategory: [RevenueCategory: RevenuesInCategory] = [:]
    
    /// revenus imposable de l'année précédente et reporté à l'année courante
    var taxableIrppRevenueDelayedFromLastYear = Debt(name: "REVENU IMPOSABLE REPORTE DE L'ANNEE PRECEDENTE", value: 0)
    
    /// total de tous les revenus nets de l'année versé en compte courant avant taxes et impots
    var totalCredited: Double {
        perCategory.reduce(.zero, { result, element in result + element.value.credits.total } )
        //        var total = 0.0
        //        for category in RevenueCategory.allCases {
        //            total += revenuesPerCategory[category]?.credits.total ?? 0.0
        //        }
        //        return total
    }
    /// total de tous les revenus de l'année imposables à l'IRPP
    var totalTaxableIrpp: Double {
        // ne pas oublier les revenus en report d'imposition
        perCategory.reduce(.zero, { result, element in result + element.value.taxablesIrpp.total } )
        + taxableIrppRevenueDelayedFromLastYear.value(atEndOf: 0)
    }
    
    /// tableau des noms de catégories et valeurs total des revenus de cette catégorie
    var namedValueTable: NamedValueTable {
        var table = NamedValueTable(name: "REVENUS")
        
        // itérer sur l'enum pour préserver l'ordre
        for category in RevenueCategory.allCases {
            if let element = perCategory[category] {
                table.values.append((name  : element.name,
                                     value : element.credits.total))
            }
        }
        return table
    }
    
    /// tableau détaillé des noms des revenus: concaténation des catégories
    var headersDetailedArray: [String] {
        var headers: [String] = [ ]
        perCategory.forEach { element in
            headers += element.value.credits.headersArray
        }
        return headers
    }
    /// tableau détaillé des valeurs des revenus: concaténation des catégories
    var valuesDetailedArray: [Double] {
        var values: [Double] = [ ]
        perCategory.forEach { element in
            values += element.value.credits.valuesArray
        }
        return values
    }
    
    // initialization
    
    /// Initializer toutes les catéogires (avec des tables vides de revenu)
    init() {
        for category in RevenueCategory.allCases {
            perCategory[category] = RevenuesInCategory(name: category.displayString)
        }
    }

    // methods
    
    func print(level: Int = 0) {
        let h = String(repeating: StringCst.header, count: level)
        Swift.print(h + name + ":    ")
        
        for category in RevenueCategory.allCases {
            perCategory[category]?.print(level: level)
        }

        // revenus imposable de l'année précédente et reporté à l'année courante
        taxableIrppRevenueDelayedFromLastYear.print()
        
        // total des revenus
        Swift.print(h + StringCst.header + "TOTAL NET:", totalCredited, "TOTAL TAXABLE:", totalTaxableIrpp)
    }
}

// MARK: Agrégat de tables des revenus (perçu, taxable) pour une catégorie nommée donnée

struct RevenuesInCategory {
    
    // properties
    
    /// nom de la catégorie de revenus
    var name: String // category.displayString
    
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
    
    func print() {
        print(level: 0)
    }

}

