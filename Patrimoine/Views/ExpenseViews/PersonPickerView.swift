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
    let event    : LifeEvent
    
    var body: some View {
        if event.isAdultEvent {
            // événement pour adulte seulement
            return Picker(selection: $name, label: Text("Personne")) {
                ForEach(family.members.filter {$0 is Adult}, id: \.self) { person in
                    Row(member: person)
                }
            }
        } else if event.isChildEvent {
            // événement pour enfant seulement
            return Picker(selection: $name, label: Text("Personne")) {
                ForEach(family.members.filter {$0 is Child}, id: \.self) { person in
                    Row(member: person)
                }
            }
        } else {
            // événement pour les deux
            return Picker(selection: $name, label: Text("Personne")) {
                ForEach(family.members, id: \.self) { person in
                    Row(member: person)
                }
            }
        }
    }
}

fileprivate struct Row : View {
    var member: Person
    
    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .padding(.trailing)
                .foregroundColor(Color.blue)
            Text(member.displayName)
        }
        .tag(member.displayName)
    }
}

struct PersonPickerView_Previews: PreviewProvider {
    static var previews: some View {
        PersonPickerView(name: .constant("name"),
                         event: .cessationActivite)
    }
}
