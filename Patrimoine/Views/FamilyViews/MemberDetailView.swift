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
        let adult     = member as! Adult
        let income    = adult.workIncome
        var revenue   = ""
        var insurance = ""
        
        switch income {
            case let .salary(netSalary, healthInsurance):
                revenue   = valueEuroFormatter.string(from: netSalary as NSNumber) ?? ""
                insurance = valueEuroFormatter.string(from: healthInsurance as NSNumber) ?? ""
            case let .turnOver(BNC, incomeLossInsurance):
                revenue   = valueEuroFormatter.string(from: BNC as NSNumber) ?? ""
                insurance = valueEuroFormatter.string(from: incomeLossInsurance as NSNumber) ?? ""
            case .none:
                revenue   = "none"
                insurance = "none"
        }
        
        return Group {
            Section(header: Text("SCENARIO").font(.subheadline)) {
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
                    Text("Ligne de vie")
                }
            }
            // revenus
            Section(header: Text("REVENUS").font(.subheadline)) {
                HStack {
                    Text(income?.pickerString == "Salaire" ? "Salaire net avant impôts" : "BNC avant impôts")
                    Spacer()
                    Text(revenue)
                }
                HStack {
                    Text(income?.pickerString == "Salaire" ? "Coût de la mutuelle" : "Charges sociales")
                    Spacer()
                    Text(insurance)
                }
                // pension de retraite
                NavigationLink(destination: RetirementDetailView()
) {
                    AmountView(label  : "Pension de retraite annuelle nette",
                               amount : adult.pension.net)
                }
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
        
        return MemberDetailView()
                .environmentObject(family)
                .environmentObject(aMember)
        
    }
}
