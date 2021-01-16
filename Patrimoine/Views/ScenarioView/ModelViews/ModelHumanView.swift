//
//  ModelHumanView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ModelHumanView: View {
    @State private var modelChoice: HumanLife.RandomVariable = .menLifeExpectation
    
    var body: some View {
        VStack {
            // sélecteur: Actif / Passif / Tout
            CasePicker(pickedCase: $modelChoice, label: "")
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())
            switch modelChoice {
                case .menLifeExpectation:
                    DiscreteRandomizerView(randomizer: HumanLife.model.menLifeExpectation)
                
                case .womenLifeExpectation:
                    DiscreteRandomizerView(randomizer: HumanLife.model.womenLifeExpectation)
                
                case .nbOfYearsOfdependency:
                    DiscreteRandomizerView(randomizer: HumanLife.model.nbOfYearsOfdependency)
            }
        }
        .navigationTitle("Fonctions de Distribution")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ModelHumanView_Previews: PreviewProvider {
    static var previews: some View {
        ModelHumanView()
    }
}
