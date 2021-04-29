//
//  AppVersionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/04/2021.
//

import SwiftUI

struct AppVersionView: View {
    var body: some View {
        VStack {
            Text(AppVersion.shared.name ?? "Patrimonio")
                .font(.title)
                .fontWeight(.heavy)
                .frame(maxWidth: .infinity)
            Text("Version: \(AppVersion.shared.theVersion ?? "?")")
            if let date = AppVersion.shared.date {
                Text(date, style: Text.DateStyle.date)
            }
            Text(AppVersion.shared.comment ?? "")
                .multilineTextAlignment(.center)
        }
    }
}

struct AppVersionView_Previews: PreviewProvider {
    static var previews: some View {
        AppVersionView()
    }
}
