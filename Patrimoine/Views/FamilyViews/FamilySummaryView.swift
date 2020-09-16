//
//  FamilySummaryView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 31/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct FamilyHeaderView: View {
    var body: some View {
        Section {
            NavigationLink(destination: FamilySummaryView()) {
                Text("Résumé").fontWeight(.bold)
            }
            .isDetailLink(true)
        }
    }
}

struct FamilySummaryView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @State private var cashFlow       : CashFlowLine? = nil
    
    fileprivate func computeCurrentYearCashFlow() {
        simulation.reset(withPatrimoine: patrimoine)
        self.cashFlow = try? CashFlowLine(withYear      : Date.now.year,
                                          withFamily    : self.family,
                                          withPatrimoine: self.patrimoine,
                                          taxableIrppRevenueDelayedFromLastyear : 0)
    }
    
    var body: some View {
        Form {
            FamilySummarySection()
            RevenuSummarySection(cashFlow: cashFlow)
            SciSummarySection(cashFlow: cashFlow)
        }
        .navigationTitle("Résumé")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: computeCurrentYearCashFlow)
        .onDisappear(perform: self.patrimoine.resetFreeInvestementCurrentValue)
    }
}

fileprivate func header(_ trailingString: String) -> some View {
    HStack {
        Text(trailingString)
        Spacer()
        Text("valorisation en \(Date.now.year)")
    }
}

struct FamilySummarySection: View {
    @EnvironmentObject var family: Family
    var body: some View {
        Section(header: Text("MEMBRES")) {
            IntegerView(label   : "Nombre de membres",
                        integer : family.members.count)
            IntegerView(label   : "• Nombre d'adultes",
                        integer : family.nbOfAdults)
            IntegerView(label   : "• Nombre d'enfants",
                        integer : family.nbOfChildren)
        }
    }
}

struct SciSummarySection: View {
    var cashFlow : CashFlowLine?
    
    var body: some View {
        Section(header: header("FISCALITE SCI")) {
            AmountView(label : "IS de la SCI",
                       amount: cashFlow!.sciCashFlowLine.IS)
        }
    }
}

struct RevenuSummarySection: View {
    var cashFlow : CashFlowLine?
    @EnvironmentObject var family: Family
    
    var body: some View {
        if cashFlow == nil {
            Section(header: header("REVENUS DU TRAVAIL")) {
                AmountView(label : "Revenu net de charges sociales et d'assurance (à vivre)",
                           amount: family.income(during: Date.now.year).netIncome)
                AmountView(label : "Revenu imposable à l'IRPP",
                           amount: family.income(during: Date.now.year).taxableIncome)
            }
            Section(header: header("FISCALITE DES REVENUS DU TRAVAIL")) {
                IntegerView(label   : "Quotient familial",
                            integer : Int(family.familyQuotient(during: Date.now.year)))
                AmountView(label : "Montant de l'IRPP",
                           amount: family.irpp(for: Date.now.year))
            }
        } else {
            Section(header: header("REVENUS")) {
                AmountView(label : "Revenu familliale net de charges sociales et d'assurance (à vivre)",
                           amount: cashFlow!.revenues.totalCredited)
                AmountView(label : "Revenu de la SCI net de taxes et d'IS ",
                           amount: cashFlow!.sciCashFlowLine.netCashFlow)
                AmountView(label : "Revenu total net",
                           amount: cashFlow!.sumOfrevenues,
                           weight: .bold)
                AmountView(label : "Revenu imposable à l'IRPP",
                           amount: cashFlow!.revenues.totalTaxableIrpp)
            }
            Section(header: header("FISCALITE FAMILLE")) {
                IntegerView(label   : "Quotient familial",
                            integer : Int(cashFlow!.taxes.familyQuotient))
                // FIXME: donne un impot nul !
                AmountView(label : "Montant de l'IRPP",
                           amount: cashFlow!.taxes.perCategory[.irpp]!.total)
                AmountView(label : "Taxes locales",
                           amount: cashFlow!.taxes.perCategory[.localTaxes]!.total)
                AmountView(label : "Prélevements Sociaux",
                           amount: cashFlow!.taxes.perCategory[.socialTaxes]!.total)
                AmountView(label : "Prélevements totaux",
                           amount: cashFlow!.taxes.total,
                           weight: .bold)
            }
        }
    }
}

struct FamilySummaryView_Previews: PreviewProvider {
    static var family     = Family()
    static var patrimoine = Patrimoin()
    
    static var previews: some View {
        FamilySummaryView()
            .environmentObject(family)
            .environmentObject(patrimoine)
    }
}
