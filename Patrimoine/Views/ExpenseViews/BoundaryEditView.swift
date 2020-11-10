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
    let label              : String
    @Binding var isLinked  : Bool
    @Binding var fixedYear : Int
    @Binding var event     : LifeEvent
    @Binding var name      : String
    @Binding var group     : GroupOfPersons
    @Binding var order     : SoonestLatest
    @State private var variableYear       : Int            = 0 // pour affichage local
    @State private var associatedToGroup  : Bool           = false // pour affichage local
    @State private var presentGroupPicker : Bool           = false // pour affichage local

    // calculer la date de l'événement
    var choosenName: Binding<String> {
        return Binding<String> (
            get: { return (self.name) },
            set: { name in
                self.name = name
                self.variableYear = self.yearOfEventFor(name: self.name)
                }
            )
    }

    var body: some View {
        Section(header: Text("\(label) de période")) {
            /// la date est-elle liée à un événement ?
            Toggle(isOn: $isLinked, label: { Text("Associé à un événement") })
            if isLinked {
                /// la date est liée à un événement:
                /// choisir le type d'événement
                CasePicker(pickedCase: $event, label: "Nature de cet événement")
                    .onChange(of: event, perform: updateGroup)
                /// choisir à quoi associer l'événement: personne ou groupe
                Toggle(isOn: $associatedToGroup) { Text("Associer cet évenement à un groupe") }
                    .onChange(of: associatedToGroup, perform: updateGroup)
                if associatedToGroup {
                    /// choisir le type de groupe si nécessaire
                    if presentGroupPicker {
                        CasePicker(pickedCase: $group, label: "Groupe associé")
                    } else {
                        LabeledText(label: "Groupe associé", text: group.displayString).foregroundColor(.secondary)
                    }
                    CasePicker(pickedCase: $order, label: "Ordre")
                } else {
                    /// choisir la personne
                    PersonPickerView(name: choosenName, event: event)
                    /// afficher la date résultante
                    if (-1...0).contains(variableYear) {
                        Text("Choisir un événement et la personne associée")
                            .foregroundColor(.red)
                    } else {
                        IntegerView(label: "\(label) (année inclue)", integer: variableYear).foregroundColor(.secondary)
                    }
                }
                
            } else {
                /// choisir une date absolue
                IntegerEditView(label: "\(label) (année inclue)", integer: $fixedYear)
            }
        }.onAppear(perform: initializeLocalvariables)
    }
    
    func updateGroup(isAssociatedToGroup: Bool) {
        if isAssociatedToGroup {
            if event.isAdultEvent {
                group              = .allAdults
                presentGroupPicker = false
                
            } else if event.isChildEvent {
                group              = .allChildrens
                presentGroupPicker = false

            } else {
                presentGroupPicker = true
            }
        }
    }
    
    func updateGroup(newEvent: LifeEvent) {
        if associatedToGroup {
            if newEvent.isAdultEvent {
                group              = .allAdults
                presentGroupPicker = false
                
            } else if newEvent.isChildEvent {
                group              = .allChildrens
                presentGroupPicker = false
                
            } else {
                presentGroupPicker = true
            }
        }
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
