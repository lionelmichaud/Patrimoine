//
//  SimulationView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct SimulationView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    
    enum PushedItem {
        case computation, bilanSynthese, bilanDetail, cfSynthese, cfDetail, kpiSummary, statistics
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // entête
                //SimulationHeaderView()
                
                //liste
                List {
                    // calcul de simulation
                    NavigationLink(destination : ComputationView(),
                                   tag         : .computation,
                                   selection   : $uiState.simulationViewState.selectedItem) {
                        Text("Calculs")
                    }
                    .isDetailLink(true)
                    
                    // affichage des graphiques
                    ChartsView()
                }
                .defaultSideBarListStyle()
                //.listStyle(InsetGroupedListStyle())
                .environment(\.horizontalSizeClass, .regular)
            }
            .navigationTitle("Simulation")

            // vue par défaut
            //SimulationHeaderView()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct SimulationView_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()
    
    static var previews: some View {
        SimulationView()
            .environmentObject(uiState)
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
            .colorScheme(.dark)
    }
}
