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
        case computation, charts
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // entête
                SimulationHeaderView()
                
                //liste
                List {
                    NavigationLink(destination : ComputationView(),
                                   tag         : .computation,
                                   selection   : $uiState.simulationViewState.selectedItem) {
                                    Text("Calculs")
                    }
                    .isDetailLink(true)
                    NavigationLink(destination: ChartsView(),
                                   tag         : .charts,
                                   selection   : $uiState.simulationViewState.selectedItem) {
                                    Text("Graphiques")
                    }
                    .isDetailLink(false)
                }
                .listStyle(GroupedListStyle())
                .environment(\.horizontalSizeClass, .regular)
            }
            .navigationBarTitle("Simulation")
            
            // vue par défaut
            ComputationView()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct SimulationHeaderView : View {
    @EnvironmentObject var simulation : Simulation

    var body: some View {
        Group {
            if !simulation.isComputed {
                VStack(alignment: .leading) {
                    Text("Aucune données à présenter")
                    Text("Calculer une simulation au préalable").foregroundColor(.red)
                }
                .padding(.horizontal)
            } else {
                Text("Simulation disponible: \(simulation.firstYear!) à \(simulation.lastYear!)")
                    .font(.callout)
                    .padding(.horizontal)
            }
        }
    }
}


struct SimulationView_Previews: PreviewProvider {
    static var family     = Family()
    static var patrimoine = Patrimoine()
    static var simulation = Simulation()
    
    static var previews: some View {
        SimulationView()
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
            .colorScheme(.dark)
    }
}
