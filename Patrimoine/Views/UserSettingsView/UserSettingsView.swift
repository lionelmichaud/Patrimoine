//
//  UserSettingsView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 26/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct UserSettingsView: View {
    @AppStorage(UserSettings.simulateVolatility) var simulateVolatility: Bool = false
    @AppStorage(UserSettings.ownershipSelection) var ownershipSelectionString: String = OwnershipNature.fullOwners.rawValue
    @State private var ownership: OwnershipNature = OwnershipNature(rawValue: UserSettings.shared.ownershipSelectionString)!

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
            versionView
                .padding()
            Form {
                CasePicker(pickedCase: $ownership, label: "Nature de la propriété individuelle pris en compte dans le graphique Bilan")
                    .pickerStyle(DefaultPickerStyle())
                    .onChange(of     : ownership,
                              perform: { newValue in
                                ownershipSelectionString = newValue.rawValue })
                Text(UserSettings.shared.ownershipSelectionString)
                Toggle("Simuler la volatilité du cours des actions (en mode Monté-Carlo)", isOn: $simulateVolatility)
                // sélecteur: Revenus / Cessibles / Tout
            }
        }
    }
}

struct UserSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        UserSettingsView()
    }
}
