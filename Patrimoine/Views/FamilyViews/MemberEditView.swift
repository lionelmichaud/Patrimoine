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
    @ObservedObject var personViewModel = PersonViewModel()
    // Child
    @State private var ageUniversity   = ScenarioCst.minAgeUniversity
    @State private var ageIndependance = ScenarioCst.minAgeIndependance
    // Adult
    @ObservedObject var adultViewModel = AdultViewModel()

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
                    AdultEditView(personViewModel: personViewModel,
                                  adultViewModel : adultViewModel)

                } else if member is Child {
                    ChildEditView(birthDate       : member.birthDate,
                                  deathAge        : $personViewModel.deathAge,
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
        personViewModel.deathAge = member.ageOfDeath
        // Child
        if let child = member as? Child {
            _ageUniversity   = State(initialValue: child.ageOfUniversity)
            _ageIndependance = State(initialValue: child.ageOfIndependence)
        }
        // Adult
        if let adult = member as? Adult {
            adultViewModel.dateRetirement            = adult.dateOfRetirement
            adultViewModel.nbYearOfDepend            = adult.nbOfYearOfDependency
            adultViewModel.ageAgircPension           = adult.ageOfAgircPensionLiquidComp.year!
            adultViewModel.trimAgircPension          = adult.ageOfAgircPensionLiquidComp.month! / 3
            adultViewModel.agePension                = adult.ageOfPensionLiquidComp.year!
            adultViewModel.trimPension               = adult.ageOfPensionLiquidComp.month! / 3
            adultViewModel.lastKnownPensionSituation = adult.lastKnownPensionSituation
            adultViewModel.lastKnownAgircSituation = adult.lastKnownAgircPensionSituation
            switch adult.initialPersonalIncome {
                case let .salary(netSalary, healthInsurance):
                    adultViewModel.revenue   = netSalary
                    adultViewModel.insurance = healthInsurance
                    adultViewModel.revIndex  = PersonalIncomeType.salary(netSalary: 0, healthInsurance: 0).id
                case let .turnOver(BNC, incomeLossInsurance):
                    adultViewModel.revenue   = BNC
                    adultViewModel.insurance = incomeLossInsurance
                    adultViewModel.revIndex  = PersonalIncomeType.turnOver(BNC: 0, incomeLossInsurance: 0).id
                case .none:
                    adultViewModel.revenue   = 0.0
                    adultViewModel.insurance = 0.0
                    adultViewModel.revIndex  = 0
            }
        }
    }

    func applyChanges() {
        member.ageOfDeath = personViewModel.deathAge
        if let adult = member as? Adult {
            adult.dateOfRetirement     = adultViewModel.dateRetirement
            adult.nbOfYearOfDependency = adultViewModel.nbYearOfDepend
            adult.setAgeOfPensionLiquidComp(year  : adultViewModel.agePension,
                                            month : adultViewModel.trimPension * 3)
            adult.setAgeOfAgircPensionLiquidComp(year  : adultViewModel.ageAgircPension,
                                                 month : adultViewModel.trimAgircPension * 3)
            adult.lastKnownPensionSituation = adultViewModel.lastKnownPensionSituation
            adult.lastKnownAgircPensionSituation = adultViewModel.lastKnownAgircSituation
            if adultViewModel.revIndex == PersonalIncomeType.salary(netSalary       : 0,
                                                                    healthInsurance : 0).id {
                adult.initialPersonalIncome = PersonalIncomeType.salary(netSalary       : adultViewModel.revenue,
                                                                        healthInsurance : adultViewModel.insurance)
            } else {
                adult.initialPersonalIncome = PersonalIncomeType.turnOver(BNC                 : adultViewModel.revenue,
                                                                          incomeLossInsurance : adultViewModel.insurance)
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
