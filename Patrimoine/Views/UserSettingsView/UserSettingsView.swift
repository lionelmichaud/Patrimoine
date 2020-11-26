//
//  UserSettingsView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 26/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct UserSettingsView: View {
    var body: some View {
        VStack {
            Text("PATRIMOINE").font(.title)
                .fontWeight(.heavy)
            Text("Version: \(AppSettings.shared.appVersion.version ?? "?")")
            if let date = AppSettings.shared.appVersion.date {
                Text(date, style: Text.DateStyle.date)
            }
            Text(AppSettings.shared.appVersion.comment ?? "")
                .multilineTextAlignment(.center)
            
        }.padding()
    }
}

struct UserSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        UserSettingsView()
    }
}
