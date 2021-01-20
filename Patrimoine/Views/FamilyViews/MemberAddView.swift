//
//  FamilyAddView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - Person View Model

class PersonViewModel: ObservableObject {
    @Published var familyName   = ""
    @Published var givenName    = ""
    @Published var sexe         = Sexe.male
    @Published var seniority    = Seniority.enfant
    @Published var birthDate    = Date()
    @Published var deathAge     = 81

    // MARK: - Initializers of ViewModel from Model
    
    init(from member: Person) {
        deathAge = member.ageOfDeath
    }
    
    // MARK: - Methods
    
    func updateFromViewModel(member: Person) {
        member.ageOfDeath = deathAge
    }
    
    init() {
//        familyName = ""
//        givenName  = ""
//        sexe       = Sexe.male
//        seniority  = Seniority.enfant
//        birthDate  = Date()
//        deathAge   = 81
    }
}

// MARK: - Adult View Model

class AdultViewModel: ObservableObject {
    @Published var fiscalOption              = InheritanceDonation.FiscalOption.fullUsufruct
    @Published var dateRetirement            = Date()
    @Published var causeOfRetirement         = Unemployment.Cause.demission
    @Published var hasAllocationSupraLegale  = false
    @Published var allocationSupraLegale     = 0.0
    //@Published var dateOfEndOfUnemployAlloc  = Date()
    @Published var ageAgircPension           = Retirement.model.regimeGeneral.model.ageMinimumLegal
    @Published var trimAgircPension          = 0
    @Published var agePension                = Retirement.model.regimeGeneral.model.ageMinimumLegal
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
    
    // MARK: - Initializers of ViewModel from Model
    
    init(from adult: Adult) {
        fiscalOption              = adult.fiscalOption
        dateRetirement            = adult.dateOfRetirement
        causeOfRetirement         = adult.causeOfRetirement
        hasAllocationSupraLegale  = adult.layoffCompensationBonified != nil
        allocationSupraLegale     = adult.layoffCompensationBonified ?? 0.0
        nbYearOfDepend            = adult.nbOfYearOfDependency
        ageAgircPension           = adult.ageOfAgircPensionLiquidComp.year!
        trimAgircPension          = adult.ageOfAgircPensionLiquidComp.month! / 3
        agePension                = adult.ageOfPensionLiquidComp.year!
        trimPension               = adult.ageOfPensionLiquidComp.month! / 3
        lastKnownPensionSituation = adult.lastKnownPensionSituation
        lastKnownAgircSituation   = adult.lastKnownAgircPensionSituation
        switch adult.workIncome {
            case let .salary(brutSalary, taxableSalary, netSalary, fromDate, healthInsurance):
                revenueBrut    = brutSalary
                revenueTaxable = taxableSalary
                revenueNet     = netSalary
                self.fromDate  = fromDate
                insurance      = healthInsurance
                revIndex       = WorkIncomeType.salaryId
            case let .turnOver(BNC, incomeLossInsurance):
                revenueBrut = BNC
                revenueNet  = BNC
                insurance   = incomeLossInsurance
                revIndex    = WorkIncomeType.turnOverId
            case .none:
                revenueBrut    = 0
                revenueTaxable = 0
                revenueNet     = 0
                insurance      = 0
                revIndex       = 0
        }
    }
    
    init() {
    }
    
    func updateFromViewModel(adult: Adult) {
        adult.fiscalOption      = fiscalOption
        adult.dateOfRetirement  = dateRetirement
        adult.causeOfRetirement = causeOfRetirement
        if causeOfRetirement == Unemployment.Cause.demission {
            // pas d'indemnité de licenciement en cas de démission
            adult.layoffCompensationBonified = nil
        } else {
            if hasAllocationSupraLegale {
                // indemnité supra-légale de licenciement accordée par l'employeur
                adult.layoffCompensationBonified = allocationSupraLegale
            } else {
                // pas d'indemnité supra-légale de licenciement
                adult.layoffCompensationBonified = nil
            }
        }
        
        adult.setAgeOfPensionLiquidComp(year  : agePension,
                                        month : trimPension * 3)
        adult.setAgeOfAgircPensionLiquidComp(year  : ageAgircPension,
                                             month : trimAgircPension * 3)
        adult.lastKnownPensionSituation = lastKnownPensionSituation
        adult.lastKnownAgircPensionSituation = lastKnownAgircSituation
        
        if revIndex == WorkIncomeType.salaryId {
            adult.workIncome =
                WorkIncomeType.salary(brutSalary      : revenueBrut,
                                      taxableSalary   : revenueTaxable,
                                      netSalary       : revenueNet,
                                      fromDate        : fromDate,
                                      healthInsurance : insurance)
        } else {
            adult.workIncome =
                WorkIncomeType.turnOver(BNC                 : revenueBrut,
                                        incomeLossInsurance : insurance)
        }
        adult.nbOfYearOfDependency = nbYearOfDepend
    }
}

// MARK: - Saisie du nouveau membre de la famille

struct MemberAddView: View {
    //@Environment(\.managedObjectContext) var moc
    @EnvironmentObject var family     : Family
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState
    @Environment(\.presentationMode) var presentationMode
    @State private var alertItem : AlertItem?
    // Person
    @StateObject var personViewModel = PersonViewModel()
    // Child
    @State private var ageUniversity   = ScenarioCst.minAgeUniversity
    @State private var ageIndependance = ScenarioCst.minAgeIndependance
    // Adult
    @StateObject var adultViewModel = AdultViewModel()
    
    var body: some View {
        VStack {
            /// Barre de titre
            HStack {
                Button(action: { self.presentationMode.wrappedValue.dismiss() },
                       label: { Text("Annuler") })
                    .capsuleButtonStyle()
                
                Spacer()
                Text("Ajouter...").font(.title).fontWeight(.bold)
                Spacer()
                
                Button(action: addMember,
                       label: { Text("OK") })
                    .capsuleButtonStyle()
                    .disabled(!formIsValid())
            }
            .padding(.horizontal)
            .padding(.top)
            
            /// Formulaire
            Form {
                CiviliteEditView(personViewModel: personViewModel)
                    .onChange(of: personViewModel.seniority) { newState in
                        // pas plus de deux adultes dans une famille
                        if newState == .adult && family.nbOfAdults == 2 {
                            self.alertItem = AlertItem(title         : Text("Pas plus de adultes par famille"),
                                                       dismissButton : .default(Text("OK")))
                            personViewModel.seniority = .enfant
                        }
                    }
                    .alert(item: $alertItem, content: myAlert)

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
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()
        
        switch personViewModel.seniority {
            case .adult  :
                // creation du nouveau membre Adult
                let newMember = Adult(sexe       : personViewModel.sexe,
                                      givenName  : personViewModel.givenName,
                                      familyName : personViewModel.familyName.uppercased(),
                                      birthDate  : personViewModel.birthDate,
                                      ageOfDeath : personViewModel.deathAge)
                adultViewModel.updateFromViewModel(adult: newMember)
                
                // ajout du nouveau membre à la famille
                family.addMember(newMember)
            
            case .enfant :
                // creation du nouveau membre Enfant
                let newMember = Child(sexe       : personViewModel.sexe,
                                      givenName  : personViewModel.givenName,
                                      familyName : personViewModel.familyName.uppercased(),
                                      birthDate  : personViewModel.birthDate,
                                      ageOfDeath : personViewModel.deathAge)
                newMember.ageOfUniversity = ageUniversity
                newMember.ageOfIndependence = ageIndependance
                // ajout du nouveau membre à la famille
                family.addMember(newMember)
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
    static var family     = Family()
    static var simulation = Simulation()
    static var patrimoine = Patrimoin()
    static var uiState    = UIState()
    
    static var previews: some View {
        MemberAddView()
            .environmentObject(family)
            .environmentObject(simulation)
            .environmentObject(patrimoine)
            .environmentObject(uiState)
    }
}
