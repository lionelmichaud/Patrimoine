//
//  KpiView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct KpiListView : View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    
    var body: some View {
        ForEach(simulation.kpis) { kpi in
            NavigationLink(destination : KpiView(kpi: kpi)) {
                Text(kpi.name)
            }
            .isDetailLink(true)
        }
    }
}

struct KpiView: View {
    @State var kpi: KPI
    
    var body: some View {
        Form {
            Text("Valeur: \(kpi.value() ?? Double.nan)")
        }
        .navigationTitle(kpi.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct KpiView_Previews: PreviewProvider {
    static var previews: some View {
        KpiView(kpi: KPI(name: "KPI test",
                         objective: 1000.0,
                         withProbability: 0.95))
    }
}
