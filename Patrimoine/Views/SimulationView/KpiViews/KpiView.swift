//
//  KpiView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct KpiView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @State private var isKpiExpanded  : Bool = false

    var body: some View {
        if !simulation.isComputed {
            // pas de données à afficher
            VStack(alignment: .leading) {
                Text("Aucune données à présenter")
                Text("Calculer une simulation au préalable").foregroundColor(.red)
                Spacer()
            }
            
        } else {
            Section {
                // synthèse des KPIs
                DisclosureGroup(isExpanded: $isKpiExpanded,
                                content: {
                NavigationLink(destination : KpiListSummaryView(),
                               tag         : .kpiSummaryView,
                               selection   : $uiState.simulationViewState.selectedItem) {
                    HStack {
                        if let allObjectivesAreReached = simulation.kpis.allObjectivesAreReached(withMode: simulation.mode) {
                            Image(systemName: allObjectivesAreReached ? "checkmark.circle.fill" : "multiply.circle.fill")
                                .imageScale(.medium)
                                .foregroundColor(allObjectivesAreReached ? .green : .red)
                        }
                        Text("Synthèse des KPIs")
                    }
                }
                .isDetailLink(true)
                
                // Liste des KPIs
                KpiListView()
                
                // Résultats tabulés des runs de MontéCarlo
                if simulation.mode == .random {
                    NavigationLink(destination : ShortGridView(),
                                   tag         : .shortGridView,
                                   selection   : $uiState.simulationViewState.selectedItem) {
                        Text("Tableau détaillé des runs")
                    }
                    .isDetailLink(true)
                }

                                },
                                label: {
                                    Text("KPI").font(.headline)
                                })
            }
        }
    }
}

struct KpiView_Previews: PreviewProvider {
    static var previews: some View {
        KpiView()
    }
}
