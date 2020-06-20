//
//  PeriodicInvestDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 25/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct PeriodicInvestDetailedView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState

    var item: PeriodicInvestement?
    // commun
    @EnvironmentObject var patrimoine: Patrimoine
    @Environment(\.presentationMode) var presentationMode
    @State private var index: Int?
    // à adapter
    @State private var localItem = PeriodicInvestement(name      : "",
                                                       type      : .other,
                                                       firstYear : Date.now.year,
                                                       lastYear  : Date.now.year + 100,
                                                       rate      : 0)
    
    var body: some View {
        Form {
            HStack{
                Text("Nom")
                    .frame(width: 70, alignment: .leading)
                TextField("obligatoire", text: $localItem.name)
            }
            // acquisition
            Section(header: Text("TYPE")) {
                TypeInvestEditView(investType: $localItem.type)
                AmountEditView(label: "Versement annuel",
                               amount: $localItem.yearlyPayement)
            }
            Section(header: Text("INITIALISATION")) {
                YearPicker(title: "Année de départ",
                           inRange: Date.now.year - 20...Date.now.year + 100,
                           selection: $localItem.firstYear)
                AmountEditView(label: "Valeure initiale",
                               amount: $localItem.initialValue)
                AmountEditView(label: "Intérêts initiaux",
                               amount: $localItem.initialInterest)
            }
            Section(header: Text("LIQUIDATION")) {
                YearPicker(title: "Année de liquidation",
                           inRange: localItem.firstYear...localItem.firstYear + 100,
                           selection: $localItem.lastYear)
            }
            Section(header: Text("RENTABILITE")) {
                PercentEditView(label: "Rendement",
                                percent: $localItem.interestRate)
            }
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .avoidKeyboard()
        .navigationBarTitle(Text("Invest. Périodique"), displayMode: .inline)
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
    
    init(item: PeriodicInvestement?, patrimoine: Patrimoine) {
        self.item = item
        if let initialItemValue = item {
            // modification d'un élément existant
            _localItem = State(initialValue: initialItemValue)
            _index     = State(initialValue: patrimoine.assets.periodicInvests.items.firstIndex(of: initialItemValue))
            // specific
        } else {
            index = nil
        }
    }
    
    func duplicate() {
        if index != nil {
            patrimoine.assets.periodicInvests.add(localItem)
        }
    }
    
    // sauvegarder les changements
    func applyChanges() {
        if let index = index {
            // modifier un éléménet existant
            patrimoine.assets.periodicInvests.update(with: localItem, at: index)
        } else {
            // créer un nouvel élément
            patrimoine.assets.periodicInvests.add(localItem)
        }
        
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.simulationViewState.selectedItem = nil

        self.presentationMode.wrappedValue.dismiss()
    }
    
    func changeOccured() -> Bool {
        return localItem != item
    }
}

struct PeriodicInvestDetailedView_Previews: PreviewProvider {
    static var patrimoine  = Patrimoine()

    static var previews: some View {
        return
            Group {
                NavigationView() {
                    PeriodicInvestDetailedView(item: patrimoine.assets.periodicInvests[0], patrimoine: patrimoine)
                        .environmentObject(patrimoine)
                }
                .previewDisplayName("PeriodicInvestDetailedView")

        }
    }
}
