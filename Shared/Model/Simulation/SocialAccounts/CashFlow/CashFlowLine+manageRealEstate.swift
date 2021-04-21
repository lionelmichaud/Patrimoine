//
//  CashFlowLine+manageRealEstate.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

extension CashFlowLine {
    /// Populate loyers, produit de la vente et impots locaux des biens immobiliers
    /// - Note:
    ///  - le produit de la vente se répartit entre UF et NP en cas de démembrement
    ///  - le produit de la vente est réinvesti dans des actifs détenus par le(s) récipiendaire(s)
    ///  - il ne doit donc pas être incorporés au NetCashFlow de fin d'année à ré-investir en fin d'année
    /// - Parameters:
    ///   - patrimoine: patrimoine
    ///   - adultsName: des adultes
    mutating func manageRealEstateRevenues(of patrimoine  : Patrimoin,
                                           for adultsName : [String]) {
        for realEstate in patrimoine.assets.realEstates.items .sorted(by:<)
        where realEstate.isPartOfPatrimoine(of: adultsName) {
            let name = realEstate.name
            
            /// Revenus
            // les revenus ne reviennent qu'aux UF ou PP, idem pour les impôts locaux
            if realEstate.providesRevenue(to: adultsName) {
                // populate real estate rent revenues and social taxes
                let yearlyRent = realEstate.yearlyRent(during: year)
                // loyers inscrit en compte courant avant prélèvements sociaux et IRPP
                revenues.perCategory[.realEstateRents]?.credits.namedValues
                    .append((name: name,
                             value: yearlyRent.revenue.rounded()))
                // part des loyers inscrit en compte courant imposable à l'IRPP - idem ci-dessus car même base
                revenues.perCategory[.realEstateRents]?.taxablesIrpp.namedValues
                    .append((name: name,
                             value: yearlyRent.taxableIrpp.rounded()))
                // prélèvements sociaux payés sur le loyer
                taxes.perCategory[.socialTaxes]?.namedValues
                    .append((name : name,
                             value: yearlyRent.socialTaxes.rounded()))
                
                // impôts locaux
                let yearlyLocaltaxes = realEstate.yearlyLocalTaxes(during: year)
                taxes.perCategory[.localTaxes]?.namedValues
                    .append((name: name,
                             value: yearlyLocaltaxes.rounded()))
            }
            
            /// Vente
            // le produit de la vente se répartit entre UF et NP si démembrement
            if realEstate.isPartOfPatrimoine(of: adultsName) {
                // produit de la vente inscrit en compte courant:
                //    produit net de charges sociales et d'impôt sur la plus-value
                // le crédit se fait au début de l'année qui suit la vente
                let liquidatedValue = realEstate.liquidatedValue(year - 1)
                revenues.perCategory[.realEstateSale]?.credits.namedValues
                    .append((name: name,
                             value: liquidatedValue.netRevenue.rounded()))
                // créditer le produit de la vente sur les comptes des personnes
                // en fonction de leur part de propriété respective
                let ownedSaleValues = realEstate.ownedValues(ofValue          : liquidatedValue.netRevenue,
                                                             atEndOf          : year,
                                                             evaluationMethod : .patrimoine)
                let netCashFlowManager = NetCashFlowManager()
                netCashFlowManager.investCapital(ownedCapitals : ownedSaleValues,
                                                 in            : patrimoine,
                                                 atEndOf       : year)
            }
        }
    }
}
