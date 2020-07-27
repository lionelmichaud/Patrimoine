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
    
    var revenuesPerCategory: [RevenueCategory: RevenuesInCategory] = [:]

    /// revenus du travail
    var workIncomes        = RevenuesInCategory(name : "Revenu Travail")
    /// pension de retraite
    var pensions           = RevenuesInCategory(name : "Revenu Pension")
    /// indemnité de licenciement
    var layoffCompensation = RevenuesInCategory(name : "Indemnité de licenciement")
    /// alloc chomage
    var unemployAlloc      = RevenuesInCategory(name : "Revenu Alloc Chomage")
    /// revenus financiers
    var financials         = RevenuesInCategory(name : "Revenu Financier")
    /// revenus des SCPI hors de la SCI
    var scpis              = RevenuesInCategory(name : "Revenu SCPI")
    /// revenus de locations des biens immobiliers
    var realEstateRents    = RevenuesInCategory(name : "Revenu Location")
    /// total des ventes des SCPI hors de la SCI
    var scpiSale           = RevenuesInCategory(name : "Vente SCPI")
    /// total des ventes des biens immobiliers
    var realEstateSale     = RevenuesInCategory(name : "Vente Immobilier")
    /// revenus imposable de l'année précédente et reporté à l'année courante
    var taxableIrppRevenueDelayedFromLastYear = Debt(name: "REVENU IMPOSABLE REPORTE DE L'ANNEE PRECEDENTE", value: 0)
    
    /// total de tous les revenus nets de l'année versé en compte courant avant taxes et impots
    var totalCredited: Double {
        workIncomes.credits.total +
            pensions.credits.total +
            layoffCompensation.credits.total +
            unemployAlloc.credits.total +
            financials.credits.total +
            scpis.credits.total +
            realEstateRents.credits.total +
            scpiSale.credits.total +
            realEstateSale.credits.total
    }
    /// total de tous les revenus de l'année imposables à l'IRPP
    var totalTaxableIrpp: Double {
        workIncomes.taxablesIrpp.total +
            pensions.taxablesIrpp.total +
            layoffCompensation.taxablesIrpp.total +
            unemployAlloc.taxablesIrpp.total +
            financials.taxablesIrpp.total +
            scpis.taxablesIrpp.total +
            realEstateRents.taxablesIrpp.total +
            scpiSale.taxablesIrpp.total +
            realEstateSale.taxablesIrpp.total +
            // ne pas oublier les revenus en report d'imposition
            taxableIrppRevenueDelayedFromLastYear.value(atEndOf: 0)
    }
    
    /// tableau des noms  et valeurs des catégories de revenus
    var namedValueTable: NamedValueTable {
        var table = NamedValueTable(name: "REVENUS")
        table.values.append((name  : workIncomes.name,
                             value : workIncomes.credits.total))
        table.values.append((name  : layoffCompensation.name,
                             value : layoffCompensation.credits.total))
        table.values.append((name  : unemployAlloc.name,
                             value : unemployAlloc.credits.total))
        table.values.append((name  : pensions.name,
                             value : pensions.credits.total))
        table.values.append((name  : financials.name,
                             value : financials.credits.total))
        table.values.append((name  : scpis.name,
                             value : scpis.credits.total))
        table.values.append((name  : realEstateRents.name,
                             value : realEstateRents.credits.total))
        table.values.append((name  : scpiSale.name,
                             value : scpiSale.credits.total))
        table.values.append((name  : realEstateSale.name,
                             value : realEstateSale.credits.total))
        return table
    }
    
    /// tableau détaillé des noms des revenus: concaténation des catégories
    var headersDetailedArray: [String] {
        workIncomes.credits.headersArray +
            pensions.credits.headersArray +
            layoffCompensation.credits.headersArray +
            unemployAlloc.credits.headersArray +
            financials.credits.headersArray +
            scpis.credits.headersArray +
            realEstateRents.credits.headersArray +
            scpiSale.credits.headersArray +
            realEstateSale.credits.headersArray
    }
    /// tableau détaillé des valeurs des revenus: concaténation des catégories
    var valuesDetailedArray: [Double] {
        workIncomes.credits.valuesArray +
            pensions.credits.valuesArray +
            layoffCompensation.credits.valuesArray +
            unemployAlloc.credits.valuesArray +
            financials.credits.valuesArray +
            scpis.credits.valuesArray +
            realEstateRents.credits.valuesArray +
            scpiSale.credits.valuesArray +
            realEstateSale.credits.valuesArray
    }
    
    // initialization
    
    /// Initializer toutes les catéogires (avec des tables vides de revenu)
    init() {
        for category in RevenueCategory.allCases {
            revenuesPerCategory[category] = RevenuesInCategory(name: category.displayString)
        }
    }

    // methods
    
    func print(level: Int = 0) {
        let h = String(repeating: StringCst.header, count: level)
        Swift.print(h + name + ":    ")
        
        for category in RevenueCategory.allCases {
            revenuesPerCategory[category]?.print(level: level)
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
    var name: String
    
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

