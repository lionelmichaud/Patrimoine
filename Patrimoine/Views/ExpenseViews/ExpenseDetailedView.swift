//
//  ExpenseDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ExpenseDetailedView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState
    @Environment(\.presentationMode) var presentationMode
    private var item             : Expense?
    private let category         : ExpenseCategory
    @State private var alertItem : AlertItem?
    @State private var index     : Int?
    @State private var localItem = Expense(name     : "",
                                           timeSpan : .permanent,
                                           value    : 0.0)
    
    var body: some View {
        Form {
            // nom
            HStack{
                Text("Nom")
                    .frame(width: 70, alignment: .leading)
                TextField("obligatoire", text: $localItem.name)
            }
            // montant de la dépense
            AmountEditView(label: "Montant annuel",
                           amount: $localItem.value)
            // proportionnalité de la dépense aux nb de membres de la famille
            Toggle("Proportionnel au nombre de membres de la famille",
                   isOn: $localItem.proportional)
            // plage de temps
            TimeSpanEditView(timeSpan: $localItem.timeSpan)
        }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .navigationBarTitle(Text("Dépense " + category.displayString),
                                displayMode: .inline)
            .navigationBarItems(
                leading: Button(
                    action : duplicate,
                    label  : { Text("Dupliquer")} )
                        .disabled(index == nil),
                trailing: Button(
                    action : applyChanges,
                    label  : { Text("Sauver")} )
                        .disabled(!changeOccured())
            )
            .alert(item: $alertItem, content: myAlert) 
    }
    
    init(category: ExpenseCategory, item: Expense?, family: Family) {
        self.item     = item
        self.category = category
        if let initialItemValue = item {
            // modification d'un élément existant
            _localItem = State(initialValue: initialItemValue)
            _index     = State(initialValue: family.expenses.categories[category]?.items.firstIndex(of: initialItemValue))
        } else {
            index = nil
        }
    }
    
    func duplicate() {
        if index != nil {
            family.expenses.categories[self.category]?.add(localItem)
        }
    }
    
    // sauvegarder les changements
    func applyChanges() {
        guard localItem.timeSpan.isValid else {
            self.alertItem = AlertItem(title         : Text("La valeur de début doit être antérieure ou égale à la valeur de fin"),
                                       dismissButton : .default(Text("OK")))
            return
        }
        guard localItem.name != "" else {
            self.alertItem = AlertItem(title         : Text("Le nom est obligatoire"),
                                       dismissButton : .default(Text("OK")))
            return
        }
        if let index = index {
            // modifier un éléménet existant
            family.expenses.categories[self.category]?.update(with: localItem,
                                                              at  : index)
        } else {
            // créer un nouvel élément
            family.expenses.categories[self.category]?.add(localItem)
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

struct ExpenseDetailedView_Previews: PreviewProvider {
    static var family     = Family()
    static var simulation = Simulation()
    static var patrimoine = Patrimoin()
    static var uiState    = UIState()

    static var previews: some View {
        ExpenseDetailedView(category : .autre,
                            item     : Expense(name    : "Test",
                                               timeSpan: .permanent,
                                               value   : 1234.0),
                            family   : family)
            .environmentObject(family)
            .environmentObject(simulation)
            .environmentObject(patrimoine)
            .environmentObject(uiState)
    }
}
