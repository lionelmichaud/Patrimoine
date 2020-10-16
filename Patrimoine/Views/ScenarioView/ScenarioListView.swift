//
//  ScenarioListView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ScenarioModelListView: View {
    var body: some View {
        Section(header: Text("Modèles").font(.headline)) {
            NavigationLink(destination: ModelHumanView()) {
                Text("Modèle Humain").fontWeight(.bold)
            }
            .isDetailLink(true)
            
            NavigationLink(destination: ModelEconomyView()) {
                Text("Modèle Economique").fontWeight(.bold)
            }
            .isDetailLink(true)
            
            NavigationLink(destination: ModelSociologyView()) {
                Text("Modèle Sociologique").fontWeight(.bold)
            }
            .isDetailLink(true)
        }
    }
}

struct ScenarioModelListView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            ScenarioModelListView()
                .previewLayout(.sizeThatFits)
        }        
    }
}
