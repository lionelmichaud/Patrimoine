//
//  BoundaryEditView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 18/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - View Model for BoundaryEditView

struct DateBoundaryViewModel: Equatable {
    
    // MARK: - Properties
    
    var fixedYear       : Int
    var event           : LifeEvent
    var isLinkedToEvent : Bool
    var name            : String
    var group           : GroupOfPersons
    var isLinkedToGroup : Bool
    var order           : SoonestLatest
    
    // MARK: - Computed Properties
    
    // vérifier qu'il est possible de calculer l'année de la borne temporelle
    var boundaryYearIsComputable: Bool {
        if isLinkedToEvent {
            if isLinkedToGroup {
                return true
            } else {
                return name != ""
            }
        } else {
            return true
        }
    }
    
    // date fixe ou calculée à partir d'un éventuel événement de vie d'une personne
    var year  : Int? {
        if isLinkedToEvent {
            // la borne temporelle est accrochée à un événement
            var persons: [Person]?
            if isLinkedToGroup {
                // l'événement est accroché à un groupe
                // construire un tableau des membres du groupe
                switch group {
                    case .allAdults:
                        guard !event.isChildEvent else {
                            return nil
                        }
                        persons = LifeExpense.family?.adults
                        
                    case .allChildrens:
                        guard !event.isAdultEvent else {
                            return nil
                        }
                        persons = LifeExpense.family?.children
                        
                    case .allPersons:
                        guard !event.isChildEvent && !event.isAdultEvent else {
                            return nil
                        }
                        persons = LifeExpense.family?.members
                }
                // rechercher l'année au plus tôt ou au plus tard
                if let years = persons?.map({ $0.yearOf(event: event)! }) {
                    switch order {
                        case .soonest:
                            return years.min()
                        case .latest:
                            return years.max()
                    }
                } else {
                    // on ne trouve pas l'année
                    return nil
                }
                
            } else {
                // l'événement est accroché à une personne
                // rechercher la personne
                if let person = LifeExpense.family?.member(withName: name) {
                    // rechercher l'année de l'événement pour cette personne
                    return person.yearOf(event: event)
                } else {
                    // on ne trouve pas le nom de la personne dans la famille
                    return nil
                }
                
            }
            
        } else {
            // pas d'événement, la date est fixe
            return fixedYear
        }
    }
    
    // construire l'objet de type DateBoundary correspondant au ViewModel
    var dateBoundary: DateBoundary {
        var _event : LifeEvent?
        var _name  : String?
        var _group : GroupOfPersons?
        var _order : SoonestLatest?
        
        if isLinkedToEvent {
            _event = self.event
            if isLinkedToGroup {
                _name  = nil
                _group = self.group
                _order = self.order
            } else {
                _name  = self.name
                _group = nil
                _order = nil
            }
            
        } else {
            _event = nil
            _name  = nil
            _group = nil
            _order = nil
        }
        return DateBoundary(fixedYear : fixedYear,
                            event     : _event,
                            name      : _name,
                            group     : _group,
                            order     : _order)
    }
    
    var description : String {
        guard let year = self.year else {
            return "indéfini"
        }
        var description: String = ""
        
        if isLinkedToEvent {
            description = event.displayString + " de "
            if isLinkedToGroup {
                description += group.displayString + (order == .soonest ? " (-)" : " (+)")
                
            } else {
                description += name
            }
            return description + ": " + String(year)
            
        } else {
            return String(year)
        }
    }

    // MARK: - Initializers of ViewModel from Model
    
    internal init(from dateBoundary: DateBoundary) {
        self.fixedYear       = dateBoundary.fixedYear
        self.event           = dateBoundary.event ?? .deces
        self.isLinkedToEvent = dateBoundary.event != nil
        self.name            = dateBoundary.name ?? ""
        self.group           = dateBoundary.group ?? .allAdults
        self.isLinkedToGroup = dateBoundary.group != nil
        self.order           = dateBoundary.order ?? .soonest
    }
}
    
// MARK: - View

struct BoundaryEditView: View {
    @EnvironmentObject var family         : Family

    // MARK: - Properties

    let label                             : String
    @Binding var boundaryVM               : DateBoundaryViewModel
    @State private var presentGroupPicker : Bool = false // pour affichage local
    
    // MARK: - Computed Properties
    
    var body: some View {
        Section(header: Text("\(label) de période")) {
            /// la date est-elle liée à un événement ?
            Toggle(isOn: $boundaryVM.isLinkedToEvent, label: { Text("Associé à un événement") })
                .onChange(of: boundaryVM.isLinkedToEvent, perform: updateIsLinkedToEvent)

            if boundaryVM.isLinkedToEvent {
                /// la date est liée à un événement:
                /// choisir le type d'événement
                CasePicker(pickedCase: $boundaryVM.event, label: "Nature de cet événement")
                    .onChange(of: boundaryVM.event, perform: updateGroup)

                /// choisir à quoi associer l'événement: personne ou groupe
                Toggle(isOn: $boundaryVM.isLinkedToGroup) { Text("Associer cet évenement à un groupe") }
                    .onChange(of: boundaryVM.isLinkedToGroup, perform: updateGroup)
                
                if boundaryVM.isLinkedToGroup {
                    /// choisir le type de groupe si nécessaire
                    if presentGroupPicker {
                        CasePicker(pickedCase: $boundaryVM.group, label: "Groupe associé")
                    } else {
                        LabeledText(label: "Groupe associé", text: boundaryVM.group.displayString).foregroundColor(.secondary)
                    }
                    CasePicker(pickedCase: $boundaryVM.order, label: "Ordre")
                    
                } else {
                    /// choisir la personne
                    PersonPickerView(name: $boundaryVM.name, event: boundaryVM.event)
                }
                /// afficher la date résultante
                if boundaryYear() == -1 {
                    Text("Choisir un événement et la personne ou le groupe associé")
                        .foregroundColor(.red)
                } else {
                    IntegerView(label: "\(label) (année inclue)", integer: boundaryYear()).foregroundColor(.secondary)
                }

            } else {
                /// choisir une date absolue
                IntegerEditView(label: "\(label) (année inclue)", integer: $boundaryVM.fixedYear)
            }
        }
    }
    
    // MARK: - Initializers
    
    init(label    : String,
         boundary : Binding<DateBoundaryViewModel?>) {
        self.label  = label
        _boundaryVM = boundary ?? DateBoundaryViewModel(from: DateBoundary.empty)
    }
    init(label    : String,
         boundary : Binding<DateBoundaryViewModel>) {
        self.label  = label
        _boundaryVM = boundary
    }
    
    // MARK: - Methods
    
    func updateIsLinkedToEvent(newIsLinkedToEvent: Bool) {
        if !newIsLinkedToEvent {
            boundaryVM.fixedYear = Date.now.year
        }
    }
    
    func updateGroup(isAssociatedToGroup: Bool) {
        if isAssociatedToGroup {
            if boundaryVM.event.isAdultEvent {
                boundaryVM.group   = .allAdults
                presentGroupPicker = false
                
            } else if boundaryVM.event.isChildEvent {
                boundaryVM.group   = .allChildrens
                presentGroupPicker = false
                
            } else {
                presentGroupPicker = true
            }
        }
    }
    
    func updateGroup(newEvent: LifeEvent) {
        if boundaryVM.isLinkedToGroup {
            if newEvent.isAdultEvent {
                boundaryVM.group   = .allAdults
                presentGroupPicker = false
                
            } else if newEvent.isChildEvent {
                boundaryVM.group   = .allChildrens
                presentGroupPicker = false
                
            } else {
                presentGroupPicker = true
            }
        }
    }
    
    func boundaryDateIsComputable() -> Bool {
        return boundaryVM.boundaryYearIsComputable
    }
    
    func boundaryYear() -> Int {
        return boundaryVM.year ?? -1
    }
}
