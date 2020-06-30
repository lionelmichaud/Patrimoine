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
        let income    = adult.initialPersonalIncome
        var revenue   = ""
        var insurance = ""
        let sam: Double = 50_000
        let lastKnownSituation = (atEndOf: 2018, nbTrimestreAcquis: 135)
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
        
        let pension =
            Pension.model.regimeGeneral.pension(sam: sam,
                                                birthDate: member.birthDate,
                                                dateOfRetirementComp: (member as! Adult).dateOfPensionLiquidComp,
                                                lastKnownSituation: lastKnownSituation) ?? 0
        return Group {
            Section(header: Text("SCENARIO").font(.subheadline)) {
                HStack {
                    Text("Age de décès estimé")
                    Spacer()
                    Text("\(member.ageOfDeath) ans en \(String(member.yearOfDeath))")
                }
                HStack {
                    Text("Date de cessation d'activité")
                    Spacer()
                    Text(mediumDateFormatter.string(from: adult.dateOfRetirement))
                }
                HStack {
                    Text("Liquidation de pension")
                    Spacer()
                    Text("\(adult.ageOfPensionLiquidComp.year!) ans en \(String(adult.dateOfPensionLiquid.year))")
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
            }
            // revenus
            Section(header: Text("REVENUS").font(.subheadline)) {
                HStack {
                    Text(income?.pickerString == "Salaire" ? "Salaire" : "BNC")
                    Spacer()
                    Text(revenue)
                }
                HStack {
                    Text(income?.pickerString == "Salaire" ? "Coût de la mutuelle" : "Charges sociales")
                    Spacer()
                    Text(insurance)
                }
                // pension de retraite
                NavigationLink(destination: RetirementDetailView()) {
                    AmountView(label: "Pension de retraite annuelle brute", amount: pension)
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
