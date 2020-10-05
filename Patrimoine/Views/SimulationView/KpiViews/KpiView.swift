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
                if kpi.value() != nil {
                    Image(systemName: kpi.objectiveIsReached! ? "checkmark.circle.fill" : "multiply.circle.fill")
                        .imageScale(.medium)
                        .foregroundColor(kpi.objectiveIsReached! ? .green : .red)
                }
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
            Section(header: Text("CALCUL " + simulationMode.mode.displayString)) {
                if let value = kpi.value() {
                    KpiSummaryView(kpi: kpi, withDetails: true)

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
                    
                } else {
                    Text("Valeure indéfinie")
                        .foregroundColor(.red)
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
            KpiView(kpi: kpiDeter())
                .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/500.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/200.0/*@END_MENU_TOKEN@*/))
                .preferredColorScheme(.dark)
//            KpiView(kpi: kpiRandom())
//                .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/500.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/200.0/*@END_MENU_TOKEN@*/))
//                .preferredColorScheme(.dark)
        }
    }
}

