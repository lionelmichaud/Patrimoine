//
//  ChartsView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ChartsView: View {
    @EnvironmentObject var simulation   : Simulation
    @EnvironmentObject var uiState      : UIState
    @State private var isBsExpanded     : Bool = false
    @State private var isCfExpanded     : Bool = false
    @State private var isFiscalExpanded : Bool = false

    var body: some View {
        if simulation.isComputed {
            Section {
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
            }
            
            Section {
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
            }
            
            Section {
                DisclosureGroup(isExpanded: $isFiscalExpanded,
                                content: {
                                    NavigationLink(destination : FiscalEvolutionChartView(),
                                                   tag         : .irppSynthesis,
                                                   selection   : $uiState.simulationViewState.selectedItem) {
                                        Text("Synthèse de l'évolution")
                                    }
                                    .isDetailLink(true)
                                    
                                    NavigationLink(destination : FiscalSliceView(),
                                                   tag         : .irppSlices,
                                                   selection   : $uiState.simulationViewState.selectedItem) {
                                        Text("Décomposition par tranche")
                                    }
                                    .isDetailLink(true)
                                },
                                label: {
                                    Text("Fiscalité")//.font(.headline)
                                })
            }
        } else {
            EmptyView()
        }
    }
}

struct ChartsView_Previews: PreviewProvider {
    static var previews: some View {
        ChartsView()
    }
}
