//
//  PatrimoineSummaryView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 31/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct PatrimoineSummaryView: View {
    @EnvironmentObject var patrimoine: Patrimoin
    @EnvironmentObject var uiState   : UIState
    let minDate = Date.now.year
    let maxDate = Date.now.year + 40
    
    var body: some View {
        VStack {
            // évaluation annuelle du patrimoine
            HStack {
                Text("Evaluation en ") + Text(String(Int(uiState.expenseViewState.evalDate)))
                Slider(value : $uiState.expenseViewState.evalDate,
                       in    : minDate.double() ... maxDate.double(),
                       step  : 1,
                       onEditingChanged: {_ in
                })
            }
            .padding(.horizontal)
            
            // tableau
            Form {
                Section(header: header("", year: Int(uiState.expenseViewState.evalDate))) {
                    HStack {
                        Text("Actif Net").fontWeight(.bold)
                        Spacer()
                        Text(patrimoine.value(atEndOf: Int(uiState.expenseViewState.evalDate)).euroString)
                    }
                }
                .listRowBackground(ListTheme.rowsBaseColor)
                Section(header: header("ACTIF", year: Int(uiState.expenseViewState.evalDate))) {
                    Group {
                        // (0) Immobilier
                        ListTableRowView(label       : "Immobilier",
                                         value       : patrimoine.assets.realEstates.value(atEndOf: Int(uiState.expenseViewState.evalDate)) +
                                            patrimoine.assets.scpis.value(atEndOf: Int(uiState.expenseViewState.evalDate)),
                                         indentLevel : 0,
                                         header      : true)
                        //      (1) Immeuble
                        ListTableRowView(label       : "Immeuble",
                                         value       : patrimoine.assets.realEstates.currentValue,
                                         indentLevel : 1,
                                         header      : true)
                        ForEach(patrimoine.assets.realEstates.items) { item in
                            ListTableRowView(label       : item.name,
                                             value       : item.value(atEndOf: Int(self.uiState.expenseViewState.evalDate)),
                                             indentLevel : 2,
                                             header      : false)
                        }
                        //      (1) SCPI
                        ListTableRowView(label       : "SCPI",
                                         value       : patrimoine.assets.scpis.currentValue,
                                         indentLevel : 1,
                                         header      : true)
                        ForEach(patrimoine.assets.scpis.items) { item in
                            ListTableRowView(label       : item.name,
                                             value       : item.value(atEndOf: Int(self.uiState.expenseViewState.evalDate)),
                                             indentLevel : 2,
                                             header      : false)
                        }
                    }
                    Group {
                        // (0) Financier
                        ListTableRowView(label       : "Financier",
                                         value       : patrimoine.assets.periodicInvests.value(atEndOf: Int(uiState.expenseViewState.evalDate)) +
                                            patrimoine.assets.freeInvests.value(atEndOf: Int(uiState.expenseViewState.evalDate)),
                                         indentLevel : 0,
                                         header      : true)
                        //      (1) Invest Périodique
                        ListTableRowView(label       : "Invest Périodique",
                                         value       : patrimoine.assets.periodicInvests.value(atEndOf: Int(uiState.expenseViewState.evalDate)),
                                         indentLevel : 1,
                                         header      : true)
                        ForEach(patrimoine.assets.periodicInvests.items) { item in
                            ListTableRowView(label       : item.name,
                                             value       : item.value(atEndOf: Int(self.uiState.expenseViewState.evalDate)),
                                             indentLevel : 2,
                                             header      : false)
                        }
                        //      (1) Investissement Libre
                        ListTableRowView(label       : "Investissement Libre",
                                         value       : patrimoine.assets.freeInvests.value(atEndOf: Int(uiState.expenseViewState.evalDate)),
                                         indentLevel : 1,
                                         header      : true)
                        ForEach(patrimoine.assets.freeInvests.items) { item in
                            ListTableRowView(label       : item.name,
                                             value       : item.value(atEndOf: Int(self.uiState.expenseViewState.evalDate)),
                                             indentLevel : 2,
                                             header      : false)
                        }
                    }
                    Group {
                        // (0) SCI
                        ListTableRowView(label       : "SCI",
                                         value       : patrimoine.assets.sci.scpis.value(atEndOf       : Int(uiState.expenseViewState.evalDate)) +
                                            patrimoine.assets.sci.bankAccount,
                                         indentLevel : 0,
                                         header      : true)
                        //      (1) SCPI
                        ListTableRowView(label       : "SCPI",
                                         value       : patrimoine.assets.sci.scpis.value(atEndOf       : Int(uiState.expenseViewState.evalDate)),
                                         indentLevel : 1,
                                         header      : true)
                        ForEach(patrimoine.assets.sci.scpis.items) { item in
                            ListTableRowView(label       : item.name,
                                             value       : item.value(atEndOf: Int(self.uiState.expenseViewState.evalDate)),
                                             indentLevel : 2,
                                             header      : false)
                        }
                        
                    }
                }
                Section(header: header("PASSIF", year: Int(uiState.expenseViewState.evalDate))) {
                    Group {
                        // (0) Emprunts
                        ListTableRowView(label       : "Emprunt",
                                         value       : patrimoine.liabilities.loans.value(atEndOf: Int(uiState.expenseViewState.evalDate)),
                                         indentLevel : 0,
                                         header      : true)
                        ForEach(patrimoine.liabilities.loans.items) { item in
                            ListTableRowView(label       : item.name,
                                             value       : item.value(atEndOf: Int(self.uiState.expenseViewState.evalDate)),
                                             indentLevel : 2,
                                             header      : false)
                        }
                    }
                    
                    Group {
                        // (0) Dettes
                        ListTableRowView(label       : "Dette",
                                         value       : patrimoine.liabilities.debts.value(atEndOf: Int(uiState.expenseViewState.evalDate)),
                                         indentLevel : 0,
                                         header      : true)
                        ForEach(patrimoine.liabilities.debts.items) { item in
                            ListTableRowView(label       : item.name,
                                             value       : item.value(atEndOf: Int(self.uiState.expenseViewState.evalDate)),
                                             indentLevel : 2,
                                             header      : false)
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Text("Résumé"), displayMode: .inline)
        }
    }
    
    func header(_ trailingString: String, year: Int) -> some View {
        HStack {
            Text(trailingString)
            Spacer()
            Text("valorisation à fin \(year)")
        }
    }
}

struct PatrimoineSummaryView_Previews: PreviewProvider {
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var uiState    = UIState()
    
    static var previews: some View {
        PatrimoineSummaryView()
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(uiState)
    }
}
