//
//  BoundaryEditView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 18/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct BoundaryEditView: View {
    @EnvironmentObject var family: Family
    let label : String
    @Binding var event    : LifeEvent
    @Binding var isLinked : Bool
    @Binding var year     : Int
    @Binding var name     : String
    @State private var variableYear: Int = 0 // pour affichage local
    
    // calculer la date de l'événement
    var choosenName: Binding<String> {
        return Binding<String> (
            get: { return self.name },
            set: { name in
                self.name = name
                self.variableYear = self.yearOfEventFor(name: self.name)
                }
            )
    }

    var body: some View {
        Section(header: Text("\(label) de période")) {
            // la dete est-elle liée à un événement ?
            Toggle(isOn: $isLinked, label: { Text("Associé à un événement") })
            if isLinked {
                // la dete est liée à un événement
                CasePicker(pickedCase: $event, label: "Nature de l'événement")
                // choisir la personne
                PersonPickerView(name: choosenName, event: event)
                // afficher la date résultante
                if variableYear == 0 {
                    Text("Choisir un événement et la personne associée")
                } else {
                    IntegerView(label: "\(label) (année inclue)", integer: variableYear).foregroundColor(.secondary)
                }
            } else {
                // choisir une date absolue
                IntegerEditView(label: "\(label) (année inclue)", integer: $year)
            }
        }.onAppear(perform: initializeLocalvariables)
    }
    
    func initializeLocalvariables() {
        self.variableYear = yearOfEventFor(name: self.name)
    }
    
    /// Recherche la date d'un évenement pour une personne d'un Nom donné
    /// - Parameter name: Nom de la personne
    /// - Returns: Date
    func yearOfEventFor(name: String) -> Int {
        // rechercher la personne
        let person = self.family.member(withName: name)
        // rechercher l'année de l'événement pour cette personne
        return person?.yearOf(event: self.event) ?? -1

    }
}
