//
//  FreeInvestView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 25/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Combine

struct FreeInvestDetailedView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState

    var item: FreeInvestement?
    // commun
    @EnvironmentObject var patrimoine: Patrimoine
    @Environment(\.presentationMode) var presentationMode
    @State private var index: Int?
    // à adapter
    @State private var initialName     : String = ""
    @State private var initialrate     : Double = 0.0
    @State private var initialYear     : Int    = Date.now.year
    @State private var initialInterest : Double = 0.0
    @State private var initialValue    : Double = 0.0
    @State private var investType      : InvestementType = .other
    
    var body: some View {
        Form {
            HStack{
                Text("Nom")
                    .frame(width: 70, alignment: .leading)
                TextField("obligatoire", text: $initialName)
            }
            // acquisition
            Section(header: Text("TYPE")) {
                TypeInvestEditView(investType: $investType)
            }
            Section(header: Text("INITIALISATION")) {
                YearPicker(title: "Année initiale",
                           inRange: Date.now.year - 20...Date.now.year + 100,
                           selection: $initialYear)
                AmountEditView(label: "Valeure initiale",
                               amount: $initialValue)
                AmountEditView(label: "Plus-values initiales",
                               amount: $initialInterest)
            }
            Section(header: Text("RENTABILITE")) {
                PercentEditView(label: "Rendement",
                                percent: $initialrate)
            }
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .avoidKeyboard()
        .navigationBarTitle(Text("Invest. Libre"), displayMode: .inline)
        .navigationBarItems(
            leading: Button(
                action : duplicate,
                label  : { Text("Dupliquer")} )
                    .disabled(index == nil),
            trailing: Button(
                action: applyChanges,
                label: { Text("Sauver") } )
                .disabled(!changeOccured())
        )
    }
    
    init(item: FreeInvestement?, patrimoine: Patrimoine) {
        self.item = item
        if let initialItemValue = item {
            // modification d'un élément existant
            _index     = State(initialValue: patrimoine.assets.freeInvests.items.firstIndex(of: initialItemValue))
            // specific
            _initialName     = State(initialValue: initialItemValue.name)
            _investType      = State(initialValue: initialItemValue.type)
            _initialrate     = State(initialValue: initialItemValue.interestRate)
            _initialYear     = State(initialValue: initialItemValue.initialState.year)
            _initialInterest = State(initialValue: initialItemValue.initialState.interest)
            _initialValue    = State(initialValue: initialItemValue.initialState.value)
        } else {
            // nouvel élément
            index = nil
        }
    }
    
    func duplicate() {
        if index != nil {
            let localItem = FreeInvestement(year            : initialYear,
                                            name            : initialName,
                                            type            : investType,
                                            rate            : initialrate,
                                            initialValue    : initialValue,
                                            initialInterest : initialInterest)
            patrimoine.assets.freeInvests.add(localItem)
        }
    }
    
    // sauvegarder les changements
    func applyChanges() {
        // construire l'item nouveau ou modifier à partir des valeurs saisies
        let localItem = FreeInvestement(year            : initialYear,
                                        name            : initialName,
                                        type            : investType,
                                        rate            : initialrate,
                                        initialValue    : initialValue,
                                        initialInterest : initialInterest)
        
        if let index = index {
            // modifier un éléménet existant
            patrimoine.assets.freeInvests.update(with: localItem, at: index)
        } else {
            // créer un nouvel élément
            patrimoine.assets.freeInvests.add(localItem)
        }
        
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.simulationViewState.selectedItem = nil

        self.presentationMode.wrappedValue.dismiss()
    }
    
    func changeOccured() -> Bool {
        return true // localItem != item
    }
}

struct FreeInvestDetailedView_Previews: PreviewProvider {
    static var patrimoine  = Patrimoine()

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
