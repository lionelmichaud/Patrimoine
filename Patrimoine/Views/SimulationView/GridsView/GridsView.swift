//
//  GridsView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct GridsView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    
    var body: some View {
        if simulation.isComputed {
            Section(header: Text("Tableaux").font(.headline)) {
                Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            }
        } else {
            EmptyView()
        }
    }
}

struct GridsView_Previews: PreviewProvider {
    static var previews: some View {
        GridsView()
    }
}
