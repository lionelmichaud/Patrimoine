//
//  ContentView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Nested struct
    
    struct TabLabel: View {
        let imageName: String
        let label: String
        
        var body: some View {
            Group {
                Image(systemName: imageName).imageScale(.large)
                Text(label)
            }
        }
    }
 
    // MARK: - Properties

    var family     : Family
    var patrimoine : Patrimoine
    var simulation : Simulation
    @EnvironmentObject private var uiState: UIState
    //@State private var selectedTab = UIState.Tab.family
    
    var body: some View {
        TabView(selection: $uiState.selectedTab){
            // composition de la famille
            FamilyView()
                .tabItem { TabLabel(imageName: "person.2.fill", label: "Famille") }
                .tag(UIState.Tab.family)
            
            // dépenses de la famille
            ExpenseView()
                .tabItem { TabLabel(imageName: "cart.fill", label: "Dépenses") }
                .tag(UIState.Tab.expense)
            
            // actifs & passifs du patrimoine de la famille
            PatrimoineView()
                .tabItem { TabLabel(imageName: "dollarsign.circle.fill", label: "Patrimoine") }
                .tag(UIState.Tab.asset)
            
            // scenario paramètrique de simulation
            ScenarioView()
                .tabItem { TabLabel(imageName: "slider.horizontal.3", label: "Scénarios") }
                .tag(UIState.Tab.scenario)
            
            // calcul et présentation des résultats de simulation
            SimulationView()
                .tabItem { TabLabel(imageName: "chart.bar.fill", label: "Simulation") }
                .tag(UIState.Tab.simulation)
        }
        .environmentObject(family)
        .environmentObject(patrimoine)
        .environmentObject(simulation)
        .environmentObject(uiState)
    }
    
    // MARK: - Initializer

    internal init(family     : Family     = Family(),
                  patrimoine : Patrimoine = Patrimoine(),
                  simulation : Simulation = Simulation()) {
        // chargement des données en fichier
        self.family     = family
        self.patrimoine = patrimoine
        self.simulation = simulation
        
        // injection de family dans la propriété statique de Expenses pour lier les évenements à des personnes
        Expense.family = family
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static let uiState = UIState()
    
    static var previews: some View {
        Group {
            ContentView().colorScheme(.dark)
                .environmentObject(uiState)
            //ContentView().colorScheme(.light)
                            .environment(\.locale, .init(identifier: "fr"))
            //                .previewDevice(PreviewDevice(rawValue: "iPhone X"))
            //                .previewDisplayName("iPhone X")
            //            ContentView()
            //                .environment(\.locale, .init(identifier: "fr"))
            //                .previewDevice(PreviewDevice(rawValue: "iPad Air (3rd generation)"))
            //                .previewDisplayName("iPad Air (3rd generation)")
        }
        
    }
}
