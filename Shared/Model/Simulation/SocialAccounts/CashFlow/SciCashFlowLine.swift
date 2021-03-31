//
//  SciCashFlowLine.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 19/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// ligne anuelle de cash flow de la SCI
struct SciCashFlowLine {
    
    // MARK: - Nested types
    
    // revenus de la SCI
    struct Revenues {
        
        // MARK: - Properties
        
        // dividendes des SCPI de la SCI : nets de charges sociales et avant IS
        var sciDividends = NamedValueTable(tableName: "SCI-REVENUS DE SCPI")
        // ventes des SCPI de la SCI: produit net de charges sociales et d'impôt sur la plus-value
        var scpiSale     = NamedValueTable(tableName: "SCI-VENTES SCPI")
        // total de tous les revenus nets de l'année: loyers + ventes de la SCI
        var total: Double { sciDividends.total + scpiSale.total }
        // total de tous les revenus imposables à l'IS de l'année: loyers + plus-values de la SCI
        // tableau résumé des noms
        var namesArray: [String] {
            ["SCI-" + sciDividends.tableName, "SCI-" + scpiSale.tableName]
        }
        // tableau résumé des valeurs
        var valuesArray: [Double] {
            [sciDividends.total, scpiSale.total]
        }
        // tableau détaillé des noms
        var namesFlatArray: [String] {
            sciDividends.namesArray.map {$0 + "(Revenu)"} + scpiSale.namesArray.map {$0 + "(Vente)"}
        }
        // tableau détaillé des valeurs
        var valuesFlatArray: [Double] {
            sciDividends.valuesArray + scpiSale.valuesArray
        }
        
        // MARK: - Methods
        
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
    var namesFlatArray: [String] {
        revenues.namesFlatArray + ["SCI-IS"]
    }
    // tableau détaillé des valeurs
    var valuesFlatArray: [Double] {
        revenues.valuesFlatArray + [-IS]
    }
    
    var summary: NamedValueTable {
        var table = NamedValueTable(tableName: "SCI")
        table.namedValues.append((name  : "Revenu SCI",
                                  value : netCashFlow))
        return table
    }
    
    // MARK: - Initializers
    
    init(withYear year  : Int,
         for adultsName : [String],
         withSCI sci    : SCI) {
        self.year = year
        
        // populate produit de vente, dividendes des SCPI
        
        // pour chaque SCPI
        for scpi in sci.scpis.items.sorted(by:<)
        where scpi.isPartOfPatrimoine(of: adultsName) {
            let name = scpi.name
            // FIXME: Ca ne marche pas comme ca. C'est toute la SCI dont il faut géréer les droit de propriété. Pas chaque SCPI individuellement.
            
            /// Revenus
            if scpi.providesRevenue(to: adultsName) {
                // populate SCPI revenues de la SCI, nets de charges sociales et avant IS
                let yearlyRevenue = scpi.yearlyRevenue(during: year)
                // revenus inscrit en compte courant après prélèvements sociaux et avant IS
                // car dans le cas d'une SCI, le revenu remboursable aux actionnaires c'est le net de charges sociales
                revenues.sciDividends.namedValues
                    .append((name : name,
                             value: yearlyRevenue.taxableIrpp.rounded()))
            }
            
            /// Vente
            // le produit de la vente se répartit entre UF et NP si démembrement
            // les produits de la vente ne reviennent qu'aux PP ou NP
            // FIXME: Ca ne marche pas comme ca. C'est toute la SCI dont il faut géréer les droit de propriété. Pas chaque SCPI individuellement.
            // populate SCPI sale revenue: produit net de charges sociales et d'impôt sur la plus-value
            // FIXME: vérifier si c'est net où brut dans le cas d'une SCI
            let liquidatedValue = scpi.liquidatedValue(year)
            revenues.scpiSale.namedValues
                .append((name : name,
                         value: liquidatedValue.netRevenue.rounded()))
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
