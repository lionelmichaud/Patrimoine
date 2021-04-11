//
//  UserSettingsView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 26/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - View UserSettingsView

struct UserSettingsView: View {
    @State private var ownership        = UserSettings.shared.ownershipSelection
    @State private var evaluationMethod = UserSettings.shared.assetEvaluationMethod

    var versionView: some View {
        GroupBox {
            Text(AppVersion.shared.appVersion.name ?? "?")
                .font(.title)
                .fontWeight(.heavy)
                .frame(maxWidth: .infinity)
            Text("Version: \(AppVersion.shared.appVersion.version ?? "?")")
            if let date = AppVersion.shared.appVersion.date {
                Text(date, style: Text.DateStyle.date)
            }
            Text(AppVersion.shared.appVersion.comment ?? "")
                .multilineTextAlignment(.center)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Simulation",
                               destination: SimulationUserSettings())
                    .isDetailLink(true)
                
                NavigationLink("Graphiques",
                               destination: GraphicUserSettings(ownership        : $ownership,
                                                                evaluationMethod : $evaluationMethod))
                    .isDetailLink(true)
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Préférences")
            
            // default View
            versionView
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
                              perform: { newValue in
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
            UserSettingsView()
        }
    }
}
