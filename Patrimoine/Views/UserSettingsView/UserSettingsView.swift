//
//  UserSettingsView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 26/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct GraphicUserSettings: View {
    // si la variable d'état est locale (@State) cela ne fonctionne pas correctement
    @Binding var ownership: OwnershipNature
    
    var body: some View {
        Form {
            Section(footer: Text("Le graphique détaillé de l'évolution dans le temps du bilan d'un individu ne prendra en compte que les biens satisfaisant à ce critère")) {
                CasePicker(pickedCase: $ownership, label: "Nature de propriété individuelle du graphique Bilan")
                    .pickerStyle(DefaultPickerStyle())
                    .onChange(of     : ownership,
                              perform: { newValue in
                                UserSettings.shared.ownershipSelection = newValue })
            }
        }
    }
}

struct SimulationUserSettings: View {
    @AppStorage(UserSettings.simulateVolatility) var simulateVolatility: Bool = false
    
    var body: some View {
        Form {
            Section(footer: Text("En mode Monté-Carlo seulement: simuler la volatilité du cours des actions et des obligations")) {
                Toggle("Simuler la volatilité des marchés", isOn: $simulateVolatility)
            }
        }
    }
}

struct UserSettingsView: View {
    @State private var ownership: OwnershipNature = UserSettings.shared.ownershipSelection

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
                NavigationLink("Simulation", destination: SimulationUserSettings())
                    .isDetailLink(true)
                
                NavigationLink("Graphiques", destination: GraphicUserSettings(ownership: $ownership))
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

struct UserSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UserSettingsView()
        }
    }
}
