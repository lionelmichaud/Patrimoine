//
//  ModelDeterministicView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

/// Affiche les valeurs déterministes retenues pour les paramètres des modèles dans une simulation "déterministe"
struct ModelDeterministicView: View {
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Modèle Humain")) {
                    IntegerView(label   : "Espérance de vie d'un Homme",
                                integer : Int(HumanLife.model.menLifeExpectation.value(withMode: .deterministic)))
                    IntegerView(label   : "Espérance de vie d'une Femme",
                                integer : Int(HumanLife.model.womenLifeExpectation.value(withMode: .deterministic)))
                    IntegerView(label   : "Nombre d'années de dépendance",
                                integer : Int(HumanLife.model.nbOfYearsOfdependency.value(withMode: .deterministic)))
                }
                Section(header: Text("Modèle Economique")) {
                    PercentView(label   : "Inflation",
                                percent : Economy.model.randomizers.inflation.value(withMode: .deterministic)/100.0)
                    PercentView(label   : "Rendement sans Risque",
                                percent : Economy.model.randomizers.securedRate.value(withMode: .deterministic)/100.0)
                    PercentView(label   : "Rendement des Actions",
                                percent : Economy.model.randomizers.stockRate.value(withMode: .deterministic)/100.0)
                }
                Section(header: Text("Modèle Sociologique")) {
                    PercentView(label   : "Dévaluation anuelle des pensions par rapport à l'inflation",
                                percent : -SocioEconomy.model.pensionDevaluationRate.value(withMode: .deterministic)/100.0)
                    IntegerView(label   : "Nombre de trimestres additionels pour obtenir le taux plein",
                                integer : Int(SocioEconomy.model.nbTrimTauxPlein.value(withMode: .deterministic)))
                    PercentView(label   : "Pénalisation des dépenses",
                                percent : SocioEconomy.model.expensesUnderEvaluationrate.value(withMode: .deterministic)/100.0)
                }
            }
            .navigationTitle("Résumé")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: { })
            .onDisappear(perform: { })
        }
    }
}

struct ModelDeterministicView_Previews: PreviewProvider {
    static var previews: some View {
        ModelDeterministicView()
    }
}
