//
//  MemberEditView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 19/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct MemberEditView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var member     : Person
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @Environment(\.presentationMode) var presentationMode
    @State var showingSheet = false
    // Person
    @State private var deathAge : Int
    // Child
    @State private var ageUniversity   = ScenarioCst.minAgeUniversity
    @State private var ageIndependance = ScenarioCst.minAgeIndependance
    // Adult
    @State private var dateRetirement = Date()
    @State private var agePension     = RetirmentCst.minAgepension
    @State private var nbYearOfDepend = 0
    @State private var revIndex       = 0
    @State private var revenue        = 0.0
    @State private var insurance      = 0.0

    var body: some View {
        VStack() {
            HStack() {
                Button(
                    action: { self.presentationMode.wrappedValue.dismiss() },
                    label: {
                        Text("Annuler")
                } )
                Spacer()
                Text("Modifier...").font(.title).fontWeight(.bold)
                Spacer()
                Button(
                    action: applyChanges,
                    label: {
                        Text("OK")
                } )
                    .disabled(false)
            }.padding(.horizontal).padding(.top)
            
            Form {
                Text(member.displayName).font(.headline)
                MemberAgeDateView(member: member).foregroundColor(.gray)
                if member is Adult {
                    HStack {
                        Text("Nombre d'enfants")
                        Spacer()
                        Text("\((member as! Adult).nbOfChildBirth)")
                    }
                    AdultEditView(birthDate      : member.birthDate,
                                  deathAge       : $deathAge,
                                  dateRetirement : $dateRetirement,
                                  agePension     : $agePension,
                                  nbYearOfDepend : $nbYearOfDepend,
                                  revIndex       : $revIndex,
                                  revenue        : $revenue,
                                  insurance      : $insurance)
                    
                } else if member is Child {
                    ChildEditView(birthDate       : member.birthDate,
                                  deathAge        : $deathAge,
                                  ageUniversity   : $ageUniversity,
                                  ageIndependance : $ageIndependance)
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .avoidKeyboard()
        }
    }
    
    init(withInitialValueFrom member: Person) {
        // Person
        _deathAge = State(initialValue: member.ageOfDeath)
        // Child
        if let child = member as? Child {
            _ageUniversity   = State(initialValue: child.ageOfUniversity)
            _ageIndependance = State(initialValue: child.ageOfIndependence)
        }
        // Adult
        if let adult = member as? Adult {
            _dateRetirement = State(initialValue: adult.dateOfRetirement)
            _nbYearOfDepend = State(initialValue: adult.nbOfYearOfDependency)
            _agePension     = State(initialValue: adult.ageOfPensionLiquidComp.year!)
            switch adult.initialPersonalIncome {
                case let .salary(netSalary, healthInsurance):
                    _revenue   = State(initialValue: netSalary)
                    _insurance = State(initialValue: healthInsurance)
                    _revIndex = State(initialValue: PersonalIncomeType.salary(netSalary: 0, healthInsurance: 0).id)
                case let .turnOver(BNC, incomeLossInsurance):
                    _revenue   = State(initialValue: BNC)
                    _insurance = State(initialValue: incomeLossInsurance)
                    _revIndex = State(initialValue: PersonalIncomeType.turnOver(BNC: 0, incomeLossInsurance: 0).id)
                case .none:
                    _revenue   = State(initialValue: 0.0)
                    _insurance = State(initialValue: 0.0)
                    _revIndex  = State(initialValue: 0)
            }
        }
    }

    func applyChanges() {
        member.ageOfDeath = deathAge
        if let adult = member as? Adult {
            adult.dateOfRetirement     = dateRetirement
            adult.nbOfYearOfDependency = nbYearOfDepend
            adult.setAgeOfPensionLiquidComp(year: agePension)
            if revIndex == PersonalIncomeType.salary(netSalary: 0, healthInsurance: 0).id {
                adult.initialPersonalIncome = PersonalIncomeType.salary(netSalary: revenue,
                                                                        healthInsurance: insurance)
            } else {
                adult.initialPersonalIncome = PersonalIncomeType.turnOver(BNC: revenue,
                                                                          incomeLossInsurance: insurance)
            }

        }
        if let child = member as? Child {
            child.ageOfUniversity = ageUniversity
            child.ageOfIndependence = ageIndependance

        }
        
        // mettre à jour le nombre d'enfant de chaque parent de la famille
        family.aMemberIsUpdated()
        
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.simulationViewState.selectedItem = nil

        self.presentationMode.wrappedValue.dismiss()
    }
}

struct MemberEditView_Previews: PreviewProvider {
    static var family  = Family()
    static var aMember = family.members.first!
    
    static var previews: some View {
        //EmptyView()
        MemberEditView(withInitialValueFrom: aMember)
            .environmentObject(family)
            .environmentObject(aMember)
    }
}
