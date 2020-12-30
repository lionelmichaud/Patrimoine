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
    
    var body: some View {
        ForEach(simulation.kpis) { kpi in
            NavigationLink(destination : KpiDetailedView(kpi: kpi)) {
                if let objectiveIsReached = kpi.objectiveIsReached(withMode: simulation.mode) {
                    Image(systemName: objectiveIsReached ? "checkmark.circle.fill" : "multiply.circle.fill")
                        .imageScale(.medium)
                        .foregroundColor(objectiveIsReached ? .green : .red)
                }
                Text(kpi.name)
            }
            .isDetailLink(true)
        }
    }
}

struct KpiDetailedView: View {
    @EnvironmentObject var simulation : Simulation
    @State var kpi: KPI
    
    var body: some View {
        VStack {
            Section(header: Text("Mode de Calcul " + simulation.mode.displayString).bold()) {
                // afficher le résumé
                KpiSummaryView(kpi         : kpi,
                               withPadding : true,
                               withDetails : true)

                // afficher le détail
                if kpi.hasValue(for: simulation.mode) {
                    switch simulation.mode {
                        case .deterministic:
                            EmptyView()
                            
                        case .random:
                            // simulation de Monté-Carlo
                            HStack {
                                AmountView(label: "Valeur Moyenne", amount: kpi.average(withMode: simulation.mode) ?? Double.nan)
                                    .padding(.trailing)
                                AmountView(label: "Valeur Médiane", amount: kpi.median(withMode: simulation.mode) ?? Double.nan)
                                    .padding(.leading)
                            }
                            .padding(.top, 3)
                            HStack {
                                AmountView(label: "Valeur Minimale", amount: kpi.min(withMode: simulation.mode) ?? Double.nan)
                                    .padding(.trailing)
                                AmountView(label: "Valeur Maximale", amount: kpi.max(withMode: simulation.mode) ?? Double.nan)
                                    .padding(.leading)
                            }
                            .padding(.top, 3)
                            HistogramView(histogram           : kpi.histogram,
                                          xLimitLine          : kpi.objective,
                                          yLimitLine          : kpi.probaObjective,
                                          xAxisFormatterChoice: .k€)
                    }
                }
            }
        }
        .padding(.horizontal)
        .navigationTitle(kpi.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct KpiListView_Previews: PreviewProvider {
    static var simulation = Simulation()
    
    static func kpiDeter() -> KPI {
        simulation.mode = .deterministic
        var kpi = KPI(name: "KPI test",
                      objective: 1000.0,
                      withProbability: 0.95)
        kpi.record(100.0, withMode: simulation.mode)
        return kpi
    }
    static func kpiRandom() -> KPI {
        simulation.mode = .random
        var kpi = KPI(name: "KPI test",
                      objective: 1000.0,
                      withProbability: 0.95)
        kpi.record(500.0, withMode: simulation.mode)
        kpi.histogram.sort(distributionType : .continuous,
                           openEnds         : false,
                           bucketNb         : 50)
        return kpi
    }
    static var previews: some View {
        Group {
            KpiDetailedView(kpi: kpiDeter())
                .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/500.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/200.0/*@END_MENU_TOKEN@*/))
                .preferredColorScheme(.dark)
//            KpiView(kpi: kpiRandom())
//                .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/500.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/200.0/*@END_MENU_TOKEN@*/))
//                .preferredColorScheme(.dark)
        }
    }
}
