//
//  DebtDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 30/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct DebtDetailedView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState

    var item: Debt?
    // commun
    @EnvironmentObject var patrimoine: Patrimoin
    @Environment(\.presentationMode) var presentationMode
    @State private var alertData: AlertData? = nil
    @State private var index: Int?
    
    // à adapter
    @State private var localItem = Debt(name: "", value: 0)
    var body: some View {
        Form {
            HStack{
                Text("Nom")
                    .frame(width: 70, alignment: .leading)
                TextField("obligatoire", text: $localItem.name)
            }
            // acquisition
            Section(header: Text("CARCTERISTIQUES")) {
                AmountEditView(label  : "Montant emprunté",
                               amount : $localItem.value)
            }
        }
        .alert(item: $alertData) { alertData in
            Alert(title: Text(alertData.title),
                  message: Text(alertData.message))
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
            //.onAppear(perform: onAppear)
            .navigationBarTitle(Text("Dette"), displayMode: .inline)
            .navigationBarItems(
                trailing: Button(
                    action: applyChanges,
                    label: {
                        Text("Sauver")
                } )
                    .disabled(!changeOccured())
        )
    }

    init(item: Debt?, patrimoine: Patrimoin) {
        self.item = item
        if let initialItemValue = item {
            // modification d'un élément existant
            _localItem = State(initialValue: initialItemValue)
            _index     = State(initialValue: patrimoine.liabilities.debts.items.firstIndex(of: initialItemValue))
            // specific
        } else {
            index = nil
        }
    }
    
    // sauvegarder les changements
    func applyChanges() {
        guard isValid() else {
            return
        }
        if let index = index {
            // modifier un éléménet existant
            patrimoine.liabilities.debts.update(with: localItem, at: index)
        } else {
            // créer un nouvel élément
            patrimoine.liabilities.debts.add(localItem)
        }
        
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.simulationViewState.selectedItem = nil

        self.presentationMode.wrappedValue.dismiss()
    }
    
    func changeOccured() -> Bool {
        return localItem != item
    }
    
    func isValid() -> Bool {
        if localItem.value > 0 {
            self.alertData = AlertData(title: "Erreur",
                                       message: "Le montant de la dette doit être négatif")
            return false
        } else {
            return true
        }
    }
}

struct DebtDetailedView_Previews: PreviewProvider {
    static var patrimoine  = Patrimoin()

    static var previews: some View {
        return
            NavigationView() {
                DebtDetailedView(item: patrimoine.liabilities.debts[0],
                                 patrimoine: patrimoine)
                    .environmentObject(patrimoine)
            }
            .previewDisplayName("DebtDetailedView")
    }
}
