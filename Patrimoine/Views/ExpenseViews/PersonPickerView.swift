//
//  PersonPickerView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct PersonPickerView: View {
    @EnvironmentObject var family : Family
    @Binding var name             : String
    let event                     : LifeEvent
    
    var body: some View {
        if event.isAdultEvent {
            // événement pour adulte seulement
            return Picker(selection: $name, label: Text("Personne")) {
                ForEach(family.members.filter {$0 is Adult}) { person in
                    PersonNameRow(member: person)
                }
            }
        } else if event.isChildEvent {
            // événement pour enfant seulement
            return Picker(selection: $name, label: Text("Personne")) {
                ForEach(family.members.filter {$0 is Child}) { person in
                    PersonNameRow(member: person)
                }
            }
        } else {
            // événement pour les deux
            return Picker(selection: $name, label: Text("Personne")) {
                ForEach(family.members) { person in
                    PersonNameRow(member: person)
                }
            }
        }
    }
}

struct PersonNameRow : View {
    var member: Person
    
    var body: some View {
        Label(member.displayName, systemImage: "person.fill")
        .tag(member.displayName)
    }
}

struct PersonPickerView_Previews: PreviewProvider {
    static var family = Family()

    static var previews: some View {
        Group {
            PersonPickerView(name: .constant("name"),
                             event: .cessationActivite)
                .environmentObject(family)
            PersonPickerView(name: .constant("name"),
                             event: .deces)
                .environmentObject(family)
        }
    }
}
