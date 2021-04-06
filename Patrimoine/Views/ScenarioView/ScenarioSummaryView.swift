//
//  ScenarioHeaderView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

/// Affiche des valeures des modèles utilisées pour le dernier Run de simulation
struct ScenarioSummaryView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var family     : Family

    var body: some View {
        VStack {
            Text("Derniers paramètres de simulation utilisés").bold()
            Form {
                Section(header: Text("Modèle Humain")) {
                    ForEach(family.members) { member in
                        if let adult = member as? Adult {
                            Text(adult.displayName)
                            VStack {
                                LabeledText(label: "Age de décès considéré",
                                            text : "\(adult.ageOfDeath) ans en \(String(adult.yearOfDeath))")
                                    .padding(.leading)
                                LabeledText(label: "Nombre d'années de dépendance",
                                            text : "\(adult.nbOfYearOfDependency) ans à partir de \(String(adult.ageOfDependency)) ans en \(adult.yearOfDependency)")
                                    .padding(.leading)
                            }
                        }
                    }
                }
                Section(header: Text("Modèle Economique")) {
                    PercentView(label   : "Inflation",
                                percent : Economy.model.randomizers.inflation.value(withMode: simulation.mode)/100.0)
                    PercentView(label   : "Rendement annuel moyen des Obligations sans risque",
                                percent : Economy.model.randomizers.securedRate.value(withMode: simulation.mode)/100.0)
                    if UserSettings.shared.simulateVolatility {
                        PercentView(label   : "Volatilité des Obligations sans risque",
                                    percent : Economy.model.randomizers.securedVolatility/100.0)
                    }
                    PercentView(label   : "Rendement annuel moyen des Actions",
                                percent : Economy.model.randomizers.stockRate.value(withMode: simulation.mode)/100.0)
                    if UserSettings.shared.simulateVolatility {
                        PercentView(label   : "Volatilité des Actions",
                                    percent : Economy.model.randomizers.stockVolatility/100.0)
                    }
                }
                Section(header: Text("Modèle Sociologique")) {
                    PercentView(label   : "Dévaluation anuelle des pensions par rapport à l'inflation",
                                percent : -SocioEconomy.model.pensionDevaluationRate.value(withMode: simulation.mode)/100.0)
                    IntegerView(label   : "Nombre de trimestres additionels pour obtenir le taux plein",
                                integer : Int(SocioEconomy.model.nbTrimTauxPlein.value(withMode: simulation.mode)))
                    PercentView(label   : "Pénalisation des dépenses",
                                percent : SocioEconomy.model.expensesUnderEvaluationRate.value(withMode: simulation.mode)/100.0)
                }
            }
            .navigationTitle("Résumé")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: { })
            .onDisappear(perform: { })
        }
    }
}

struct ScenarioSummaryViewView_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()

    static var previews: some View {
            ScenarioSummaryView()
                .environmentObject(uiState)
                .environmentObject(family)
                .environmentObject(patrimoine)
                .environmentObject(simulation)
                .previewLayout(.sizeThatFits)
    }
}
