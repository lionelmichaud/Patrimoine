//
//  KpisSummaryView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct KpiListSummaryView: View {
    @EnvironmentObject var simulation : Simulation
    
    var body: some View {
        Text("Mode de Calcul " + simulation.mode.displayString)
            .bold()
        Form {
            ForEach(simulation.kpis) { kpi in
                Section(header: Text(kpi.name)) {
                    KpiSummaryView(kpi         : kpi,
                                   withPadding : false,
                                   withDetails : false)
                }
            }
        }
        .navigationTitle("Synthèse des KPI")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct KpiSummaryView: View {
    @EnvironmentObject var simulation : Simulation
    @State var kpi  : KPI
    var withPadding : Bool
    var withDetails : Bool
    
    var body: some View {
        if kpi.hasValue(for: simulation.mode) {
            if withDetails {
                Text(kpi.note)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxHeight: 45, alignment: .leading)
                    .padding(.horizontal, 8)
                    .background(Color.secondary)
                    .cornerRadius(5)
                    .padding(.top, 3)
                AmountView(label   : "Valeur Objectif Minimale",
                           amount  : kpi.objective,
                           comment : simulation.mode == .random ? "à atteindre avec une probabilité ≥ \((kpi.probaObjective * 100.0).percentString())%" : "")
                    .padding(EdgeInsets(top: withPadding ? 3 : 0, leading: 0, bottom: withPadding ? 3 : 0, trailing: 0))
                if simulation.mode == .random {
                    HStack {
                        PercentView(label   : "Valeur Objectif Atteinte",
                                    percent : 1.0 - (kpi.probability(for: kpi.objective) ?? Double.nan),
                                    comment : "avec une probabilité de")
                        Image(systemName: kpi.objectiveIsReached(withMode: simulation.mode)! ? "checkmark.circle.fill" : "multiply.circle.fill")
                            .imageScale(/*@START_MENU_TOKEN@*/.large/*@END_MENU_TOKEN@*/)
                    }
                    .foregroundColor(kpi.objectiveIsReached(withMode: simulation.mode)! ? .green : .red)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: withPadding ? 3 : 0, trailing: 0))
                }
            }
            HStack {
                AmountView(label   : "Valeur Atteinte",
                           amount  : kpi.value(withMode: simulation.mode)!,
                           comment : simulation.mode == .random ? "avec une probabilité de \((kpi.probaObjective * 100.0).percentString())%" : "")
                Image(systemName: kpi.objectiveIsReached(withMode: simulation.mode)! ? "checkmark.circle.fill" : "multiply.circle.fill")
                    .imageScale(/*@START_MENU_TOKEN@*/.large/*@END_MENU_TOKEN@*/)
            }
            .foregroundColor(kpi.objectiveIsReached(withMode: simulation.mode)! ? .green : .red)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: withPadding ? 3 : 0, trailing: 0))
            // simulation déterministe
            ProgressBar(value            : kpi.value(withMode: simulation.mode)!,
                        minValue         : 0.0,
                        maxValue         : kpi.objective,
                        backgroundEnabled: false,
                        labelsEnabled    : true,
                        backgroundColor  : .secondary,
                        foregroundColor  : kpi.objectiveIsReached(withMode: simulation.mode)! ? .green : .red,
                        formater: value€Formatter)
            //.padding(.vertical)
            
        } else {
            Text("Valeure indéfinie")
                .foregroundColor(.red)
        }
    }
}

struct KpisSummaryView_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()

    static var previews: some View {
        VStack {
            KpiListSummaryView()
        }
        .previewDevice("iPhone 11")
        .preferredColorScheme(.dark)
        .environmentObject(simulation)
    }
}
