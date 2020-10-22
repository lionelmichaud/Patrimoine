//
//  ModelEconomyView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ModelEconomyView: View {
    @State private var modelChoice: Economy.ModelEnum = .inflation
    
    var body: some View {
        VStack {
            // sélecteur: Actif / Passif / Tout
            CasePicker(pickedCase: $modelChoice, label: "")
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())
            switch modelChoice {
                case .inflation:
                    BetaRandomizerView(randomizer: Economy.model.inflation)

                case .longTermRate:
                    BetaRandomizerView(randomizer: Economy.model.longTermRate)

                case .stockRate:
                    BetaRandomizerView(randomizer: Economy.model.stockRate)
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
