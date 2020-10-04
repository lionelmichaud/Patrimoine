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

    enum PushedItem {
        case bilanSynthese, bilanDetail, cfSynthese, cfDetail, kpi, statistics
    }
    
    var body: some View {
        VStack {
            if !simulation.isComputed {
                // pas de données à afficher
                VStack(alignment: .leading) {
                    Text("Aucune données à présenter")
                    Text("Calculer une simulation au préalable").foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal)
                
            } else {
                Text("Simulation disponible: \(simulation.firstYear!) à \(simulation.lastYear!)")
                    .font(.callout)
                    .padding(.horizontal)
                List {
                    Section(header: Text("Bilan").font(.headline)) {
                        NavigationLink(destination: BalanceSheetGlobalChartView(),
                                       tag         : .bilanSynthese,
                                       selection   : $uiState.chartsViewState.selectedItem) {
                                        Text("Synthèse")
                                        
                        }
                        .isDetailLink(true)
                        .padding(.leading)
                        
                        NavigationLink(destination: BalanceSheetDetailedChartView(),
                                       tag         : .bilanDetail,
                                       selection   : $uiState.chartsViewState.selectedItem) {
                                        Text("Détails")
                        }
                        .isDetailLink(true)
                        .padding(.leading)
                    }
                    
                    Section(header: Text("Cash flow").font(.headline)) {
                        NavigationLink(destination: CashFlowGlobalChartView(),
                                       tag         : .cfSynthese,
                                       selection   : $uiState.chartsViewState.selectedItem) {
                            Text("Synthèse")
                        }
                        .isDetailLink(true)
                        .padding(.leading)
                        
                        NavigationLink(destination: CashFlowDetailedChartView(),
                                       tag         : .cfDetail,
                                       selection   : $uiState.chartsViewState.selectedItem) {
                            Text("Détails")
                        }
                        .isDetailLink(true)
                        .padding(.leading)
                    }
                    
                    Section(header: Text("KPI").font(.headline)) {
                        KpiListView()
                            .padding(.leading)
                    }

                    Section(header: Text("Statistiques").font(.headline)) {
                        NavigationLink(destination: StatisticsChartsView(),
                                       tag         : .statistics,
                                       selection   : $uiState.chartsViewState.selectedItem) {
                            Text("Assistant Distributions")
                        }
                        .isDetailLink(true)
                        .padding(.leading)
                    }
                }
                .defaultSideBarListStyle()
                //.listStyle(GroupedListStyle())
                .environment(\.horizontalSizeClass, .regular)
            }
        }
        .navigationTitle("Graphiques")
    }
}

struct ChartsView_Previews: PreviewProvider {
    static var previews: some View {
        ChartsView()
    }
}
