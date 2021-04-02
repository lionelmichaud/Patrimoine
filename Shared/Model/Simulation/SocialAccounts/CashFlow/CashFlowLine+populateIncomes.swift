//
//  CashFlowLine+populateIncomes.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

extension CashFlowLine {
    /// Populate Ages and Work incomes
    /// - Parameter family: de la famille
    mutating func populateIncomes(of family: Family) {
        var totalPensionDiscount = 0.0
        
        // pour chaque membre de la famille
        for person in family.members.sorted(by:>) {
            // populate ages of family members
            let name = person.name.familyName! + " " + person.name.givenName!
            ages.persons.append((name: name, age: person.age(atEndOf: year)))
            // populate work, pension and unemployement incomes of family members
            if let adult = person as? Adult {
                /// revenus du travail
                let workIncome = adult.workIncome(during: year)
                // revenus du travail inscrit en compte avant IRPP (net charges sociales, de dépenses de mutuelle ou d'assurance perte d'emploi)
                revenues.perCategory[.workIncomes]?.credits.namedValues
                    .append((name: name,
                             value: workIncome.net.rounded()))
                // part des revenus du travail inscrite en compte qui est imposable à l'IRPP
                revenues.perCategory[.workIncomes]?.taxablesIrpp.namedValues
                    .append((name: name,
                             value: workIncome.taxableIrpp.rounded()))
                
                /// pension de retraite
                let pension  = adult.pension(during: year)
                // pension inscrit en compte avant IRPP (net de charges sociales)
                revenues.perCategory[.pensions]?.credits.namedValues
                    .append((name: name,
                             value: pension.net.rounded()))
                // part de la pension inscrite en compte qui est imposable à l'IRPP
                let relicat = Fiscal.model.pensionTaxes.model.maxRebate - totalPensionDiscount
                var discount = pension.net - pension.taxable
                if relicat >= discount {
                    // l'abattement est suffisant pour cette personne
                    revenues.perCategory[.pensions]?.taxablesIrpp.namedValues
                        .append((name: name,
                                 value: pension.taxable.rounded()))
                } else {
                    discount = relicat
                    revenues.perCategory[.pensions]?.taxablesIrpp.namedValues
                        .append((name: name,
                                 value: (pension.net - discount).rounded()))
                }
                totalPensionDiscount += discount
                
                /// indemnité de licenciement
                let compensation = adult.layoffCompensation(during: year)
                revenues.perCategory[.layoffCompensation]?.credits.namedValues
                    .append((name: name,
                             value: compensation.net.rounded()))
                revenues.perCategory[.layoffCompensation]?.taxablesIrpp.namedValues
                    .append((name: name,
                             value: compensation.taxable.rounded()))
                /// allocation chomage
                let alocation = adult.unemployementAllocation(during: year)
                revenues.perCategory[.unemployAlloc]?.credits.namedValues
                    .append((name: name, value: alocation.net.rounded()))
                revenues.perCategory[.unemployAlloc]?.taxablesIrpp.namedValues
                    .append((name: name,
                             value: alocation.taxable.rounded()))
            }
        }
    }
}
