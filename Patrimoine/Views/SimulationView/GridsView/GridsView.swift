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
                NavigationLink(destination : ShortGridView(),
                               tag         : .shortGridView,
                               selection   : $uiState.simulationViewState.selectedItem) {
                    Text("Synthèse")
                }
                .isDetailLink(true)
            }
        } else {
            EmptyView()
        }
    }
}

struct ShortGridView: View {
    @EnvironmentObject var simulation : Simulation
    
    var body: some View {
        let columns = [GridItem()]
        
        return
            VStack {
                // entête
                if simulation.resultTable.count != 0 {
                    GridHeaderView(line: simulation.resultTable.first!)
                }
                // tableau
                ScrollView([.vertical]) {
                    LazyVGrid(columns: columns) {
                        ForEach(simulation.resultTable, id: \.self) { line in
                            ShortGridLineView(line: line)
                        }
                    }
                }
                .border(Color.secondary)
            }
            .navigationTitle("Résultats des Runs de la Simulation")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct GridHeaderView : View {
    let line: SimulationResultLine
    let viewHeight = CGFloat(100)
    
    var body: some View {
        HStack {
            Text("Run")
                .italic()
                .frame(width: viewHeight)
                .rotationEffect(.degrees(-90))
                .frame(width: 28)
            Divider()
            // propriétés aléatoires des adultes
            ForEach(line.dicoOfAdultsRandomProperties.keys.sorted(), id: \.self) { name in
                Text("Espérance de Vie")
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
                    .frame(width: 65)
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
                    .frame(width: 28)
                Divider()
                // propriétés aléatoires des adultes
                ForEach(line.dicoOfAdultsRandomProperties.keys.sorted(), id: \.self) { name in
                    Text(String(line.dicoOfAdultsRandomProperties[name]!.ageOfDeath))
                        .frame(width: 28)
                    Divider()
                    Text(String(line.dicoOfAdultsRandomProperties[name]!.nbOfYearOfDependency))
                        .frame(width: 15)
                    Divider()
                }
                // valeurs aléatoires de conditions économiques
                ForEach(Economy.RandomVariable.allCases, id: \.self) { variableEnum in
                    Text((line.dicoOfEconomyRandomVariables[variableEnum]?.percentString(digit: 1) ?? "NaN") + "%")
                        .frame(width: 40)
                    Divider()
                }
                // valeurs aléatoires de conditions socio-économiques
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
                // valeurs résultantes des KPIs
                ForEach(SimulationKPIEnum.allCases, id: \.self) { kpiEnum in
                    if let kpiResult = line.dicoOfKpiResults[kpiEnum] {
                        Text(kpiResult.value.k€String)
                            .frame(width: 65)
                            .foregroundColor(kpiResult.objectiveIsReached ? .green : .red)
                    } else {
                        Text("-")
                            .frame(width: 65)
                    }
                    Divider()
                }
                Spacer()
            }
            .font(.callout)
            .allowsTightening(true)
        }
    }
}


struct ShortGridView_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var simulation = Simulation()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    
    static var previews: some View {
        simulation.compute(nbOfYears      : 15,
                           nbOfRuns       : 2,
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
