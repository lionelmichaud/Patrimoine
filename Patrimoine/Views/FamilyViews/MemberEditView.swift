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
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @Environment(\.presentationMode) var presentationMode
    
    let member: Person
    
    @State var showingSheet = false
    // Person
    @StateObject var personViewModel: PersonViewModel
    // Child
    @State private var ageUniversity   = ScenarioCst.minAgeUniversity
    @State private var ageIndependance = ScenarioCst.minAgeIndependance
    // Adult
    @StateObject var adultViewModel = AdultViewModel()
    
    var body: some View {
        VStack() {
            /// Barre de titre
            HStack() {
                Button(action: { presentationMode.wrappedValue.dismiss() },
                       label : { Text("Annuler") } )
                    .capsuleButtonStyle()
                Spacer()
                Text("Modifier...").font(.title).fontWeight(.bold)
                Spacer()
                Button(action: applyChanges,
                       label : { Text("OK") } )
                    .capsuleButtonStyle()
                    .disabled(false)
            }.padding(.horizontal).padding(.top)
            
            /// Formulaire
            Form {
                Text(member.displayName).font(.headline)
                MemberAgeDateView(member: member).foregroundColor(.gray)
                if member is Adult {
                    /// Adulte
                    HStack {
                        Text("Nombre d'enfants")
                        Spacer()
                        Text("\((member as! Adult).nbOfChildBirth)")
                    }
                    AdultEditView(personViewModel: personViewModel,
                                  adultViewModel : adultViewModel)
                    
                } else if member is Child {
                    /// Enfant
                    ChildEditView(birthDate       : member.birthDate,
                                  deathAge        : $personViewModel.deathAge,
                                  ageUniversity   : $ageUniversity,
                                  ageIndependance : $ageIndependance)
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    /// Initialise le ViweModel à partir des propriété d'un membre existant
    /// - Parameter member: le membre de la famille
    init(withInitialValueFrom member: Person) {
        self.member = member
        // Initialize Person ViewModel
        _personViewModel = StateObject(wrappedValue: PersonViewModel(from: member))
        
        // Child
        if let child = member as? Child {
            _ageUniversity   = State(initialValue: child.ageOfUniversity)
            _ageIndependance = State(initialValue: child.ageOfIndependence)
        }
        
        // Initialize Adult ViewModel
        if let adult = member as? Adult {
            _adultViewModel = StateObject(wrappedValue: AdultViewModel(from: adult))
        }
    }
    
    /// Applique les modifications: recopie le ViewModel dans les propriétés d'un membre existant
    func applyChanges() {
        // Update Person from ViewModel
        personViewModel.updateFromViewModel(member: member)
        
        // Child
        if let child = member as? Child {
            child.ageOfUniversity   = ageUniversity
            child.ageOfIndependence = ageIndependance
        }
        
        // Update Adult from ViewModel
        if let adult = member as? Adult {
            adultViewModel.updateFromViewModel(adult: adult)
        }
        
        // mettre à jour le nombre d'enfant de chaque parent de la famille
        family.aMemberIsUpdated()
        
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()
        
        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Saisie Adult
struct AdultEditView : View {
    @ObservedObject var personViewModel        : PersonViewModel
    @ObservedObject var adultViewModel         : AdultViewModel
    @State private var compenstationSupraLegal : Bool = false
    @State private var alertItem               : AlertItem?
    
    var body: some View {
        Group {
            // Section scénario
            ScenarioSection(personViewModel : personViewModel,
                            adultViewModel  : adultViewModel)
            
            // Section activité
            ActivitySection(adultViewModel: adultViewModel)
            
            // Section retraite
            RetirementEditView(personViewModel : personViewModel,
                              adultViewModel   : adultViewModel)
            
            // Section dépendance
            DepedanceSection(adultViewModel: adultViewModel)
        }
    }
}

// MARK: - Saisie Adult / Section Scenario
fileprivate struct ScenarioSection: View {
    @ObservedObject var personViewModel : PersonViewModel
    @ObservedObject var adultViewModel  : AdultViewModel

    var body: some View {
        Section(header: Text("SCENARIO").font(.subheadline)) {
            Stepper(value: $personViewModel.deathAge, in: Date().year - personViewModel.birthDate.year ... 100) {
                HStack {
                    Text("Age de décès estimé ")
                    Spacer()
                    Text("\(personViewModel.deathAge) ans").foregroundColor(.secondary)
                }
            }
            HStack {
                Text("Option fiscale retenue en cas d'héritage")
                Spacer()
                CasePicker(pickedCase: $adultViewModel.fiscalOption, label: "Option fiscale retenue en cas d'héritage")
                    .pickerStyle(SegmentedPickerStyle())
            }
        }
    }
}

// MARK: - Saisie Adult / Section Activité
struct ActivitySection: View {
    @ObservedObject var adultViewModel: AdultViewModel
    
    var body: some View {
        Section(header: Text("ACTIVITE")) {
            RevenueEditView(adultViewModel: adultViewModel)
            EndOfWorkingPeriodEditView(adultViewModel: adultViewModel)
        }
    }
}

// MARK: - Saisie Adult / Section Dépendance
struct DepedanceSection: View {
    @ObservedObject var adultViewModel: AdultViewModel
    
    var body: some View {
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

// MARK: - Saisie Adult / Section Activité / Saisie des revenus
fileprivate struct RevenueEditView : View {
    @ObservedObject var adultViewModel: AdultViewModel
    
    var body: some View {
        let salary = adultViewModel.revIndex == WorkIncomeType.salaryId
        
        return Group {
            CaseWithAssociatedValuePicker<WorkIncomeType>(caseIndex: $adultViewModel.revIndex, label: "")
                .pickerStyle(SegmentedPickerStyle())
            if salary {
                AmountEditView(label: "Salaire brut", amount: $adultViewModel.revenueBrut)
                AmountEditView(label: "Salaire net de feuille de paye", amount: $adultViewModel.revenueNet)
                AmountEditView(label: "Salaire imposable", amount: $adultViewModel.revenueTaxable)
                AmountEditView(label: "Coût de la mutuelle (protec. sup.)", amount: $adultViewModel.insurance)
                DatePicker(selection           : $adultViewModel.fromDate,
                           in                  : 50.years.ago!...Date.now,
                           displayedComponents : .date,
                           label               : { HStack {Text("Date d'embauche"); Spacer() } })
            } else {
                AmountEditView(label: "BNC", amount: $adultViewModel.revenueBrut)
                AmountEditView(label: "Charges sociales", amount: $adultViewModel.insurance)
            }
        }
    }
}

// MARK: - Saisie Adult / Section Activité / Saisie fin de période d'activité professionnelle
fileprivate struct EndOfWorkingPeriodEditView: View {
    @ObservedObject var adultViewModel: AdultViewModel
    
    var body: some View {
        DatePicker(selection           : $adultViewModel.dateRetirement,
                   displayedComponents : .date,
                   label               : { HStack { Text("Date de cessation d'activité"); Spacer() } })
        //                    .onChange(of: adultViewModel.dateRetirement) { newState in
        //                        if (newState > (self.member as! Adult).dateOfAgircPensionLiquid) ||
        //                            (newState > (self.member as! Adult).dateOfPensionLiquid) {
        //                            self.alertItem = AlertItem(title         : Text("La date de cessation d'activité est postérieure à la date de liquiditaion d'une pension de retraite"),
        //                                                       dismissButton : .default(Text("OK")))
        //                        }
        //                    }
        //                    .alert(item: $alertItem) { alertItem in myAlert(alertItem: alertItem) }
        CasePicker(pickedCase: $adultViewModel.causeOfRetirement, label: "Cause").pickerStyle(SegmentedPickerStyle())
        if (adultViewModel.causeOfRetirement != Unemployment.Cause.demission) {
            Toggle(isOn: $adultViewModel.hasAllocationSupraLegale, label: { Text("Indemnité de licenciement non conventionnelle (supra convention)") })
            if adultViewModel.hasAllocationSupraLegale {
                AmountEditView(label: "Montant total brut", amount: $adultViewModel.allocationSupraLegale).padding(.leading)
            }
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

struct MemberEditView_Previews: PreviewProvider {
    static var family  = Family()
    static var aMember = family.members.first!
    
    static var previews: some View {
        Group {
            //EmptyView()
            MemberEditView(withInitialValueFrom: aMember)
                .environmentObject(family)
                .environmentObject(aMember)
            Form {
                RevenueEditView(adultViewModel: AdultViewModel())
            }
        }
    }
}
