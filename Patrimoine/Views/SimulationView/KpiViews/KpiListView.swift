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
                if let objectiveIsReached = kpi.objectiveIsReached {
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
    @State var kpi: KPI
    
    var body: some View {
        Form {
            Section(header: Text("CALCUL " + simulationMode.mode.displayString)) {
                // afficher le résumé
                KpiSummaryView(kpi: kpi, withDetails: true)
                
                // afficher le détail
                if let value = kpi.value() {
                    switch simulationMode.mode {
                        case .deterministic:
                            EmptyView()

                        case .random:
                            // simulation de Monté-Carlo
                            Text("Valeur: \(value)")
                            HistogramView(histogram           : kpi.histogram,
                                          xLimitLine          : kpi.objective,
                                          yLimitLine          : kpi.probaObjective,
                                          xAxisFormatterChoice: .k€)
                    }
                }
            }
        }
        .navigationTitle(kpi.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct KpiView_Previews: PreviewProvider {
    static func kpiDeter() -> KPI {
        simulationMode.mode = .deterministic
        var kpi = KPI(name: "KPI test",
                      objective: 1000.0,
                      withProbability: 0.95)
        kpi.record(100.0)
        return kpi
    }
    static func kpiRandom() -> KPI {
        simulationMode.mode = .random
        var kpi = KPI(name: "KPI test",
                      objective: 1000.0,
                      withProbability: 0.95)
        kpi.record(500.0)
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

