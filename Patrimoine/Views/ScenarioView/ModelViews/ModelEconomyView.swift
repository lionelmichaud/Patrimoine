//
//  ModelEconomyView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

/// Affiche un graphique des fonctions de distribution des modèles statistiques
struct ModelEconomyView: View {
    @State private var modelChoice: Economy.RandomVariable = .inflation
    
    var body: some View {
        VStack {
            // sélecteur: inflation / securedRate / stockRate
            CasePicker(pickedCase: $modelChoice, label: "")
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())
            switch modelChoice {
                case .inflation:
                    BetaRandomizerView(randomizer: Economy.model.randomizers.inflation)

                case .securedRate:
                    BetaRandomizerView(randomizer: Economy.model.randomizers.securedRate)

                case .stockRate:
                    BetaRandomizerView(randomizer: Economy.model.randomizers.stockRate)
            }
        }
        .navigationTitle("Fonctions de Distribution")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ModelEconomyView_Previews: PreviewProvider {
    static var previews: some View {
        ModelEconomyView()
    }
}
