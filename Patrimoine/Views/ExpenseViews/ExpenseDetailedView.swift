//
//  ExpenseDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - View Model for LifeExpense

class LifeExpenseViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published var name         : String = ""
    @Published var value        : Double = 0.0
    @Published var proportional : Bool   = false
    @Published var timeSpanVM   : TimeSpanViewModel
    
    // MARK: - Computed properties
    
    // construire l'objet de type LifeExpense correspondant au ViewModel
    var lifeExpense: LifeExpense {
        return LifeExpense(name         : self.name,
                           timeSpan     : self.timeSpanVM.timeSpan,
                           proportional : self.proportional,
                           value        : self.value)
    }
    
    // MARK: - Initializers of ViewModel from Model

    internal init(from expense: LifeExpense) {
        self.name         = expense.name
        self.value        = expense.value
        self.proportional = expense.proportional
        self.timeSpanVM   = TimeSpanViewModel(from: expense.timeSpan)
    }
    
    internal init() {
        self.timeSpanVM   = TimeSpanViewModel()
    }

    // MARK: - Methods
    
    func differs(from thisLifeExpense: LifeExpense) -> Bool {
        return
            self.name         != thisLifeExpense.name ||
            self.value        != thisLifeExpense.value ||
            self.proportional != thisLifeExpense.proportional ||
            self.timeSpanVM   != TimeSpanViewModel(from: thisLifeExpense.timeSpan)
    }
}
    
// MARK: - View

struct ExpenseDetailedView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState
    @Environment(\.presentationMode) var presentationMode
    
    private var originalItem           : LifeExpense?
    private let category               : LifeExpenseCategory
    @StateObject private var expenseVM : LifeExpenseViewModel
    @State private var alertItem       : AlertItem?
    @State private var index           : Int?

    // MARK: - Computed Properties
    
    var body: some View {
        Form {
            /// nom
            HStack{
                Text("Nom")
                    .frame(width: 70, alignment: .leading)
                TextField("obligatoire", text: $expenseVM.name)
            }
            
            /// montant de la dépense
            AmountEditView(label: "Montant annuel",
                           amount: $expenseVM.value)
            
            /// proportionnalité de la dépense aux nb de membres de la famille
            Toggle("Proportionnel au nombre de membres à charge de la famille",
                   isOn: $expenseVM.proportional)
            
            /// plage de temps
            TimeSpanEditView(timeSpanVM: $expenseVM.timeSpanVM)
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .navigationBarTitle(Text("Dépense " + category.displayString),
                            displayMode: .inline)
        .navigationBarItems(
            leading: Button(
                action : duplicate,
                label  : { Text("Dupliquer")} )
                .capsuleButtonStyle()
                .disabled((index == nil) || changeOccured()),
            trailing: Button(
                action : applyChanges,
                label  : { Text("Sauver")} )
                .capsuleButtonStyle()
                .disabled(!changeOccured())
        )
        .alert(item: $alertItem, content: myAlert)
    }
    
    // MARK: - Initializers
    
    init(category : LifeExpenseCategory,
         item     : LifeExpense?,
         family   : Family) {
        self.originalItem = item
        self.category     = category
        if let initialItemValue = item {
            // modification d'un élément existant
            _expenseVM = StateObject(wrappedValue: LifeExpenseViewModel(from: initialItemValue))
            _index     = State(initialValue: family.expenses.perCategory[category]?.items.firstIndex(of: initialItemValue))
        } else {
            // création d'un nouvel élément
            _expenseVM = StateObject(wrappedValue: LifeExpenseViewModel(from: LifeExpense()))
            index = nil
        }
    }
    
    // MARK: - Methods
    
    func duplicate() {
        var localItem = expenseVM.lifeExpense
        // générer un nouvel identifiant pour la copie
        localItem.id = UUID()
        localItem.name += "-copie"
        // ajouter la copie créée
        family.expenses.perCategory[self.category]?.add(localItem,
                                                        fileNamePrefix : self.category.pickerString + "_")
    }
    
    // sauvegarder les changements
    func applyChanges() {
        /// vérifier que ke nom ne fait pas doublon
        let nameAlreadyExists = family.expenses.perCategory.values.contains { arrayOfExpenses in
            return arrayOfExpenses.items.contains { expense in
                return expense.name == expenseVM.name
            }
        }
        if nameAlreadyExists {
            self.alertItem = AlertItem(title         : Text("Le nom existe déjà. Choisissez en un autre."),
                                       dismissButton : .default(Text("OK")))
            return
        }
        guard expenseVM.name != "" else {
            self.alertItem = AlertItem(title         : Text("Le nom est obligatoire"),
                                       dismissButton : .default(Text("OK")))
            return
        }
        /// valider les dates
        guard let firstYear = expenseVM.timeSpanVM.timeSpan.firstYear else {
            self.alertItem = AlertItem(title         : Text("La date de début doit être définie"),
                                       dismissButton : .default(Text("OK")))
            return
        }
        guard let lastYear = expenseVM.timeSpanVM.timeSpan.lastYear else {
            self.alertItem = AlertItem(title         : Text("La date de fin doit être définie"),
                                       dismissButton : .default(Text("OK")))
            return
        }
        guard expenseVM.timeSpanVM.timeSpan.isValid else {
            self.alertItem = AlertItem(title         : Text("La date de début (\(firstYear)) doit être antérieure ou égale à la date de fin (\(lastYear))"),
                                       dismissButton : .default(Text("OK")))
            return
        }

        // tous les tests sont OK
        if let index = index {
            // modifier un éléménet existant
            family.expenses.perCategory[self.category]?.update(with           : expenseVM.lifeExpense,
                                                               at             : index,
                                                               fileNamePrefix : self.category.pickerString + "_")
        } else {
            // créer un nouvel élément
            family.expenses.perCategory[self.category]?.add(expenseVM.lifeExpense,
                                                            fileNamePrefix : self.category.pickerString + "_")
        }
        
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()
        
        self.presentationMode.wrappedValue.dismiss()
    }
    
    func changeOccured() -> Bool {
        if originalItem == nil {
            return true
        } else {
            return expenseVM.differs(from: originalItem!)
        }
    }
}

struct ExpenseDetailedView_Previews: PreviewProvider {
    static var family     = Family()
    static var simulation = Simulation()
    static var patrimoine = Patrimoin()
    static var uiState    = UIState()
    
    static var previews: some View {
        ExpenseDetailedView(category : .autres,
                            item     : LifeExpense(name    : "Test",
                                                   timeSpan: .permanent,
                                                   value   : 1234.0),
                            family   : family)
            .environmentObject(family)
            .environmentObject(simulation)
            .environmentObject(patrimoine)
            .environmentObject(uiState)
    }
}
