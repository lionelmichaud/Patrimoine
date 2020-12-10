//
//  AlertView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct AlertItem: Identifiable {
    var id = UUID()
    var title = Text("")
    var message: Text?
    var dismissButton: Alert.Button?
    var primaryButton: Alert.Button?
    var secondaryButton: Alert.Button?
}

func myAlert(alertItem: AlertItem) -> Alert {
    if let primaryButton = alertItem.primaryButton,
        let secondaryButton = alertItem.secondaryButton {
        return Alert(title           : alertItem.title,
                     message         : alertItem.message,
                     primaryButton   : primaryButton,
                     secondaryButton : secondaryButton)
    } else {
        return Alert(title         : alertItem.title,
                     message       : alertItem.message,
                     dismissButton : alertItem.dismissButton)
    }
}

/// Usage
/// https://medium.com/better-programming/alerts-in-swiftui-a714a19a547e
struct ContentWithAlertView: View {

    @State var alertItem : AlertItem?

    var body: some View {

        VStack {

            /// button 1
            Button(action: {
                self.alertItem = AlertItem(title: Text("I'm an alert"), message: Text("Are you sure about this?"), primaryButton: .default(Text("Yes"), action: {
                    /// insert alert 1 action here
                }), secondaryButton: .cancel())
            }, label: {
                Text("SHOW ALERT 1")
            })

            /// button 2
            Button(action: {
                self.alertItem = AlertItem(title: Text("I'm another alert"), dismissButton: .default(Text("OK")))
            }, label: {
                Text("SHOW ALERT 2")
            })

        }.alert(item: $alertItem, content: myAlert)
    }
}

struct ContentWithAlertView_Previews: PreviewProvider {
    static var previews: some View {
        ContentWithAlertView()
    }
}
