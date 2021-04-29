//
//  ContentView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - Environment Properties

    @EnvironmentObject private var uiState: UIState
    //@SceneStorage("selectedTab") var selection = UIState.Tab.family
    
    // MARK: - Properties

    var body: some View {
        TabView(selection: $uiState.selectedTab) {
            /// préférences
            SettingsView()
                .tabItem { Label("Préférences", systemImage: "gear") }
                .tag(UIState.Tab.userSettings)
            
            /// composition de la famille
            FamilyView()
                .tabItem { Label("Famille", systemImage: "person.2.fill") }
                .tag(UIState.Tab.family)
            
            /// dépenses de la famille
            ExpenseView()
                .tabItem { Label("Dépenses", systemImage: "cart.fill") }
                .tag(UIState.Tab.expense)

            /// actifs & passifs du patrimoine de la famille
            PatrimoineView()
                .tabItem { Label("Patrimoine", systemImage: "dollarsign.circle.fill") }
                .tag(UIState.Tab.asset)

            /// scenario paramètrique de simulation
            ScenarioView()
                .tabItem { Label("Scénarios", systemImage: "slider.horizontal.3") }
                .tag(UIState.Tab.scenario)

            /// calcul et présentation des résultats de simulation
            SimulationView()
                .tabItem { Label("Simulation", systemImage: "function") }
                .tag(UIState.Tab.simulation)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static let uiState    = UIState()
    static let family     = Family()
    static let patrimoine = Patrimoin()
    static let simulation = Simulation()

    static var previews: some View {
        Group {
            ContentView().colorScheme(.dark)
                .environmentObject(uiState)
                .environmentObject(family)
                .environmentObject(patrimoine)
                .environmentObject(simulation)
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
