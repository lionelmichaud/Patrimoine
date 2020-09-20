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
    private var originalItem: Debt?
    // commun
    @EnvironmentObject var patrimoine: Patrimoin
    @Environment(\.presentationMode) var presentationMode
    @State private var alertItem: AlertItem?
    @State private var index: Int?
    
    // à adapter
    @State private var localItem = Debt(name: "", note: "", value: 0)
    var body: some View {
        Form {
            LabeledTextField(label: "Nom", defaultText: "obligatoire", text: $localItem.name)
            LabeledTextEditor(label: "Note", text: $localItem.note)
            // acquisition
            Section(header: Text("CARCTERISTIQUES")) {
                AmountEditView(label  : "Montant emprunté",
                               amount : $localItem.value)
            }
        }
        .alert(item: $alertItem, content: myAlert)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .navigationTitle("Dette")
        .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(
                    action : duplicate,
                    label  : { Text("Dupliquer")} )
                    .capsuleButtonStyle()
                    .disabled((index == nil) || changeOccured()),
                trailing: Button(
                    action: applyChanges,
                    label: {
                        Text("Sauver")
                } )
                    .disabled(!changeOccured())
        )
    }

    init(item: Debt?, patrimoine: Patrimoin) {
        self.originalItem       = item
        if let initialItemValue = item {
            // modification d'un élément existant
            _localItem = State(initialValue: initialItemValue)
            _index     = State(initialValue: patrimoine.liabilities.debts.items.firstIndex(of: initialItemValue))
            // specific
        } else {
            // création d'un nouvel élément
            index = nil
        }
    }
    
    func duplicate() {
        // générer un nouvel identifiant pour la copie
        localItem.id = UUID()
        localItem.name += "-copie"
        // ajouter un élément à la liste
        patrimoine.liabilities.debts.add(localItem)
        // revenir à l'élement avant duplication
        localItem = originalItem!
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
        uiState.resetSimulation()

        self.presentationMode.wrappedValue.dismiss()
    }
    
    func changeOccured() -> Bool {
        return localItem != originalItem
    }
    
    func isValid() -> Bool {
        if localItem.value > 0 {
            self.alertItem = AlertItem(title         : Text("Erreur"),
                                       message       : Text("Le montant emprunté doit être négatif"),
                                       dismissButton : .default(Text("OK")))
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
