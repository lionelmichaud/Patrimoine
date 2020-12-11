//
//  FamilyDetailView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - Afficher les détails d'un membre de la famille

struct MemberDetailView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var member     : Person
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @State var showingSheet = false
    
    var body: some View {
        Form {
            Text(member.displayName).font(.headline)
            
            /// partie commune
            MemberAgeDateView(member: member)
            
            if let adult = member as? Adult {
                /// partie spécifique adulte
                HStack {
                    Text("Nombre d'enfants")
                    Spacer()
                    Text("\(adult.nbOfChildBirth)")
                }
                AdultDetailView()
                
            } else if member is Child {
                /// partie spécifique enfant
                ChildDetailView()
            }
        }
        .sheet(isPresented: $showingSheet) {
            MemberEditView(withInitialValueFrom: self.member)
            //                .environmentObject(self.family)
            //                .environmentObject(self.patrimoine)
            //                .environmentObject(self.simulation)
            //                .environmentObject(self.uiState)
        }
        .navigationTitle("Membre")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: Button(
                action: { withAnimation { self.showingSheet = true } },
                label : { Text("Modifier") }
            )
            .capsuleButtonStyle()
        )
    }
}

struct FamilyDetailView_Previews: PreviewProvider {
    static var family  = Family()
    
    static var previews: some View {
        let aMember = family.members.first!
        
        return Group {
            MemberDetailView()
                .environmentObject(family)
                .environmentObject(aMember)
            MemberDetailView()
                .environmentObject(family)
                .environmentObject(aMember)
        }
        
    }
}
