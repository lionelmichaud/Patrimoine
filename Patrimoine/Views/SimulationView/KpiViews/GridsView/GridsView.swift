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
        if simulation.mode == .random && simulation.isComputed {
            NavigationLink(destination : ShortGridView(),
                           tag         : .shortGridView,
                           selection   : $uiState.simulationViewState.selectedItem) {
                Text("Tableau détaillé des runs")
            }
            .isDetailLink(true)
        } else {
            EmptyView()
        }
    }
}

struct ShortGridView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @State private var filter         : RunFilterEnum       = .all
    @State private var sortCriteria   : KpiSortCriteriaEnum = .byRunNumber
    @State private var sortOrder      : SortingOrder        = .ascending

    var body: some View {
        let columns = [GridItem()]
        
        return
            VStack {
                /// entête
                if simulation.resultTable.count != 0 {
                    GridHeaderView(line: simulation.resultTable.first!)
                }
                /// tableau
                ScrollView([.vertical]) {
                    LazyVGrid(columns: columns) {
                        ForEach(simulation.resultTable
                                    .filtered(with: filter)
                                    .sorted(by: sortCriteria, with: sortOrder), id: \.self) { line in
                            ShortGridLineView(line: line)
                                .contextMenu {
                                    Button(action: { replay(thisRun: line) }) { // swiftlint:disable:this multiple_closures_with_trailing_closure
                                        Label("Rejouer", systemImage: "arrowtriangle.forward.circle")
                                    }
                                }
                        }
                    }
                }
                .border(Color.secondary)
            }
            .navigationTitle("Résultats des Runs de la Simulation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // menu de filtrage
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker(selection: $filter, label: Text("Filtering options")) {
                            Label("Tous les résultats", systemImage: "checkmark.circle.fill").tag(RunFilterEnum.all)
                            Label("Résultats négatifs", systemImage: "xmark.octagon.fill").tag(RunFilterEnum.someBad)
                            Label("Résultats indéterminés", systemImage: "exclamationmark.triangle.fill").tag(RunFilterEnum.somUnknown)
                        }
                    }
                    label: {
                        Image(systemName: "loupe")
                            .imageScale(.large)
                            .padding(.leading)
                    }
                }
                // menu de choix de critère de tri
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker(selection: $sortCriteria, label: Text("Sorting options")) {
                            Text("Numéro de Run").tag(KpiSortCriteriaEnum.byRunNumber)
                            Text("KPI Actif Minimum").tag(KpiSortCriteriaEnum.byKpi1)
                            Text("KPI Actif au 1er Décès").tag(KpiSortCriteriaEnum.byKpi2)
                            Text("KPI Actif au 2nd Décès").tag(KpiSortCriteriaEnum.byKpi3)
                        }
                    }
                    label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .imageScale(.large)
                            .padding(.leading)
                    }
                }
                // menu de choix de l'ordre de tri
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { sortOrder.toggle() }) { // swiftlint:disable:this multiple_closures_with_trailing_closure
                        Image(systemName: sortOrder.imageSystemName)
                            .imageScale(.large)
                    }
                }
                // sauvegarde du tableau
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveGrid ) {
                        Label("Enregistrer", systemImage: "square.and.arrow.up")
                    }
                }
            }
    }
    
    func saveGrid() {
        // TODO: - implémenter la sauvegarde du tableau des KPIs de résultat de simulation
    }
    
    func replay(thisRun: SimulationResultLine) {
        // rejouer le run unique
        simulation.replay(thisRun        : thisRun,
                          withFamily     : family,
                          withPatrimoine : patrimoine)
    }
}

struct GridHeaderView : View {
    let line: SimulationResultLine
    let viewHeight = CGFloat(100)
    
    var body: some View {
        HStack(alignment: .center) {
            Text("Run")
                .italic()
                .frame(width: viewHeight)
                .rotationEffect(.degrees(-90))
                .frame(width: 28)
            Divider()
            // propriétés aléatoires des adultes
            ForEach(line.dicoOfAdultsRandomProperties.keys.sorted(), id: \.self) { _ in
                Text("Durée de Vie")
                    .frame(width: viewHeight)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 28)
                Divider()
                Text("Dépendance")
                    .frame(width: viewHeight)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 15)
                Divider()
            }
            // valeurs aléatoires de conditions économiques
            ForEach(Economy.RandomVariable.allCases, id: \.self) { variableEnum in
                Text(variableEnum.pickerString)
                    .frame(width: viewHeight)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 40)
                Divider()
            }
            // valeurs aléatoires de conditions socio-économiques
            ForEach(SocioEconomy.RandomVariable.allCases, id: \.self) { variableEnum in
                Text(variableEnum.pickerString)
                    .frame(width: viewHeight)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 40)
                Divider()
            }
            // valeurs résultantes des KPIs
            ForEach(SimulationKPIEnum.allCases, id: \.self) { kpiEnum in
                Text(kpiEnum.pickerString)
                    .lineLimit(3)
                    .frame(width: viewHeight)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 70)
                Divider()
            }
            Spacer()
        }
        .multilineTextAlignment(.center)
        .font(.callout)
        .allowsTightening(true)
        .lineLimit(2)
        .lineSpacing(-2.0)
        .truncationMode(.middle)
        .frame(maxHeight: viewHeight)
        .border(Color.secondary)
    }
}

struct ShortGridLineView : View {
    let line: SimulationResultLine
    
    var body: some View {
        VStack {
            HStack(spacing: nil) {
                Text(String(line.runNumber))
                    .italic()
                    .font(.caption)
                    .foregroundColor(colorOfRun(withTheseKpis: line.dicoOfKpiResults))
                    .frame(width: 28)
                Divider()
                /// propriétés aléatoires des adultes
                ForEach(line.dicoOfAdultsRandomProperties.keys.sorted(), id: \.self) { name in
                    Text(String(line.dicoOfAdultsRandomProperties[name]!.ageOfDeath))
                        .frame(width: 28)
                    Divider()
                    Text(String(line.dicoOfAdultsRandomProperties[name]!.nbOfYearOfDependency))
                        .frame(width: 15)
                    Divider()
                }
                /// valeurs aléatoires de conditions économiques
                ForEach(Economy.RandomVariable.allCases, id: \.self) { variableEnum in
                    Text((line.dicoOfEconomyRandomVariables[variableEnum]?.percentString(digit: 1) ?? "NaN") + "%")
                        .frame(width: 40)
                    Divider()
                }
                /// valeurs aléatoires de conditions socio-économiques
                ForEach(SocioEconomy.RandomVariable.allCases, id: \.self) { variableEnum in
                    switch variableEnum {
                        case .nbTrimTauxPlein:
                            Text(String(Int(line.dicoOfSocioEconomyRandomVariables[variableEnum]!.rounded())))
                                .frame(width: 40)
                            
                        default:
                            Text((line.dicoOfSocioEconomyRandomVariables[variableEnum]?.percentString(digit: 1) ?? "NaN") + "%")
                                .frame(width: 40)
                    }
                    Divider()
                }
                /// valeurs résultantes des KPIs
                ForEach(SimulationKPIEnum.allCases, id: \.self) { kpiEnum in
                    if let kpiResult = line.dicoOfKpiResults[kpiEnum] {
                        Text(kpiResult.value.k€String)
                            .frame(width: 70)
                            .foregroundColor(kpiResult.objectiveIsReached ? .green : .red)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .frame(width: 70)
                    }
                    Divider()
                }
                Spacer()
            }
            .font(.callout)
            .allowsTightening(true)
        }
    }
    
    func colorOfRun(withTheseKpis kpis: DictionaryOfKpiResults) -> Color {
        let runResult = kpis.runResult()
        switch runResult {
            case .allObjectivesReached:
                return .green
            case .someObjectiveMissed:
                return .red
            case .someObjectiveUndefined:
                return .primary
        }
    }
}

struct ShortGridView_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var simulation = Simulation()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    
    static var previews: some View {
        simulation.compute(nbOfYears      : 25,
                           nbOfRuns       : 10,
                           withFamily     : family,
                           withPatrimoine : patrimoine)
        return
            NavigationView {
                NavigationLink(destination: ShortGridView()
                                .preferredColorScheme(.dark)
                                .environmentObject(uiState)
                                .environmentObject(simulation)) {
                    Text("Synthèse")
                }
                .isDetailLink(true)
            }
            .preferredColorScheme(.dark)
    }
}
