//
//  KpisSummaryView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct KpisSummaryView: View {
    @EnvironmentObject var simulation : Simulation
    
    var body: some View {
        Text("Calcul " + simulationMode.mode.displayString)
        Form {
            ForEach(simulation.kpis) { kpi in
                Section(header: Text(kpi.name)) {
                    if kpi.value() != nil {
                        KpiSummaryView(kpi: kpi, withDetails: false)
                    } else {
                        Text("Valeure indéfinie")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Synthèse des KPI")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct KpiSummaryView: View {
    @State var kpi: KPI
    var withDetails: Bool
    
    var body: some View {
        if withDetails {
            AmountView(label: "Valeur objectif", amount: kpi.objective)
        }
        HStack {
            AmountView(label: "Valeur atteinte", amount: kpi.value() ?? Double.nan)
            Image(systemName: kpi.objectiveIsReached! ? "checkmark.circle.fill" : "multiply.circle.fill")
                .imageScale(/*@START_MENU_TOKEN@*/.large/*@END_MENU_TOKEN@*/)
        }
        .foregroundColor(kpi.objectiveIsReached! ? .green : .red)
        // simulation déterministe
        ProgressBar(value            : kpi.value()!,
                    minValue         : 0.0,
                    maxValue         : kpi.objective,
                    backgroundEnabled: false,
                    labelsEnabled    : true,
                    backgroundColor  : .secondary,
                    foregroundColor  : kpi.objectiveIsReached! ? .green : .red,
                    formater: valueEuroFormatter)
            .padding(.vertical)
    }
}

struct KpisSummaryView_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()

    static var previews: some View {
        VStack {
            KpisSummaryView()
        }
        .previewDevice("iPhone 11")
        .preferredColorScheme(.dark)
        .environmentObject(simulation)
    }
}
