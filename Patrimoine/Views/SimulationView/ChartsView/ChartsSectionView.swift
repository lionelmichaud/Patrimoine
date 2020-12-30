//
//  ChartsView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ChartsSectionView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @State private var isBsExpanded   : Bool = false
    @State private var isCfExpanded   : Bool = false
    @State private var isIrppExpanded : Bool = false
    @State private var isIsfExpanded  : Bool = false

    var body: some View {
        if simulation.isComputed {
            Section(header: Text("Graphiques") ) {
                DisclosureGroup(isExpanded: $isBsExpanded,
                                content: {
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
                                },
                                label: {
                                    Text("Bilan")//.font(.headline)
                                })

                DisclosureGroup(isExpanded: $isCfExpanded,
                                content: {
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
                                },
                                label: {
                                    Text("Cash Flow")//.font(.headline)
                                })

                DisclosureGroup(isExpanded: $isIrppExpanded,
                                content: {
                                    NavigationLink(destination : IrppEvolutionChartView(),
                                                   tag         : .irppSynthesis,
                                                   selection   : $uiState.simulationViewState.selectedItem) {
                                        Text("Synthèse de l'évolution")
                                    }
                                    .isDetailLink(true)
                                    
                                    NavigationLink(destination : IrppSliceView(),
                                                   tag         : .irppSlices,
                                                   selection   : $uiState.simulationViewState.selectedItem) {
                                        Text("Décomposition par tranche")
                                    }
                                    .isDetailLink(true)
                                },
                                label: {
                                    Text("Impôt sur le Revenu")//.font(.headline)
                                })

                DisclosureGroup(isExpanded: $isIsfExpanded,
                                content: {
                                    NavigationLink(destination : IsfEvolutionChartView(),
                                                   tag         : .isfSynthesis,
                                                   selection   : $uiState.simulationViewState.selectedItem) {
                                        Text("Synthèse de l'évolution")
                                    }
                                    .isDetailLink(true)
                                },
                                label: {
                                    Text("Impôt sur la Fortune")//.font(.headline)
                                })
            }
        } else {
            EmptyView()
        }
    }
}

struct ChartsView_Previews: PreviewProvider {
    static var previews: some View {
        ChartsSectionView()
    }
}
