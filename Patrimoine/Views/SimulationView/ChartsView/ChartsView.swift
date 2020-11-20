//
//  ChartsView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ChartsView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    
    var body: some View {
        if !simulation.isComputed {
            // pas de données à afficher
            VStack(alignment: .leading) {
                Text("Aucune données à présenter")
                Text("Calculer une simulation au préalable").foregroundColor(.red)
                Spacer()
            }
            
        } else {
            Section(header: Text("KPI").font(.headline)) {
                // synthèse des KPIs
                NavigationLink(destination : KpiListSummaryView(),
                               tag         : .kpiSummaryView,
                               selection   : $uiState.simulationViewState.selectedItem) {
                    HStack {
                        if let allObjectivesAreReached = simulation.kpis.allObjectivesAreReached(withMode: simulation.mode) {
                            Image(systemName: allObjectivesAreReached ? "checkmark.circle.fill" : "multiply.circle.fill")
                                .imageScale(.medium)
                                .foregroundColor(allObjectivesAreReached ? .green : .red)
                        }
                        Text("Synthèse")
                    }
                }
                .isDetailLink(true)
                
                // Liste des KPIs
                KpiListView()
            }
            
            Section(header: Text("Graphes Bilan").font(.headline)) {
                NavigationLink(destination : BalanceSheetGlobalChartView(),
                               tag         : .bilanSynthese,
                               selection   : $uiState.simulationViewState.selectedItem) {
                    Text("Synthèse de l'évolution")
                }
                .isDetailLink(true)
                
                NavigationLink(destination : BalanceSheetDetailedChartView(),
                               tag         : .bilanDetail,
                               selection   : $uiState.simulationViewState.selectedItem) {
                    Text("Détails de l'évolution")
                }
                .isDetailLink(true)
            }
            
            Section(header: Text("Graphes Cash Flow").font(.headline)) {
                NavigationLink(destination : CashFlowGlobalChartView(),
                               tag         : .cfSynthese,
                               selection   : $uiState.simulationViewState.selectedItem) {
                    Text("Synthèse de l'évolution")
                }
                .isDetailLink(true)
                
                NavigationLink(destination : CashFlowDetailedChartView(),
                               tag         : .cfDetail,
                               selection   : $uiState.simulationViewState.selectedItem) {
                    Text("Détails de l'évolution")
                }
                .isDetailLink(true)
            }
            
            Section(header: Text("Graphes Fiscalité").font(.headline)) {
                NavigationLink(destination : FiscalChartView(),
                               tag         : .irppSynthesis,
                               selection   : $uiState.simulationViewState.selectedItem) {
                    Text("Synthèse de l'évolution")
                }
                .isDetailLink(true)
            }
        }
    }
}

struct ChartsView_Previews: PreviewProvider {
    static var previews: some View {
        ChartsView()
    }
}
