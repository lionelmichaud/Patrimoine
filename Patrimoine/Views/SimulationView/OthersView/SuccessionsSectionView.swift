//
//  SimulationOthersView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct SuccessionsSectionView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    
    var body: some View {
        if simulation.isComputed {
            Section(header: Text("Successions") ) {
                NavigationLink(destination: SuccessionsView(title       : "Successions Légales",
                                                            successions : simulation.occuredLegalSuccessions),
                               tag         : .successionsLegal,
                               selection   : $uiState.simulationViewState.selectedItem) {
                    Text("Légales")
                }
                .isDetailLink(true)
                
                NavigationLink(destination: SuccessionsView(title       : "Successions d'Assurances Vie",
                                                            successions : simulation.occuredLifeInsSuccessions),
                               tag         : .successionsAssVie,
                               selection   : $uiState.simulationViewState.selectedItem) {
                    Text("Assurance Vie")
                }
                .isDetailLink(true)
                
                NavigationLink(destination: SuccessionsView(title       : "Cumul des Successions",
                                                            successions : simulation.occuredLegalSuccessions + simulation.occuredLifeInsSuccessions),
                               tag         : .successionCumul,
                               selection   : $uiState.simulationViewState.selectedItem) {
                    Text("Cumul")
                }
                .isDetailLink(true)
            }
        }
    }
}

struct SimulationOthersView_Previews: PreviewProvider {
    static var previews: some View {
        SuccessionsSectionView()
    }
}
