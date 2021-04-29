//
//  UserSettingsView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 26/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - View UserSettingsView

struct SettingsView: View {
    @State private var ownership        = UserSettings.shared.ownershipSelection
    @State private var evaluationMethod = UserSettings.shared.assetEvaluationMethod
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: AppVersionView()) {
                    Label("Version", systemImage: "info.circle")
                }
                .isDetailLink(true)
                
                NavigationLink(destination: SimulationUserSettings()) {
                    Label("Simulation", systemImage: "function")
                }
                .isDetailLink(true)
                
                NavigationLink(destination: GraphicUserSettings(ownership        : $ownership,
                                                                evaluationMethod : $evaluationMethod)) {
                    Label("Graphiques", systemImage: "chart.bar.xaxis")
                }
                .isDetailLink(true)
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Préférences")
            
            // default View
            AppVersionView()
                .padding()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

// MARK: - View UserSettingsView / GraphicUserSettings

struct GraphicUserSettings: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState
    // si la variable d'état est locale (@State) cela ne fonctionne pas correctement
    @Binding var ownership        : OwnershipNature
    @Binding var evaluationMethod : AssetEvaluationMethod
    
    var body: some View {
        Form {
            Section(footer: Text("Le graphique détaillé de l'évolution dans le temps du bilan d'un individu ne prendra en compte que les biens satisfaisant à ce critère")) {
                CasePicker(pickedCase: $ownership, label: "Filtrage du Bilan individuel")
                    .pickerStyle(DefaultPickerStyle())
                    .onChange(of     : ownership,
                              perform: { newValue in
                                UserSettings.shared.ownershipSelection = newValue
                                // remettre à zéro la simulation et sa vue
                                simulation.reset(withPatrimoine: patrimoine)
                                uiState.resetSimulation()
                              })
            }
            
            Section(footer: Text("Le graphique détaillé de l'évolution dans le temps du bilan d'un individu prendra en compte cette valeur")) {
                CasePicker(pickedCase: $evaluationMethod, label: "Valeure prise en compte")
                    .pickerStyle(DefaultPickerStyle())
                    .onChange(of     : evaluationMethod,
                              perform: { newValue in
                                UserSettings.shared.assetEvaluationMethod = newValue
                                // remettre à zéro la simulation et sa vue
                                simulation.reset(withPatrimoine: patrimoine)
                                uiState.resetSimulation()
                              })
            }
        }
    }
}

// MARK: - View UserSettingsView / SimulationUserSettings

struct SimulationUserSettings: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState
    @AppStorage(UserSettings.simulateVolatility) var simulateVolatility: Bool = false
    
    var body: some View {
        Form {
            Section(footer: Text("En mode Monté-Carlo seulement: simuler la volatilité du cours des actions et des obligations")) {
                Toggle("Simuler la volatilité des marchés", isOn: $simulateVolatility)
                    .onChange(of     : simulateVolatility,
                              perform: { _ in
                                // remettre à zéro la simulation et sa vue
                                simulation.reset(withPatrimoine: patrimoine)
                                uiState.resetSimulation()
                              })
            }
        }
    }
}

struct UserSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView()
        }
    }
}
