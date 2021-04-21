//
//  SuccessionsView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct SuccessionsView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    var title: String
    
    var successions: [Succession]
    
    var body: some View {
        if successions.isEmpty {
            Text("Pas de décès pendant la dernière simulation")
        } else {
            List {
                // Cumul global des successions
                GroupBox(label: Text("Cumulatif").font(.headline)) {
                    Group {
                        Group {
                            AmountView(label : "Masse successorale",
                                       amount: successions.sum(for: \.taxableValue))
                            AmountView(label : "Droits de succession à payer",
                                       amount: -successions.sum(for: \.tax),
                                       comment: (successions.sum(for: \.tax) / successions.sum(for: \.taxableValue)).percentStringRounded)
                            Divider()
                            AmountView(label : "Succession nette laissée aux héritiers",
                                       amount: successions.sum(for: \.net))
                        }
                        .foregroundColor(.secondary)
                        .padding(.top, 3)
                        Divider()
                        CumulatedSuccessorsDisclosureGroup(successions: successions)
                    }
                    .padding(.leading)
                }

                // liste des successsions dans le temps
                ForEach(successions.sorted(by: \.yearOfDeath)) { succession in
                    SuccessionGroupBox(succession: succession)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
//    init(simulation: Simulation) {
//        self.successions = simulation.occuredLegalSuccessions
//    }
}

struct CumulatedSuccessorsDisclosureGroup: View {
    var successions: [Succession]
    
    var body: some View {
        DisclosureGroup(
            content: {
                ForEach(successions.successorsInheritedNetValue.keys.sorted(), id:\.self) { name in
                    GroupBox(label: Text(name).font(.headline)) {
                        AmountView(label  : "Valeur héritée nette",
                                   amount : successions.successorsInheritedNetValue[name]!)
                            .foregroundColor(.secondary)
                            .padding(.top, 3)
                    }
                }
            },
            label: {
                Text("Héritiers").font(.headline)
            })
    }
}

struct SuccessionGroupBox: View {
    var succession: Succession
    
    var body: some View {
        GroupBox(label: Text("Succession de \(succession.decedent.displayName) ") +
                    Text("à l'âge de \(succession.decedent.age(atEndOf: succession.yearOfDeath)) ans ").fontWeight(.regular) +
                    Text("en \(String(succession.yearOfDeath))").fontWeight(.regular)) {
            Group {
                Group {
                    AmountView(label : "Masse successorale",
                               amount: succession.taxableValue)
                    AmountView(label : "Droits de succession à payer par les héritiers",
                               amount: -succession.tax,
                               comment: (succession.tax / succession.taxableValue).percentStringRounded)
                    Divider()
                    AmountView(label : "Succession nette laissée aux héritiers",
                               amount: succession.net)
                }
                .foregroundColor(.secondary)
                .padding(.top, 3)
                Divider()
                SuccessorsDisclosureGroup(inheritances: succession.inheritances)
            }
            .padding(.leading)
        }
    }
}

struct SuccessorsDisclosureGroup: View {
    var inheritances : [Inheritance]
    
    var body: some View {
        DisclosureGroup(
            content: {
                ForEach(inheritances, id: \.person.id) { inheritence in
                    SuccessorGroupBox(inheritence: inheritence)
                }
            },
            label: {
                Text("Héritiers").font(.headline)
            })
    }
}

struct SuccessorGroupBox : View {
    var inheritence: Inheritance
    
    var body: some View {
        GroupBox(label: groupBoxLabel(person: inheritence.person).font(.headline)) {
            Group {
//                PercentView(label   : "Part de la succession",
//                            percent : inheritence.percent)
                AmountView(label  : "Valeur héritée brute",
                           amount : inheritence.brut,
                           comment: inheritence.percent.percentStringRounded + " de la succession")
                    .padding(.top, 3)
                AmountView(label  : "Droits de succession à payer",
                           amount : -inheritence.tax,
                           comment: (inheritence.tax / inheritence.brut).percentStringRounded)
                    .padding(.top, 3)
                Divider()
                AmountView(label : "Valeur héritée nette",
                           amount: inheritence.net)
            }
            .foregroundColor(.secondary)
        }
    }
    
    func groupBoxLabel(person: Person) -> some View {
        HStack {
            Text(person.displayName)
            Spacer()
            Text(person is Adult ? "Conjoint" : "Enfant")
        }
    }
}

struct SuccessionsView_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()

    static func initializedSimulation() -> Simulation {
        let simulation = Simulation()
        simulation.compute(nbOfYears      : 55,
                           nbOfRuns       : 1,
                           withFamily     : family,
                           withPatrimoine : patrimoine)
        return simulation
    }
    
    static var previews: some View {
        let simulation = initializedSimulation()
        
        return SuccessionsView(title       : "Successions",
                               successions : simulation.occuredLegalSuccessions)
            .preferredColorScheme(.dark)
            .environmentObject(uiState)
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
    }
}
