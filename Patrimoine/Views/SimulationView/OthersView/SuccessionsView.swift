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
    
    private var successions: [Succession]
    
    var body: some View {
        if successions.isEmpty {
            Text("Pas de décès pendant la dernière simulation")
        } else {
            List {
                GroupBox(label: Text("Cumulatif")
                            .font(.headline)) {
                    Group {
                        AmountView(label : "Masse successorale",
                                   amount: successions.sum(for: \.taxableValue))
                        AmountView(label : "Droits de succession à payer",
                                   amount: -successions.sum(for: \.tax),
                                   comment: ((successions.sum(for: \.tax) / successions.sum(for: \.taxableValue))*100.0).percentString()+"%")
                        Divider()
                        AmountView(label : "Valeur héritée nette",
                                   amount: successions.sum(for: \.net))
                    }
                    .foregroundColor(.secondary)
                    .padding(.top, 3)
                }
                ForEach(successions) { succession in
                    SuccessionGroupBox(succession: succession)
                }
            }
            .navigationTitle("Successions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    init(simulation: Simulation) {
        self.successions = simulation.occuredSuccessions
    }
}

struct SuccessionGroupBox: View {
    var succession: Succession
    
    var body: some View {
        GroupBox(label: Text("Succession de \(succession.decedent.displayName) ") +
                    Text("à l'âge de \(succession.decedent.age(atEndOf: succession.yearOfDeath)) ans ").fontWeight(.regular) +
                    Text("en \(String(succession.yearOfDeath))").fontWeight(.regular)) {
            Group {
                VStack {
                    AmountView(label : "Masse successorale",
                               amount: succession.taxableValue)
                    AmountView(label : "Droits de succession à payer par les héritiers",
                               amount: -succession.tax,
                               comment: ((succession.tax / succession.taxableValue)*100.0).percentString()+"%")
                    Divider()
                    AmountView(label : "Succession nette laissée aux héritiers",
                               amount: succession.net)
                }
                .foregroundColor(.secondary)
                .padding(.top, 3)
                Divider()
                SuccessorsGroupBox(inheritances: succession.inheritances)
            }
            .padding(.leading)
        }
    }
}

struct SuccessorsGroupBox: View {
    var inheritances : [Inheritance]
    
    var body: some View {
        DisclosureGroup(
            content: {
                ForEach(inheritances, id: \.person.id) { inheritence in
                    SuccessorView(inheritence: inheritence)
                }
            },
            label: {
                Text("Héritiers")
                    .font(.headline)
            })
    }
}

struct SuccessorView : View {
    var inheritence: Inheritance
    
    var body: some View {
        GroupBox(label: groupBoxLabel(person: inheritence.person)
                    .font(.headline)) {
            Group {
                PercentView(label   : "Part de la succession",
                            percent : inheritence.percent)
                AmountView(label : "Valeur héritée brute",
                           amount: inheritence.brut)
                AmountView(label : "Droits de succession à payer",
                           amount: -inheritence.tax)
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
        
        return SuccessionsView(simulation: simulation)
            .preferredColorScheme(.dark)
            .environmentObject(uiState)
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
    }
}
