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
    @EnvironmentObject var family    : Family
    @EnvironmentObject var patrimoine: Patrimoin
    @State private var cashFlow      : CashFlowLine? = nil
    
    var body: some View {
        List {
            Section(header: Text("MEMBRES")) {
                IntegerView(label   : "Nombre de membres",
                            integer : family.members.count,
                            weight  : .bold)
                IntegerView(label   : "• Nombre d'adultes",
                            integer : family.nbOfAdults,
                            weight  : .bold)
                IntegerView(label   : "• Nombre d'enfants",
                            integer : family.nbOfChildren,
                            weight  : .bold)
            }
            if cashFlow == nil {
                Section(header: header("REVENUS DU TRAVAIL")) {
                    AmountView(label : "Revenu net de charges sociales",
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
                    AmountView(label : "Revenu familliale net de charges sociales",
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
                    AmountView(label : "Montant de l'IRPP",
                               amount: cashFlow!.taxes.irpp)
                    AmountView(label : "Taxes locales",
                               amount: cashFlow!.taxes.localTaxes.total)
                    AmountView(label : "Prélevements Sociaux",
                               amount: cashFlow!.taxes.socialTaxes.total)
                    AmountView(label : "Prélevements totaux",
                               amount: cashFlow!.taxes.total,
                               weight: .bold)
                }
                Section(header: header("FISCALITE SCI")) {
                    AmountView(label : "IS de la SCI",
                               amount: cashFlow!.sciCashFlowLine.IS,
                               weight: .bold)
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Text("Résumé"), displayMode: .inline)
        .onAppear(perform:{
            self.cashFlow = try? CashFlowLine(withYear      : Date.now.year,
                                              withFamily    : self.family,
                                              withPatrimoine: self.patrimoine,
                                              taxableIrppRevenueDelayedFromLastyear : 0)
        })
        .onDisappear(perform: { self.patrimoine.resetFreeInvestementCurrentValue() })
    }
    
    func header(_ trailingString: String) -> some View {
        HStack {
            Text(trailingString)
            Spacer()
            Text("valorisation en \(Date.now.year)")
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
