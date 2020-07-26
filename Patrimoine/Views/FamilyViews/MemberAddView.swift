//
//  FamilyAddView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: -  Person View Model
class PersonViewModel: ObservableObject {
    @Published var familyName = ""
    @Published var givenName  = ""
    @Published var sexe       = Sexe.male
    @Published var seniority  = Seniority.adult
    @Published var birthDate  = Date()
    @Published var deathAge   = 81
}

// MARK: -  Adult View Model
class AdultViewModel: ObservableObject {
    @Published var dateRetirement            = Date()
    @Published var causeOfRetirement         = Unemployment.Cause.demission
    @Published var hasAllocationSupraLegale  = false
    @Published var allocationSupraLegale     = 0.0
    //@Published var dateOfEndOfUnemployAlloc  = Date()
    @Published var ageAgircPension           = Pension.model.regimeGeneral.model.ageMinimumLegal
    @Published var trimAgircPension          = 0
    @Published var agePension                = Pension.model.regimeGeneral.model.ageMinimumLegal
    @Published var trimPension               = 0
    @Published var nbYearOfDepend            = 0
    @Published var revIndex                  = 0
    @Published var revenueBrut               = 0.0
    @Published var revenueTaxable            = 0.0
    @Published var revenueNet                = 0.0
    @Published var fromDate                  = Date.now
    @Published var insurance                 = 0.0
    @Published var lastKnownPensionSituation = RegimeGeneralSituation()
    @Published var lastKnownAgircSituation   = RegimeAgircSituation()
}

// MARK: - Saisie du nouveau membre de la famille
struct MemberAddView: View {
    //@Environment(\.managedObjectContext) var moc
    @EnvironmentObject var family: Family
    @Environment(\.presentationMode) var presentationMode
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
                Text("Ajouter...").font(.title).fontWeight(.bold)
                Spacer()
                Button(
                    action: addMember,
                    label: {
                        Text("OK")
                            .bold()
                            .padding(.vertical, 2.0)
                            .padding(.horizontal, 8.0)
                            .background(Capsule(style: .circular).stroke(formIsValid() ? Color.blue : Color.gray, lineWidth: 2))
                } )
                    .disabled(!formIsValid())
            }.padding(.horizontal).padding(.top)
            
            Form {
                CiviliteEditView(personViewModel: personViewModel)
                
                if formIsValid() {
                    if personViewModel.seniority == .adult {
                        AdultEditView(personViewModel: personViewModel,
                                      adultViewModel : adultViewModel)
                        
                    } else {
                        ChildEditView(birthDate       : personViewModel.birthDate,
                                      deathAge        : $personViewModel.deathAge,
                                      ageUniversity   : $ageUniversity,
                                      ageIndependance : $ageIndependance)
                    }
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    /// Création du nouveau membre et ajout à la famille
    func addMember() {
        switch personViewModel.seniority {
            case .adult  :
                // creation du nouveau membre
                let newMember = Adult(sexe       : personViewModel.sexe,
                                      givenName  : personViewModel.givenName,
                                      familyName : personViewModel.familyName.uppercased(),
                                      birthDate  : personViewModel.birthDate,
                                      ageOfDeath : personViewModel.deathAge)
                newMember.dateOfRetirement     = adultViewModel.dateRetirement
                newMember.causeOfRetirement    = adultViewModel.causeOfRetirement
                if (adultViewModel.causeOfRetirement == Unemployment.Cause.demission) {
                    // pas d'indemnité de licenciement en cas de démission
                    newMember.layoffCompensationBonified = nil
                } else {
                    if adultViewModel.hasAllocationSupraLegale {
                        // indemnité supra-légale de licenciement accordée par l'employeur
                        newMember.layoffCompensationBonified = adultViewModel.allocationSupraLegale
                    } else {
                        // pas d'indemnité supra-légale de licenciement
                        newMember.layoffCompensationBonified = nil
                    }
                }

                newMember.setAgeOfPensionLiquidComp(year  : adultViewModel.agePension,
                                                    month : adultViewModel.trimPension * 3)
                newMember.setAgeOfAgircPensionLiquidComp(year  : adultViewModel.ageAgircPension,
                                                         month : adultViewModel.trimAgircPension * 3)
                newMember.lastKnownPensionSituation = adultViewModel.lastKnownPensionSituation
                newMember.lastKnownAgircPensionSituation = adultViewModel.lastKnownAgircSituation
                
                if adultViewModel.revIndex == PersonalIncomeType.salaryId {
                    newMember.workIncome =
                        PersonalIncomeType.salary(brutSalary      : adultViewModel.revenueBrut,
                                                  taxableSalary   : adultViewModel.revenueTaxable,
                                                  netSalary       : adultViewModel.revenueNet,
                                                  fromDate        : adultViewModel.fromDate,
                                                  healthInsurance : adultViewModel.insurance)
                } else {
                    newMember.workIncome =
                        PersonalIncomeType.turnOver(BNC                 : adultViewModel.revenueBrut,
                                                    incomeLossInsurance : adultViewModel.insurance)
                }
                
                newMember.nbOfYearOfDependency = adultViewModel.nbYearOfDepend

                // ajout du nouveau membre à la famille
                family.addMember(newMember)
                // debug
                //print(family)
            
            case .enfant :
                // creation du nouveau membre
                let newMember = Child(sexe       : personViewModel.sexe,
                                      givenName  : personViewModel.givenName,
                                      familyName : personViewModel.familyName.uppercased(),
                                      birthDate  : personViewModel.birthDate,
                                      ageOfDeath : personViewModel.deathAge)
                newMember.ageOfUniversity = ageUniversity
                newMember.ageOfIndependence = ageIndependance
                // ajout du nouveau membre à la famille
                family.addMember(newMember)
                // debug
                //print(family)
            
        }
        
        self.presentationMode.wrappedValue.dismiss()
    }
    
    /// Vérifie que la formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    func formIsValid() -> Bool {
        if personViewModel.familyName.allSatisfy({ $0 == " " }) ||
            personViewModel.givenName.allSatisfy({ $0 == " " })            // genre.allSatisfy({ $0 == " " })
        {
            return false
        }
        return true
    }
}


// MARK: - Saisie des civilités du nouveau membre
struct CiviliteEditView : View {
    @ObservedObject var personViewModel: PersonViewModel

    var body: some View {
        Section {
            CasePicker(pickedCase: $personViewModel.sexe, label: "Genre")
                .pickerStyle(SegmentedPickerStyle())
            CasePicker(pickedCase: $personViewModel.seniority, label: "Seniorité")
                .pickerStyle(SegmentedPickerStyle())
            HStack {
                Text("Nom")
                    .frame(width: 70, alignment: .leading)
                TextField("obligatoire", text: $personViewModel.familyName)
            }
            HStack {
                Text("Prénom")
                    .frame(width: 70, alignment: .leading)
                TextField("obligatoire", text: $personViewModel.givenName)
            }
            DatePicker(selection: $personViewModel.birthDate,
                       in: 100.years.ago!...Date(),
                       displayedComponents: .date,
                       label: { Text("Date de naissance") })
        }
    }
}

struct MemberAddView_Previews: PreviewProvider {
    static var family  = Family()

    static var previews: some View {
            MemberAddView()
                .environmentObject(family)
    }
}

