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
                NavigationLink(destination : SuccessionsView(simulation: simulation),
                               tag         : .successions,
                               selection   : $uiState.simulationViewState.selectedItem) {
                    Text("Légales")
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
