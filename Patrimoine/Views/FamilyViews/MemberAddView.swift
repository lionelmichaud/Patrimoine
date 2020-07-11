//
//  FamilyAddView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
// https://github.com/michaelhenry/KeyboardAvoider.git
import KeyboardAvoider

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
    @Published var ageAgircPension           = Pension.model.regimeGeneral.model.ageMinimumLegal
    @Published var trimAgircPension          = 0
    @Published var agePension                = Pension.model.regimeGeneral.model.ageMinimumLegal
    @Published var trimPension               = 0
    @Published var nbYearOfDepend            = 0
    @Published var revIndex                  = 0
    @Published var revenue                   = 0.0
    @Published var insurance                 = 0.0
    @Published var lastKnownPensionSituation = RegimeGeneralSituation()
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
            .avoidKeyboard()
                //.gesture(DragGesture().onChanged{_ in UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for:
        }
    }
    
    // création du nouveau membre et ajout à la famille
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
                newMember.nbOfYearOfDependency = adultViewModel.nbYearOfDepend
                newMember.setAgeOfPensionLiquidComp(year  : adultViewModel.agePension,
                                                    month : adultViewModel.trimPension * 3)
                newMember.setAgeOfAgircPensionLiquidComp(year  : adultViewModel.ageAgircPension,
                                                         month : adultViewModel.trimAgircPension * 3)
                if adultViewModel.revIndex == PersonalIncomeType.salary(netSalary       : 0,
                                                         healthInsurance : 0).id {
                    newMember.initialPersonalIncome =
                        PersonalIncomeType.salary(netSalary       : adultViewModel.revenue,
                                                  healthInsurance : adultViewModel.insurance)
                } else {
                    newMember.initialPersonalIncome =
                        PersonalIncomeType.turnOver(BNC                 : adultViewModel.revenue,
                                                    incomeLossInsurance : adultViewModel.insurance)
                }
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

// MARK: - Saisie adulte
struct AdultEditView : View {
    @ObservedObject var personViewModel : PersonViewModel
    @ObservedObject var adultViewModel  : AdultViewModel
    
    var body: some View {
        Group {
            Section(header: Text("SCENARIO").font(.subheadline)) {
                Stepper(value: $personViewModel.deathAge, in: Date().year - personViewModel.birthDate.year ... 100) {
                    HStack {
                        Text("Age de décès estimé ")
                        Spacer()
                        Text("\(personViewModel.deathAge) ans").foregroundColor(.secondary)
                    }
                }
            }
            // revenus
            Section(header: Text("REVENUS")) {
                RevenueEditView(revIndex: $adultViewModel.revIndex,
                                revenue: $adultViewModel.revenue,
                                insurance: $adultViewModel.insurance)
            }
            // retraite
            Section(header: Text("RETRAITE")) {
                DatePicker(selection: $adultViewModel.dateRetirement,
                           in: Date()...100.years.fromNow! ,
                           displayedComponents: .date,
                           label: { Text("Date de cessation d'activité") })
            }
            RetirementEditView(personViewModel : personViewModel,
                               adultViewModel  : adultViewModel)
            // dépendance
            Section(header:Text("DEPENDANCE")) {
                Stepper(value: $adultViewModel.nbYearOfDepend, in: 0 ... 15) {
                    HStack {
                        Text("Nombre d'année de dépendance ")
                        Spacer()
                        Text("\(adultViewModel.nbYearOfDepend) ans").foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Saisie des revenus
struct RevenueEditView : View {
    @Binding var revIndex  : Int
    @Binding var revenue   : Double
    @Binding var insurance : Double
    
    var body: some View {
        Group {
            CaseWithAssociatedValuePicker<PersonalIncomeType>(caseIndex: $revIndex, label: "")
                .pickerStyle(SegmentedPickerStyle())
            
            AmountEditView(label: revIndex == PersonalIncomeType.salary(netSalary: 0, healthInsurance: 0).id ? "Salaire" : "BNC",
                           amount: $revenue)
            AmountEditView(label: revIndex == PersonalIncomeType.salary(netSalary: 0, healthInsurance: 0).id ? "Coût de la mutuelle" : "Charges sociales",
                           amount: $insurance)
        }
    }
}

// MARK: - Saisie enfant
struct ChildEditView : View {
    let birthDate                : Date
    @Binding var deathAge        : Int
    @Binding var ageUniversity   : Int
    @Binding var ageIndependance : Int
    
    var body: some View {
        Group() {
            Section(header: Text("SCENARIO").font(.subheadline)) {
                Stepper(value: $deathAge, in: Date().year - birthDate.year ... 100) {
                    HStack {
                        Text("Age de décès estimé")
                        Spacer()
                        Text("\(deathAge) ans").foregroundColor(.secondary)
                    }
                }
                Stepper(value: $ageUniversity, in: ScenarioCst.minAgeUniversity ... ScenarioCst.minAgeIndependance) {
                    HStack {
                        Text("Age d'entrée à l'université")
                        Spacer()
                        Text("\(ageUniversity) ans").foregroundColor(.secondary)
                    }
                }
                Stepper(value: $ageIndependance, in: ScenarioCst.minAgeIndependance ... 50) {
                    HStack {
                        Text("Age d'indépendance financière")
                        Spacer()
                        Text("\(ageIndependance) ans").foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct MemberAddView_Previews: PreviewProvider {
    static var family  = Family()

    static var previews: some View {
        Group {
            MemberAddView()
                .environmentObject(family)
            Form {
                RevenueEditView(revIndex: .constant(1), revenue: .constant(1234.0), insurance: .constant(5678.2))
            }
        }
    }
}

