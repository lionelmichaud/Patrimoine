//
//  ScenarioView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ScenarioView: View {
    @EnvironmentObject var uiState    : UIState
    
    enum PushedItem {
        case summary, deterministicModel, humanModel, economyModel, sociologyModel, statisticsAssistant
    }
    
    var body: some View {
        NavigationView {
            /// Primary view
            List {
                // entête
                ScenarioHeaderView()
                
                // liste des items de la side bar
                ScenarioListView()
            }
            .defaultSideBarListStyle()
            .environment(\.horizontalSizeClass, .regular)
            .navigationTitle("Scénario")
            //            .navigationBarItems(
            //                leading: EditButton(),
            //                trailing: Button(
            //                    action: {
            //                        withAnimation {
            //                            self.showingSheet = true
            //                        }
            //                    },
            //                    label: {
            //                        Image(systemName: "plus").padding()
            //                    }))
            
            /// vue par défaut
            ScenarioSummaryView()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct ScenarioHeaderView: View {
    @EnvironmentObject var uiState: UIState
    
    var body: some View {
        Section {
            NavigationLink(destination : ScenarioSummaryView(),
                           tag         : .summary,
                           selection   : $uiState.scenarioViewState.selectedItem) {
                Text("Dernière Valeurs Utilisées").fontWeight(.bold)
            }
            .isDetailLink(true)
        }
    }
}

struct ScenarioListView: View {
    @EnvironmentObject var uiState    : UIState
    @EnvironmentObject var simulation : Simulation
    
    var body: some View {
        // Vue des statistiques générées pour les modèles
        ScenarioModelListView()
        
        // Vua assistant statistiques
        Section(header: Text("Statistiques").font(.headline)) {
            NavigationLink(destination: StatisticsChartsView(),
                           tag         : .statisticsAssistant,
                           selection   : $uiState.scenarioViewState.selectedItem) {
                Text("Assistant Distributions")
            }
            .isDetailLink(true)
            .padding(.leading)
        }
    }
}

struct ScenarioView_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()
    
    static var previews: some View {
        ScenarioView()
            .environmentObject(uiState)
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
    }
}
