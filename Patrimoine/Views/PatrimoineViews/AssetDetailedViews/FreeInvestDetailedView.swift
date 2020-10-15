//
//  FreeInvestView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 25/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct FreeInvestDetailedView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    
    private var originalItem: FreeInvestement?
    // commun
    @EnvironmentObject var patrimoine: Patrimoin
    @Environment(\.presentationMode) var presentationMode
    @State private var index: Int?
    // à adapter
    @State private var totalValue : Double = 0.0
    @State private var localItem = FreeInvestement(year             : Date.now.year - 1,
                                                   name             : "",
                                                   note             : "",
                                                   type             : .other,
                                                   interestRateType : .contractualRate(fixedRate: 0.0),
                                                   initialValue     : 0,
                                                   initialInterest  : 0)

    var body: some View {
        Form {
            LabeledTextField(label: "Nom", defaultText: "obligatoire", text: $localItem.name)
            LabeledTextEditor(label: "Note", text: $localItem.note)
            // acquisition
            Section(header: Text("TYPE")) {
                TypeInvestEditView(investType: $localItem.type)
            }
            Section(header: Text("INITIALISATION")) {
                YearPicker(title    : "Année d'actualisation",
                           inRange  : Date.now.year - 20...Date.now.year + 100,
                           selection: $localItem.initialState.year)
                AmountEditView(label : "Valeure actualisée",
                               amount: $totalValue)
                    .onChange(of: totalValue) { newValue in
                        localItem.initialState.investment = newValue - localItem.initialState.interest
                    }
                AmountEditView(label: "dont Plus-values",
                               amount: $localItem.initialState.interest)
                    .onChange(of: localItem.initialState.interest) { newValue in
                        localItem.initialState.investment = totalValue - newValue
                    }
            }
            Section(header: Text("RENTABILITE")) {
                InterestRateTypeEditView(rateType: $localItem.interestRateType)
                PercentView(label: "Rendement net d'inflation",
                            percent: localItem.interestRateNet/100.0)
                    .foregroundColor(.secondary)
            }
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .navigationTitle("Invest. Libre")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button(
                action : duplicate,
                label  : { Text("Dupliquer")} )
                .capsuleButtonStyle()
                .disabled((index == nil) || changeOccured()),
            trailing: Button(
                action: applyChanges,
                label: { Text("Sauver") } )
                .capsuleButtonStyle()
                .disabled(!changeOccured())
        )
    }
    
    init(item: FreeInvestement?, patrimoine: Patrimoin) {
        self.originalItem = item
        if let initialItemValue = item {
            // modification d'un élément existant
            _localItem  = State(initialValue: initialItemValue)
            _index      = State(initialValue: patrimoine.assets.freeInvests.items.firstIndex(of: initialItemValue))
            _totalValue = State(initialValue: initialItemValue.initialState.value)
            // specific
        } else {
            // nouvel élément
            index = nil
        }
    }
    
    func duplicate() {
        // générer un nouvel identifiant pour la copie
        localItem.id = UUID()
        localItem.name += "-copie"
        // ajouter la copie
        patrimoine.assets.freeInvests.add(localItem)
        // revenir à l'élement avant duplication
        localItem = originalItem!
    }
    
    // sauvegarder les changements
    func applyChanges() {
        if let index = index {
            // modifier un éléménet existant
            patrimoine.assets.freeInvests.update(with: localItem, at: index)
        } else {
            // créer un nouvel élément
            patrimoine.assets.freeInvests.add(localItem)
        }
        
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()
        
        self.presentationMode.wrappedValue.dismiss()
    }
    
    func changeOccured() -> Bool {
        return localItem != originalItem
    }
}

struct FreeInvestDetailedView_Previews: PreviewProvider {
    static var patrimoine  = Patrimoin()
    
    static var previews: some View {
        return
            Group {
                NavigationView() {
                    FreeInvestDetailedView(item: patrimoine.assets.freeInvests[0], patrimoine: patrimoine)
                        .environmentObject(patrimoine)
                }
                .previewDisplayName("FreeInvestDetailedView")
            }
    }
}
