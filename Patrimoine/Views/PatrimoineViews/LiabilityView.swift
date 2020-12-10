//
//  LiabilityView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct LiabilityView: View {
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState
    
    var body: some View {
        Section {
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.liabViewState.colapseLiab,
                                label       : "Passif",
                                value       : patrimoine.liabilities.value(atEndOf: Date.now.year),
                                indentLevel : 0,
                                header      : true)

            if !uiState.patrimoineViewState.liabViewState.colapseLiab {
                    LoanView()
                    DebtView()
            }
        }
    }
}

struct LoanView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState

    func removeItems(at offsets: IndexSet) {
        patrimoine.liabilities.loans.delete(at: offsets)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        patrimoine.liabilities.loans.move(from: source, to: destination)
    }
    
    var body: some View {
        Group {
            // label
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.liabViewState.colapseEmpruntlist,
                                label       : "Emprunt",
                                value       : patrimoine.liabilities.loans.value(atEndOf: Date.now.year),
                                indentLevel : 1,
                                header      : true)
            
            // items
            if !uiState.patrimoineViewState.liabViewState.colapseEmpruntlist {
                // ajout d'un nouvel item à la liste
                NavigationLink(destination: LoanDetailedView(item       : nil,
                                                             family     : family,
                                                             patrimoine : patrimoine)) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                        Text("Ajouter un élément...")
                    }
                    .foregroundColor(.accentColor)
                }
                
                // liste des items
                ForEach(patrimoine.liabilities.loans.items) { item in
                    NavigationLink(destination: LoanDetailedView(item       : item,
                                                                 family     : family,
                                                                 patrimoine : self.patrimoine)) {
                        LabeledValueRowView(colapse     : self.$uiState.patrimoineViewState.liabViewState.colapseEmpruntlist,
                                            label       : item.name,
                                            value       : item.value(atEndOf: Date.now.year),
                                            indentLevel : 3,
                                            header      : false)
                    }
                    .isDetailLink(true)
                }
                .onDelete(perform: removeItems)
                .onMove(perform: move)
            }
        }
    }
}

struct DebtView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState

    func removeItems(at offsets: IndexSet) {
        patrimoine.liabilities.debts.delete(at: offsets)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        patrimoine.liabilities.debts.move(from: source, to: destination)
    }
    
    var body: some View {
        Section {
            // label
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.liabViewState.colapseDetteListe,
                                label       : "Dette",
                                value       : patrimoine.liabilities.debts.value(atEndOf: Date.now.year),
                                indentLevel : 1,
                                header      : true)
            
            // items
            if !uiState.patrimoineViewState.liabViewState.colapseDetteListe {
                // ajout d'un nouvel item à la liste
                NavigationLink(destination: DebtDetailedView(item       : nil,
                                                             family     : family,
                                                             patrimoine : patrimoine)) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                        Text("Ajouter un élément...")
                    }
                    .foregroundColor(.accentColor)
                }
                
                // liste des items
                ForEach(patrimoine.liabilities.debts.items) { item in
                    NavigationLink(destination: DebtDetailedView(item       : item,
                                                                 family     : family,
                                                                 patrimoine : self.patrimoine)) {
                        LabeledValueRowView(colapse     : self.$uiState.patrimoineViewState.liabViewState.colapseDetteListe,
                                            label       : item.name,
                                            value       : item.value(atEndOf: Date.now.year),
                                            indentLevel : 3,
                                            header      : false)
                    }
                    .isDetailLink(true)
                }
                .onDelete(perform: removeItems)
                .onMove(perform: move)
            }
        }
    }
}

struct LiabilityView_Previews: PreviewProvider {
    static var patrimoine = Patrimoin()
    static var uiState    = UIState()

    static var previews: some View {
        NavigationView {
            List {
                LiabilityView()
                    .environmentObject(patrimoine)
                    .environmentObject(uiState)
                    .previewDisplayName("LiabilityView")
            }
        }
    }
}
