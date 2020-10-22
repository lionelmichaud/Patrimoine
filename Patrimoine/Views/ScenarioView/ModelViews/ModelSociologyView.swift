//
//  ModelSociologyView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ModelSociologyView: View {
    @State private var modelChoice: SocioEconomy.ModelEnum = .pensionDevaluationRate
    
    var body: some View {
        VStack {
            // sélecteur: Actif / Passif / Tout
            CasePicker(pickedCase: $modelChoice, label: "")
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())
            switch modelChoice {
                case .pensionDevaluationRate:
                    BetaRandomizerView(randomizer: SocioEconomy.model.pensionDevaluationRate)
                    
                case .nbTrimTauxPlein:
                    DiscreteRandomizerView(randomizer: SocioEconomy.model.nbTrimTauxPlein)
                    
                case .expensesUnderEvaluationrate:
                    BetaRandomizerView(randomizer: SocioEconomy.model.expensesUnderEvaluationrate)
            }
        }
        .navigationTitle("Fonctions de Distribution")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ModelSociologyView_Previews: PreviewProvider {
    static var previews: some View {
        ModelSociologyView()
    }
}
