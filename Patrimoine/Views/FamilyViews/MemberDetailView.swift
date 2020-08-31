//
//  FamilyDetailView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - Afficher les détails d'un membre de la famille

struct MemberDetailView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var member     : Person
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @State var showingSheet = false
    
    var body: some View {
        Form {
            Text(member.displayName).font(.headline)
            MemberAgeDateView(member: member)
            if member is Adult {
                HStack {
                    Text("Nombre d'enfants")
                    Spacer()
                    Text("\((member as! Adult).nbOfChildBirth)")
                }
                AdultDetailView()

            } else if member is Child {
                ChildDetailView()
            }
        }
        .sheet(isPresented: $showingSheet) {
            MemberEditView(withInitialValueFrom: self.member)
                .environmentObject(self.member)
                .environmentObject(self.family)
                .environmentObject(self.patrimoine)
                .environmentObject(self.simulation)
                .environmentObject(self.uiState)
        }
        .navigationBarTitle("Membre", displayMode: .inline)
        .navigationBarItems(
            trailing: Button(
                action: {
                    withAnimation {
                        self.showingSheet = true
                    }
                },
                label: {
                    Text("Modifier")
                }
            )
        )
    }
}

// MARK: - Adult View

struct AdultDetailView: View {
    @EnvironmentObject var member: Person

    var body: some View {
        let adult          = member as! Adult
        let income         = adult.workIncome
        var revenueBrut    = 0.0
        var revenueNet     = 0.0
        var revenueTaxable = 0.0
        var revenueLiving  = 0.0
        var fromDate       = ""
        var insurance      = 0.0
        
        switch income {
            case let .salary(_, _, _, fromDate1, healthInsurance):
                revenueBrut    = adult.workBrutIncome
                revenueTaxable = adult.workTaxableIncome
                revenueLiving  = adult.workLivingIncome
                revenueNet     = adult.workNetIncome
                fromDate       = fromDate1.stringMediumDate
                insurance      = healthInsurance
            case let .turnOver(_, incomeLossInsurance):
                revenueBrut    = adult.workBrutIncome
                revenueTaxable = adult.workTaxableIncome
                revenueLiving  = adult.workLivingIncome
                revenueNet     = adult.workNetIncome
                insurance      = incomeLossInsurance
            case .none:
                revenueBrut    = 0
                revenueTaxable = 0
                revenueLiving  = 0
                revenueNet     = 0
                insurance      = 0
        }
        
        return Group {
            /// Section: scénario
            Section {
                DisclosureGroup (
                    content: {
                        HStack {
                            Text("Age de décès estimé")
                            Spacer()
                            Text("\(member.ageOfDeath) ans en \(String(member.yearOfDeath))")
                        }
                        HStack {
                            Text("Cessation d'activité")
                            Spacer()
                            Text("\(adult.age(atDate: adult.dateOfRetirement).year!) ans \(adult.age(atDate: adult.dateOfRetirement).month!) mois au \(mediumDateFormatter.string(from: adult.dateOfRetirement))")
                        }
                        HStack {
                            Text("Cause")
                            Spacer()
                            Text(adult.causeOfRetirement.displayString)
                        }.padding(.leading)
                        if adult.hasUnemployementAllocationPeriod {
                            if adult.dateOfStartOfAllocationReduction != nil {
                                HStack {
                                    Text("Début de la période de réducition d'allocation chômage")
                                    Spacer()
                                    Text("\(adult.age(atDate: adult.dateOfStartOfAllocationReduction!).year!) ans \(adult.age(atDate: adult.dateOfStartOfAllocationReduction!).month!) mois au \(mediumDateFormatter.string(from: adult.dateOfStartOfAllocationReduction!))")
                                }.padding(.leading)
                            }
                            HStack {
                                Text("Fin de la période d'allocation chômage")
                                Spacer()
                                Text("\(adult.age(atDate: adult.dateOfEndOfUnemployementAllocation!).year!) ans \(adult.age(atDate: adult.dateOfEndOfUnemployementAllocation!).month!) mois au \(mediumDateFormatter.string(from: adult.dateOfEndOfUnemployementAllocation!))")
                            }.padding(.leading)
                        }
                        HStack {
                            Text("Liquidation de pension - régime complém.")
                            Spacer()
                            Text("\(adult.ageOfAgircPensionLiquidComp.year!) ans \(adult.ageOfAgircPensionLiquidComp.month!) mois fin \(monthMediumFormatter.string(from: adult.dateOfAgircPensionLiquid)) \(String(adult.dateOfAgircPensionLiquid.year))")
                        }
                        HStack {
                            Text("Liquidation de pension - régime général")
                            Spacer()
                            Text("\(adult.ageOfPensionLiquidComp.year!) ans \(adult.ageOfPensionLiquidComp.month!) mois fin \(monthMediumFormatter.string(from: adult.dateOfPensionLiquid)) \(String(adult.dateOfPensionLiquid.year))")
                        }
                        HStack {
                            Text("Dépendance")
                            Spacer()
                            if adult.nbOfYearOfDependency == 0 {
                                Text("aucune")
                            } else {
                                Text("\(adult.nbOfYearOfDependency) ans à partir de \(String(adult.yearOfDependency))")
                            }
                        }
                        NavigationLink(destination: PersonLifeLineView(withInitialValueFrom: self.member)) {
                            Text("Ligne de vie").foregroundColor(.blue)
                        }
                    },
                    label: {
                        Text("SCENARIO DE VIE").font(.headline)
                    })
            }
            
            /// Section: revenus
            Section {
                DisclosureGroup (
                    content: {
                        if income?.pickerString == "Salaire" {
                            AmountView(label  : "Salaire brut", amount : revenueBrut)
                            AmountView(label  : "Salaire net de feuille de paye", amount : revenueNet)
                            AmountView(label  : "Coût de la mutuelle (protec. sup.)", amount : insurance)
                            AmountView(label  : "Salaire net moins mutuelle facultative (à vivre)", amount : revenueLiving)
                            AmountView(label  : "Salaire imposable (après abattement)", amount : revenueTaxable)
                            HStack {
                                Text("Date d'embauche")
                                Spacer()
                                Text(fromDate)
                            }
                        } else {
                            AmountView(label  : "BNC", amount : revenueBrut)
                            AmountView(label  : "BNC net de charges sociales", amount : revenueNet)
                            AmountView(label  : "Coût des assurances", amount : insurance)
                            AmountView(label  : "BNC net de charges sociales et d'assurances (à vivre)", amount : revenueLiving)
                            AmountView(label  : "BNC imposable (après abattement)", amount : revenueTaxable)
                            
                        }
                        // allocation chomage
                        if adult.hasUnemployementAllocationPeriod {
                            NavigationLink(destination: UnemployementDetailView().environmentObject(self.member)) {
                                AmountView(label  : "Allocation chômage annuelle nette",
                                           amount : adult.unemployementAllocation!.net).foregroundColor(.blue)
                            }
                        }
                        // pension de retraite
                        NavigationLink(destination: RetirementDetailView().environmentObject(self.member)) {
                            AmountView(label  : "Pension de retraite annuelle nette",
                                       amount : adult.pension.net).foregroundColor(.blue)
                        }
                    },
                    label: {
                        Text("REVENUS").font(.headline)
                    })
            }
        }
    }
}

// MARK: - Child View

struct ChildDetailView: View {
    @EnvironmentObject var member: Person

    var body: some View {
        let child = member as! Child
        return Section(header: Text("SCENARIO").font(.subheadline)) {
            HStack {
                Text("Age de décès estimé")
                Spacer()
                Text("\(member.ageOfDeath) ans en \(String(member.yearOfDeath))")
            }
            HStack {
                Text("Age d'entrée à l'université")
                Spacer()
                Text("\(child.ageOfUniversity) ans en \(String(child.dateOfUniversity.year))")
            }
            HStack {
                Text("Age d'indépendance financière")
                Spacer()
                Text("\(child.ageOfIndependence) ans en \(String(child.dateOfIndependence.year))")
            }
            NavigationLink(destination: PersonLifeLineView(withInitialValueFrom: self.member)) {
                Text("Ligne de vie")
            }
        }
    }
}

struct FamilyDetailView_Previews: PreviewProvider {
    static var family  = Family()

    static var previews: some View {
        let aMember = family.members.first!
        
        return Group {
            MemberDetailView()
                    .environmentObject(family)
                .environmentObject(aMember)
            MemberDetailView()
                .environmentObject(family)
                .environmentObject(aMember)
        }
        
    }
}
