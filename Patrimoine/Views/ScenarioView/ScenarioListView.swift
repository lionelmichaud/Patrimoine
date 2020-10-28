//
//  ScenarioListView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ScenarioModelListView: View {
    @EnvironmentObject var uiState: UIState

    var body: some View {
        Section(header: Text("Modèles Déterministe").font(.headline)) {
            NavigationLink(destination: ModelDeterministicView(),
                           tag         : .deterministicModel,
                           selection   : $uiState.scenarioViewState.selectedItem) {
                Text("Tous les Modèles")
            }
            .isDetailLink(true)
        }
       Section(header: Text("Modèles Statistiques").font(.headline)) {
            NavigationLink(destination: ModelHumanView(),
                           tag         : .humanModel,
                           selection   : $uiState.scenarioViewState.selectedItem) {
                Text("Modèle Humain")
            }
            .isDetailLink(true)
            
            NavigationLink(destination: ModelEconomyView(),
                           tag         : .economyModel,
                           selection   : $uiState.scenarioViewState.selectedItem) {
                Text("Modèle Economique")
            }
            .isDetailLink(true)
            
            NavigationLink(destination: ModelSociologyView(),
                           tag         : .sociologyModel,
                           selection   : $uiState.scenarioViewState.selectedItem) {
                Text("Modèle Sociologique")
            }
            .isDetailLink(true)
        }
    }
}

struct ScenarioModelListView_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()

    static var previews: some View {
        Form {
            ScenarioModelListView()
                .environmentObject(uiState)
                .environmentObject(family)
                .environmentObject(patrimoine)
                .environmentObject(simulation)
                .previewLayout(.sizeThatFits)
        }        
    }
}
