//
//  SCI.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// ligne anuelle de cash flow de la SCI
struct SciCashFlowLine {
    
    // MARK: - Nested types

    // revenus de la SCI
    struct Revenues {
        
        // properties
        
        // dividendes des SCPI de la SCI
        var sciDividends = NamedValueTable(name: "SCI-REVENUS DE SCPI")
        // ventes des SCPI de la SCI
        var scpiSale     = NamedValueTable(name: "SCI-VENTES SCPI")
        // total de tous les revenus nets de l'année: loyers + ventes de la SCI
        var total: Double { sciDividends.total + scpiSale.total }
        // total de tous les revenus imposables à l'IS de l'année: loyers + plus-values de la SCI
        // tableau résumé des noms
        var namesArray: [String] {
            ["SCI-" + sciDividends.name, "SCI-" + scpiSale.name]
        }
        // tableau résumé des valeurs
        var valuesArray: [Double] {
            [sciDividends.total, scpiSale.total]
        }
        // tableau détaillé des noms
        var headersDetailedArray: [String] {
            sciDividends.namesArray + scpiSale.namesArray
        }
        // tableau détaillé des valeurs
        var valuesDetailedArray: [Double] {
            sciDividends.valuesArray + scpiSale.valuesArray
        }
        
        // methods
        
        func print(level: Int = 0) {
            let h = String(repeating: StringCst.header, count: level)
            Swift.print(h + "REVENUS SCI:    ")
            // SCPIs dividendes
            sciDividends.print(level: level+1)
            // SCPIs ventes
            scpiSale.print(level: level+1)
            // total des revenus
            Swift.print(h + StringCst.header + "TOTAL:", total)
        }
    }
    
    // MARK: - Properties

    let year        : Int
    var revenues    = Revenues() // revenus des SCPI de la SCI
    // TODO: Ajouter les dépenses de la SCI déductibles du revenu (comptable, gestion, banque...)
    let IS          : Double // impôts sur les société
    var netCashFlow : Double { revenues.total - IS }
    
    // tableau résumé des noms
    var namesArray: [String] {
        revenues.namesArray + ["SCI-IS"]
    }
    // tableau résumé des valeurs
    var valuesArray: [Double] {
        Swift.print(revenues.valuesArray + [-IS])
        return revenues.valuesArray + [-IS]
    }
    // tableau détaillé des noms
    var namesDetailedArray: [String] {
        revenues.headersDetailedArray + ["SCI-IS"]
    }
    // tableau détaillé des valeurs
    var valuesDetailedArray: [Double] {
        revenues.valuesDetailedArray + [-IS]
    }
    
    var summary: NamedValueTable {
        var table = NamedValueTable(name: "SCI")
        table.namedValues.append((name  : "Revenu SCI",
                                  value : netCashFlow))
        return table
    }
    
    // MARK: - Initializers

    init(withYear year: Int, withSCI sci: SCI) {
        self.year = year
        
        // populate produit de vente, dividendes des SCPI
        
        // pour chaque SCPI
        for scpi in sci.scpis.items.sorted(by:<) {
            // populate SCPI revenues de la SCI, nets de charges sociales et avant IS
            let yearlyRevenue = scpi.yearlyRevenue(atEndOf: year)
            let name          = scpi.name
            // revenus inscrit en compte courant après prélèvements sociaux et avant IS
            // car dans le cas d'une SCI, le revenu remboursable aux actionnaires c'est le net de charges sociales
            revenues.sciDividends.namedValues.append((name : name,
                                                      value: yearlyRevenue.taxableIrpp.rounded()))
            // populate SCPI sale revenue: produit net de charges sociales et d'impôt sur la plus-value
            // FIXME: vérifier si c'est net où brut dans le cas d'une SCI
            let liquidatedValue = scpi.liquidatedValue(year)
            revenues.scpiSale.namedValues.append((name : name,
                                                  value: liquidatedValue.revenue.rounded()))
        }
        
        // calcul de l'IS de la SCI
        IS = Fiscal.model.companyProfitTaxes.IS(revenues.total)
    }
    
    // MARK: - Methods

    func summaryFiltredNames(with itemSelectionList: ItemSelectionList) -> [String] {
        summary.filtredNames(with : itemSelectionList)
    }
    
    func summaryFiltredValues(with itemSelectionList: ItemSelectionList) -> [Double] {
        summary.filtredValues(with : itemSelectionList)
    }
    
    func print(level: Int = 0) {
        let h = String(repeating: StringCst.header, count: level)
        Swift.print(h + "SCI:    ")
        // revenues
        revenues.print(level: 1)
        // IS de la SCI
        Swift.print(h + StringCst.header + "IS:", IS)
        // net cash flow
        Swift.print(h + StringCst.header + "NET CASH FLOW:", netCashFlow)
    }
}

// MARK: - Société Civile Immobilière (SCI)
struct SCI {
    
    // MARK: - Properties

    var scpis       = ScpiArray(fileNamePrefix: "SCI_")
    var bankAccount = 0.0
    
    // MARK: - Methods

    func print() {
        Swift.print("  SCI:")
        // investissement SCPI
        Swift.print("    SCPI:")
        for scpi in scpis.items { scpi.print() }
        // compte courant
        Swift.print("    compte courant:", bankAccount, "€")
    }
}
