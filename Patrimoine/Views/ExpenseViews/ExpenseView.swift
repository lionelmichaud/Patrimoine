//
//  ExpenseView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ExpenseView: View {
    @EnvironmentObject var family     : Family

    private var categories: [(LifeExpenseCategory, ExpenseArray)] {
        family.expenses.perCategory.sorted(by: \.key.displayString)
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                List {
                    // résumé
                    ExpenseHeaderView()
                    
                    // pour chaque catégorie de dépense, afficher la liste des dépenses
                    ForEach(categories, id: \.0) { (category, expenses) in
                        ExpenseListInCategory(category: category,
                                              expenses: expenses)
                    }
                }
                .defaultSideBarListStyle()
                //.listStyle(GroupedListStyle())
                .environment(\.horizontalSizeClass, .regular)
                
            }
            .navigationTitle("Dépenses")
            .navigationBarItems(
                leading: EditButton())
            
            // vue par défaut
            ExpenseSummaryView()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct ExpenseHeaderView: View {
    @EnvironmentObject var family: Family

    var body: some View {
        Group {
            Section {
                NavigationLink(destination: ExpenseSummaryView()) {
                    Text("Résumé").fontWeight(.bold)
                }
                .isDetailLink(true)
            }
            Section {
                HStack {
                    Text("Total")
                        .font(Font.system(size: 21,
                                          design: Font.Design.default))
                        .fontWeight(.bold)
                    Spacer()
                    Text(family.expenses.value(atEndOf: Date.now.year).€String)
                        .font(Font.system(size: 21,
                                          design: Font.Design.default))
                }
                .listRowBackground(ListTheme.rowsBaseColor)
            }
        }
    }
}

struct ExpenseListInCategory: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState
    let category: LifeExpenseCategory
    var expenses: ExpenseArray
    //@State private var colapse = true

    var body: some View {
        Section {
            LabeledValueRowView(colapse     : $uiState.expenseViewState.colapseCategories[category.rawValue],
                                label       : category.displayString,
                                value       : family.expenses.perCategory[category]?.value(atEndOf: Date.now.year) ?? 0,
                                indentLevel : 0,
                                header      : true)
            if !uiState.expenseViewState.colapseCategories[category.rawValue] {
                // ajouter un nouvel item à liste des items
                NavigationLink(destination: ExpenseDetailedView(category: category,
                                                                item    : nil,
                                                                family  : family)) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .imageScale(.large)
                            Text("Ajouter un élément...")
                        }
                        .foregroundColor(.accentColor)
                }
                
                // liste des items existants
                ForEach(expenses.items) { expense in
                    NavigationLink(destination: ExpenseDetailedView(category: self.category,
                                                                    item    : expense,
                                                                    family  : self.family)) {
                        LabeledValueRowView(colapse     : .constant(true),
                                            label       : expense.name,
                                            value       : expense.value(atEndOf: Date.now.year),
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
    
    func removeItems(at offsets: IndexSet) {
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()
        // supprimer la dépense
        family.expenses.perCategory[self.category]?.delete(at             : offsets,
                                                           fileNamePrefix : self.category.pickerString + "_")
    }
    
    func move(from source    : IndexSet, to destination : Int) {
        family.expenses.perCategory[self.category]?.move(from           : source,
                                                         to             : destination,
                                                         fileNamePrefix : self.category.pickerString + "_")
    }
}

struct ExpenseView_Previews: PreviewProvider {
    static var family     = Family()
    static var simulation = Simulation()
    static var patrimoine = Patrimoin()
    static var uiState    = UIState()

    static var previews: some View {
        NavigationView() {
            ExpenseView()
                .environmentObject(family)
                .environmentObject(simulation)
                .environmentObject(patrimoine)
                .environmentObject(uiState)
        }
    }
}
