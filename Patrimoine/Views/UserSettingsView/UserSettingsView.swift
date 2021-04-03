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
        VStack {
            versionView
            Form {
                Toggle("Simuler la volatilité du cours des actions", isOn: $simulateVolatility)
            }
        }.padding()
    }
}

struct UserSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        UserSettingsView()
    }
}
