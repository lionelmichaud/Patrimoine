//
//  FamilyMasterView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 08/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct FamilyListView : View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState

    var body: some View {
        Section {
            ForEach(family.members) { member in
                NavigationLink(destination: MemberDetailView().environmentObject(member)) {
                    MemberRowView(member: member)
                }
                .isDetailLink(true)
            }
            .onDelete(perform: deleteMembers)
            .onMove(perform: family.moveMembers)
        }
    }
    
    func deleteMembers(at offsets: IndexSet) {
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()
        // supprimer le membre de la famille
        family.deleteMembers(at: offsets)
    }
}

struct MemberRowView : View {
    var member: Person
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(member.displayName)
                .font(.headline)
            MemberAgeDateView(member: member)
                .font(.caption)
        }
    }
}

struct MemberAgeDateView : View {
    var member    : Person
    
    var body: some View {
        AgeDateView(ageLabel: (member.sexe == .male ? "Agé de" : "Agée de"),
                    dateLabel: (member.sexe == .male ? "Né le" : "Née le"),
                    age: member.ageComponents.year!,
                    date: member.displayBirthDate)
            .foregroundColor(.secondary)
    }
}

struct AgeDateView : View {
    var ageLabel  : String
    var dateLabel : String
    var age: Int
    var date: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(ageLabel)
                Spacer()
                Text("\(age) ans")
                    .foregroundColor(.primary)
            }
            HStack {
                Text(dateLabel)
                Spacer()
                Text(date).foregroundColor(.primary)
            }
        }
    }
}

struct FamilyListView_Previews: PreviewProvider {
    static var family  = Family()
    
    static var previews: some View {
        NavigationView {
            FamilyListView()
                .environmentObject(family)
        }
    }
}
