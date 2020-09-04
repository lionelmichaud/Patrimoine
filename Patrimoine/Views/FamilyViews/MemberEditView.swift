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
    @ObservedObject var personViewModel = PersonViewModel()
    // Child
    @State private var ageUniversity   = ScenarioCst.minAgeUniversity
    @State private var ageIndependance = ScenarioCst.minAgeIndependance
    // Adult
    @ObservedObject var adultViewModel = AdultViewModel()
    
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
            adultViewModel.causeOfRetirement         = adult.causeOfRetirement
            adultViewModel.hasAllocationSupraLegale  = adult.layoffCompensationBonified != nil
            adultViewModel.allocationSupraLegale     = adult.layoffCompensationBonified ?? 0.0
            adultViewModel.nbYearOfDepend            = adult.nbOfYearOfDependency
            adultViewModel.ageAgircPension           = adult.ageOfAgircPensionLiquidComp.year!
            adultViewModel.trimAgircPension          = adult.ageOfAgircPensionLiquidComp.month! / 3
            adultViewModel.agePension                = adult.ageOfPensionLiquidComp.year!
            adultViewModel.trimPension               = adult.ageOfPensionLiquidComp.month! / 3
            adultViewModel.lastKnownPensionSituation = adult.lastKnownPensionSituation
            adultViewModel.lastKnownAgircSituation = adult.lastKnownAgircPensionSituation
            switch adult.workIncome {
                case let .salary(brutSalary, taxableSalary, netSalary, fromDate, healthInsurance):
                    adultViewModel.revenueBrut    = brutSalary
                    adultViewModel.revenueTaxable = taxableSalary
                    adultViewModel.revenueNet     = netSalary
                    adultViewModel.fromDate       = fromDate
                    adultViewModel.insurance      = healthInsurance
                    adultViewModel.revIndex = WorkIncomeType.salaryId
                case let .turnOver(BNC, incomeLossInsurance):
                    adultViewModel.revenueBrut = BNC
                    adultViewModel.revenueNet  = BNC
                    adultViewModel.insurance = incomeLossInsurance
                    adultViewModel.revIndex  = WorkIncomeType.turnOverId
                case .none:
                    adultViewModel.revenueBrut    = 0
                    adultViewModel.revenueTaxable = 0
                    adultViewModel.revenueNet     = 0
                    adultViewModel.insurance      = 0
                    adultViewModel.revIndex       = 0
            }
        }
    }
    
    /// Applique les modifications: recopie le ViewModel dans les propriétés d'un membre existant
    func applyChanges() {
        member.ageOfDeath = personViewModel.deathAge
        if let adult = member as? Adult {
            adult.dateOfRetirement     = adultViewModel.dateRetirement
            adult.causeOfRetirement    = adultViewModel.causeOfRetirement
            if (adultViewModel.causeOfRetirement == Unemployment.Cause.demission) {
                // pas d'indemnité de licenciement en cas de démission
                adult.layoffCompensationBonified = nil
            } else {
                if adultViewModel.hasAllocationSupraLegale {
                    // indemnité supra-légale de licenciement accordée par l'employeur
                    adult.layoffCompensationBonified = adultViewModel.allocationSupraLegale
                } else {
                    // pas d'indemnité supra-légale de licenciement
                    adult.layoffCompensationBonified = nil
                }
            }
            
            adult.setAgeOfPensionLiquidComp(year  : adultViewModel.agePension,
                                            month : adultViewModel.trimPension * 3)
            adult.setAgeOfAgircPensionLiquidComp(year  : adultViewModel.ageAgircPension,
                                                 month : adultViewModel.trimAgircPension * 3)
            adult.lastKnownPensionSituation = adultViewModel.lastKnownPensionSituation
            adult.lastKnownAgircPensionSituation = adultViewModel.lastKnownAgircSituation
            
            if adultViewModel.revIndex == WorkIncomeType.salaryId {
                adult.workIncome =
                    WorkIncomeType.salary(brutSalary      : adultViewModel.revenueBrut,
                                          taxableSalary   : adultViewModel.revenueTaxable,
                                          netSalary       : adultViewModel.revenueNet,
                                          fromDate        : adultViewModel.fromDate,
                                          healthInsurance : adultViewModel.insurance)
            } else {
                adult.workIncome =
                    WorkIncomeType.turnOver(BNC                 : adultViewModel.revenueBrut,
                                            incomeLossInsurance : adultViewModel.insurance)
            }
            
            adult.nbOfYearOfDependency = adultViewModel.nbYearOfDepend
            
        }
        if let child = member as? Child {
            child.ageOfUniversity = ageUniversity
            child.ageOfIndependence = ageIndependance
        }
        
        // mettre à jour le nombre d'enfant de chaque parent de la famille
        family.aMemberIsUpdated()
        
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()
        
        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Saisie adulte
struct AdultEditView : View {
    @ObservedObject var personViewModel        : PersonViewModel
    @ObservedObject var adultViewModel         : AdultViewModel
    @State private var compenstationSupraLegal : Bool = false
    @State private var alertItem               : AlertItem?
    
    fileprivate func scenarioView() -> some View {
        return Section(header: Text("SCENARIO").font(.subheadline)) {
            Stepper(value: $personViewModel.deathAge, in: Date().year - personViewModel.birthDate.year ... 100) {
                HStack {
                    Text("Age de décès estimé ")
                    Spacer()
                    Text("\(personViewModel.deathAge) ans").foregroundColor(.secondary)
                }
            }
        }
    }
    
    var body: some View {
        Group {
            scenarioView()
            // activité
            Section(header: Text("ACTIVITE")) {
                RevenueEditView(revIndex       : $adultViewModel.revIndex,
                                revenueBrut    : $adultViewModel.revenueBrut,
                                revenueNet     : $adultViewModel.revenueNet,
                                revenueTaxable : $adultViewModel.revenueTaxable,
                                fromDate       : $adultViewModel.fromDate,
                                insurance      : $adultViewModel.insurance)
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
                    Toggle(isOn: $adultViewModel.hasAllocationSupraLegale, label: { Text("Indemnité de licenciement supra-légale") })
                    if adultViewModel.hasAllocationSupraLegale {
                        AmountEditView(label: "Montant brut", amount: $adultViewModel.allocationSupraLegale).padding(.leading)
                    }
                }
            }
            // retraite
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
fileprivate struct RevenueEditView : View {
    @Binding var revIndex       : Int
    @Binding var revenueBrut    : Double
    @Binding var revenueNet     : Double
    @Binding var revenueTaxable : Double
    @Binding var fromDate       : Date
    @Binding var insurance      : Double
    
    var body: some View {
        let salary = revIndex == WorkIncomeType.salaryId
        
        return Group {
            CaseWithAssociatedValuePicker<WorkIncomeType>(caseIndex: $revIndex, label: "")
                .pickerStyle(SegmentedPickerStyle())
            if salary {
                AmountEditView(label: "Salaire brut", amount: $revenueBrut)
                AmountEditView(label: "Salaire net de feuille de paye", amount: $revenueNet)
                AmountEditView(label: "Salaire imposable", amount: $revenueTaxable)
                AmountEditView(label: "Coût de la mutuelle (protec. sup.)", amount: $insurance)
                DatePicker(selection           : $fromDate,
                           in                  : 50.years.ago!...Date.now,
                           displayedComponents : .date,
                           label               : { HStack {Text("Date d'embauche"); Spacer() } })
            } else {
                AmountEditView(label: "BNC", amount: $revenueBrut)
                AmountEditView(label: "Charges sociales", amount: $insurance)
            }
            if salary {
                
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
                RevenueEditView(revIndex       : .constant(1),
                                revenueBrut    : .constant(100000.0),
                                revenueNet     : .constant(85000.0),
                                revenueTaxable : .constant(90000.0),
                                fromDate       : .constant(Date.now),
                                insurance      : .constant(5678.2))
            }
        }
    }
}
