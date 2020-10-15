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
    @State private var initialName      : String = ""
    @State private var initialNote      : String = ""
    @State private var investType       : InvestementType  = .other
    @State private var initialRateType  : InterestRateType = .contractualRate(fixedRate: 0.0)
    @State private var initialYear      : Int    = Date.now.year
    @State private var initialInterest  : Double = 0.0
    @State private var initialValue     : Double = 0.0

    var body: some View {
        Form {
            LabeledTextField(label: "Nom", defaultText: "obligatoire", text: $initialName)
            LabeledTextEditor(label: "Note", text: $initialNote)
            // acquisition
            Section(header: Text("TYPE")) {
                TypeInvestEditView(investType: $investType)
            }
            Section(header: Text("INITIALISATION")) {
                YearPicker(title: "Année d'actualisation",
                           inRange: Date.now.year - 20...Date.now.year + 100,
                           selection: $initialYear)
                AmountEditView(label: "Valeure actualisée",
                               amount: $initialValue)
                AmountEditView(label: "dont Plus-values",
                               amount: $initialInterest)
            }
            Section(header: Text("RENTABILITE")) {
                InterestRateTypeEditView(rateType: $initialRateType)
            }
//            Section(header: Text("RENTABILITE")) {
//                PercentView(label: "Rendement",
//                            percent: localItem.interestRate)
//            }
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
            _index = State(initialValue: patrimoine.assets.freeInvests.items.firstIndex(of: initialItemValue))
            // specific
            _initialName     = State(initialValue: initialItemValue.name)
            _initialNote     = State(initialValue: initialItemValue.note)
            _investType      = State(initialValue: initialItemValue.type)
            _initialRateType = State(initialValue: initialItemValue.interestRateType)
            _initialYear     = State(initialValue: initialItemValue.initialState.year)
            _initialInterest = State(initialValue: initialItemValue.initialState.interest)
            _initialValue    = State(initialValue: initialItemValue.initialState.value)
        } else {
            // nouvel élément
            index = nil
        }
    }
    
    func duplicate() {
        let copyOfItemWithNewId = FreeInvestement(year             : initialYear,
                                                  name             : initialName + "-copie",
                                                  note             : initialNote,
                                                  type             : investType,
                                                  interestRateType : initialRateType,
                                                  initialValue     : initialValue,
                                                  initialInterest  : initialInterest)
        patrimoine.assets.freeInvests.add(copyOfItemWithNewId)
        // revenir à l'élement avant duplication
    }
    
    // sauvegarder les changements
    func applyChanges() {
        // construire l'item nouveau ou modifier à partir des valeurs saisies
        let localItem = FreeInvestement(year             : initialYear,
                                        name             : initialName,
                                        note             : initialNote,
                                        type             : investType,
                                        interestRateType : initialRateType,
                                        initialValue     : initialValue,
                                        initialInterest  : initialInterest)
        
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
        return true // localItem != item
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
