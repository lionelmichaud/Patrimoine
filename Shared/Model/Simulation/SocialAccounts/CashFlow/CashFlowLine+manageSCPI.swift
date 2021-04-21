//
//  CashFlowLine+manageSCPI.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

extension CashFlowLine {
    /// Populate produit de vente, dividendes, taxes sociales des SCPI hors de la SCI
    /// - Note:
    ///  - le produit de la vente se répartit entre UF et NP en cas de démembrement
    ///  - le produit de la vente est réinvesti dans des actifs détenus par le(s) récipiendaire(s)
    ///  - il ne doit donc pas être incorporés au NetCashFlow de fin d'année à ré-investir en fin d'année
    /// - Parameters:
    ///   - patrimoine: patrimoine
    ///   - adultsName: des adultes
    mutating func manageScpiRevenues(of patrimoine  : Patrimoin,
                                     for adultsName : [String]) {
        for scpi in patrimoine.assets.scpis.items.sorted(by:<)
        where scpi.isPartOfPatrimoine(of: adultsName) {
            let name = scpi.name
            
            /// Revenus
            if scpi.providesRevenue(to: adultsName) {
                // populate SCPI revenues and social taxes
                let yearlyRevenue = scpi.yearlyRevenue(during: year)
                // dividendes inscrit en compte courant avant prélèvements sociaux et IRPP
                revenues.perCategory[.scpis]?.credits.namedValues
                    .append((name: name,
                             value: yearlyRevenue.revenue.rounded()))
                // part des dividendes inscrit en compte courant imposable à l'IRPP
                revenues.perCategory[.scpis]?.taxablesIrpp.namedValues
                    .append((name: name,
                             value: yearlyRevenue.taxableIrpp.rounded()))
                // prélèvements sociaux payés sur les dividendes de SCPI
                taxes.perCategory[.socialTaxes]?.namedValues
                    .append((name: name,
                             value: yearlyRevenue.socialTaxes.rounded()))
            }
            
            /// Vente
            // le produit de la vente se répartit entre UF et NP si démembrement
            // populate SCPI sale revenue: produit de vente net de charges sociales et d'impôt sur la plus-value
            // le crédit se fait au début de l'année qui suit la vente
            let liquidatedValue = scpi.liquidatedValue(year - 1)
            revenues.perCategory[.scpiSale]?.credits.namedValues
                .append((name: name,
                         value: liquidatedValue.netRevenue.rounded()))
            // créditer le produit de la vente sur les comptes des personnes
            // en fonction de leur part de propriété respective
            let ownedSaleValues = scpi.ownedValues(ofValue          : liquidatedValue.netRevenue,
                                                   atEndOf          : year,
                                                   evaluationMethod : .patrimoine)
            
            let netCashFlowManager = NetCashFlowManager()
            netCashFlowManager.investCapital(ownedCapitals : ownedSaleValues,
                                             in            : patrimoine,
                                             atEndOf       : year)
        }
    }
}
