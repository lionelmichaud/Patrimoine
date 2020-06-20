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

// MARK: - Saisie du nouveau membre de la famille
struct MemberAddView: View {
    //@Environment(\.managedObjectContext) var moc
    @EnvironmentObject var family: Family
    @Environment(\.presentationMode) var presentationMode
    // Person
    @State private var familyName = ""
    @State private var givenName  = ""
    @State private var sexe       = Sexe.male
    @State private var seniority  = Seniority.adult
    @State private var birthDate  = Date()
    @State private var deathAge   = 81
    // Child
    @State private var ageUniversity   = ScenarioCst.minAgeUniversity
    @State private var ageIndependance = ScenarioCst.minAgeIndependance
    // Adult
    @State private var dateRetirement = Date()
    @State private var agePension     = RetirmentCst.minAgepension
    @State private var revIndex      = 0
    @State private var revenue       = 0.0
    @State private var insurance     = 0.0

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
                CiviliteEditView(familyName : $familyName,
                                 givenName  : $givenName,
                                 sexe       : $sexe,
                                 seniority  : $seniority,
                                 birthDate  : $birthDate)
                
                if formIsValid() {
                    if seniority == .adult {
                        AdultEditView(birthDate      : birthDate,
                                      deathAge       : $deathAge,
                                      dateRetirement : $dateRetirement,
                                      agePension     : $agePension,
                                      revIndex       : $revIndex,
                                      revenue        : $revenue,
                                      insurance      : $insurance)
                        
                    } else {
                        ChildEditView(birthDate       : birthDate,
                                      deathAge        : $deathAge,
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
        switch seniority {
            case .adult  :
                // creation du nouveau membre
                let newMember = Adult(sexe: sexe, givenName: givenName, familyName: familyName.uppercased(), birthDate: birthDate, ageOfDeath: deathAge)
                newMember.dateOfRetirement = dateRetirement
                newMember.setAgeOfPensionLiquidComp(year: agePension)
                if revIndex == PersonalIncomeType.salary(netSalary: 0, healthInsurance: 0).id {
                    newMember.initialPersonalIncome = PersonalIncomeType.salary(netSalary: revenue,
                                                                                healthInsurance: insurance)
                } else {
                    newMember.initialPersonalIncome = PersonalIncomeType.turnOver(BNC: revenue,
                                                                                  incomeLossInsurance: insurance)
                }
                // ajout du nouveau membre à la famille
                family.addMember(newMember)
                // debug
                //print(family)
            case .enfant :
                // creation du nouveau membre
                let newMember = Child(sexe: sexe, givenName: givenName, familyName: familyName.uppercased(), birthDate: birthDate, ageOfDeath: deathAge)
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
        if familyName.allSatisfy({ $0 == " " }) ||
            givenName.allSatisfy({ $0 == " " })            // genre.allSatisfy({ $0 == " " })
        {
            return false
        }
        return true
    }
}


// MARK: - Saisie des civilités du nouveau membre
struct CiviliteEditView : View {
    @Binding var familyName : String
    @Binding var givenName  : String
    @Binding var sexe       : Sexe
    @Binding var seniority  : Seniority
    @Binding var birthDate  : Date
    
    var body: some View {
        Section {
            CasePicker(pickedCase: $sexe, label: "Genre")
                .pickerStyle(SegmentedPickerStyle())
            CasePicker(pickedCase: $seniority, label: "Seniorité")
                .pickerStyle(SegmentedPickerStyle())
            HStack {
                Text("Nom")
                    .frame(width: 70, alignment: .leading)
                TextField("obligatoire", text: $familyName)
            }
            HStack {
                Text("Prénom")
                    .frame(width: 70, alignment: .leading)
                TextField("obligatoire", text: $givenName)
            }
            DatePicker(selection: $birthDate,
                       in: 100.years.ago!...Date(),
                       displayedComponents: .date,
                       label: { Text("Date de naissance") })
        }
    }
}

// MARK: - Saisie adulte
struct AdultEditView : View {
    let birthDate               : Date
    @Binding var deathAge       : Int
    @Binding var dateRetirement : Date
    @Binding var agePension     : Int
    @Binding var revIndex       : Int
    @Binding var revenue        : Double
    @Binding var insurance      : Double
    
    var body: some View {
        Group() {
            Section(header: Text("SCENARIO").font(.subheadline)) {
                Stepper(value: $deathAge, in: Date().year - birthDate.year ... 100) {
                    HStack {
                        Text("Age de décès estimé ")
                        Spacer()
                        Text("\(deathAge) ans").foregroundColor(.secondary)
                    }
                }
            }
            Section(header:Text("Retraite")) {
                DatePicker(selection: $dateRetirement,
                           in: Date()...100.years.fromNow! ,
                           displayedComponents: .date,
                           label: { Text("Date de cessation d'activité") })
                Stepper(value: $agePension, in: RetirmentCst.minAgepension ... RetirmentCst.maxAgepension) {
                    HStack {
                        Text("Liquidation de pension ")
                        Spacer()
                        Text("\(agePension) ans").foregroundColor(.secondary)
                    }
                }
            }
            // revenus
            Section(header: Text("Revenus")) {
                RevenueEditView(revIndex: $revIndex,
                                revenue: $revenue,
                                insurance: $insurance)
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
