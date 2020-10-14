//
//  ComputationView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import ActivityIndicatorView

struct ComputationView: View {
    @EnvironmentObject var uiState          : UIState
    @EnvironmentObject var family           : Family
    @EnvironmentObject var patrimoine       : Patrimoin
    @EnvironmentObject var simulation       : Simulation
    @State private var busySaveWheelAnimate : Bool = false
    @State private var busyCompWheelAnimate : Bool = false
    
    struct ComputationForm: View {
        @EnvironmentObject var uiState    : UIState
        @EnvironmentObject var simulation : Simulation
        
        var body: some View {
            Form {
                // paramétrage de la simulation : cas général
                Section(header: Text("Paramètres de Simulation").font(.headline)) {
                    HStack{
                        Text("Titre")
                            .frame(width: 70, alignment: .leading)
                        TextField("", text: $simulation.title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    //.padding(.top)
                    HStack {
                        Text("Nombre d'années à calculer: ") + Text(String(Int(uiState.computationState.nbYears)))
                        Slider(value : $uiState.computationState.nbYears,
                               in    : 5 ... 50,
                               step  : 5,
                               onEditingChanged: {_ in
                               })
                    }
                    // choix du mode de simulation: cas spécifiques
                    // sélecteur: Déterministe / Aléatoire
                    CasePicker(pickedCase: $simulation.mode, label: "")
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: simulation.mode) { newMode in
                            Patrimoin.setSimulationMode(to: newMode)
                            Pension.setSimulationMode(to: newMode)
                        }
                    switch simulation.mode {
                        case .deterministic:
                            EmptyView()
                            
                        case .random:
                            HStack {
                                Text("Nombre de run: ") + Text(String(Int(uiState.computationState.nbRuns)))
                                Slider(value : $uiState.computationState.nbRuns,
                                       in    : 100 ... 1000,
                                       step  : 100,
                                       onEditingChanged: {_ in
                                       })
                            }
                    }
                }
                // affichage des résultats
                Section(header: Text("Résultats").font(.headline)) {
                    if simulation.isComputed {
                        HStack {
                            Text("Simulation disponible: de \(simulation.firstYear!) à \(simulation.lastYear!)")
                                .font(.callout)
                            if simulation.mode == .random {
                                Spacer(minLength: 100)
                                IntegerView(label   : "Nombre de run exécutés",
                                            integer : simulation.mode == .deterministic ? 1  : simulation.currentRunNb)
                            }
                        }
                        
                    } else {
                        // pas de données à afficher
                        VStack(alignment: .leading) {
                            Text("Aucune données à présenter")
                            Text("Calculer une simulation au préalable").foregroundColor(.red)
                        }
                    }
                }
                if simulation.isComputed {
                    ForEach(simulation.kpis) { kpi in
                        Section(header: Text(kpi.name)) {
                            if kpi.value(withMode: simulation.mode) != nil {
                                KpiSummaryView(kpi         : kpi,
                                               withPadding : false,
                                               withDetails : false)
                            } else {
                                Text("Valeure indéfinie")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        ComputationForm()
            .navigationTitle("Calcul")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    // bouton sauvegarder
                    Button(action: saveSimulation,
                           label: {
                            HStack(alignment: .center) {
                                if busySaveWheelAnimate {
                                    ProgressView()
                                }
                                Image(systemName: "pencil.and.ellipsis.rectangle")
                                    .imageScale(.large)
                                Text("Enregistrer")
                            }
                           }
                    )
                    .capsuleButtonStyle()
                    .disabled(!(simulation.isComputed && !simulation.isSaved))
                    .opacity(!(simulation.isComputed && !simulation.isSaved) ? 0.5 : 1.0)
                }
                ToolbarItem(placement: .primaryAction) {
                    // bouton calculer
                    Button(action: computeSimulation,
                           label: {
                            HStack(alignment: .center) {
                                if busyCompWheelAnimate {
                                    ProgressView()
                                }
                                Image(systemName: "function")
                                    .imageScale(.large)
                                Text("Calculer")
                            }
                           }
                    )
                    .capsuleButtonStyle()
                }
            }
    }
    
    func computeSimulation() {
        busyCompWheelAnimate.toggle()
        // executer les calculs en tâche de fond
        //DispatchQueue.global(qos: .userInitiated).async {
        switch simulation.mode {
            case .deterministic:
                simulation.compute(nbOfYears      : Int(uiState.computationState.nbYears),
                                   nbOfRuns       : 1,
                                   withFamily     : family,
                                   withPatrimoine : patrimoine)
                
            case .random:
                simulation.compute(nbOfYears      : Int(uiState.computationState.nbYears),
                                   nbOfRuns       : Int(uiState.computationState.nbRuns),
                                   withFamily     : family,
                                   withPatrimoine : patrimoine)
        }
        // mettre à jour les variables d'état dans le thread principal
        //DispatchQueue.main.async {
        uiState.bsChartState.itemSelection = simulation.socialAccounts.getBalanceSheetLegend(.both)
        uiState.cfChartState.itemSelection = simulation.socialAccounts.getCashFlowLegend(.both)
        //}
        //}
        busyCompWheelAnimate.toggle()
        #if DEBUG
        // self.simulation.socialAccounts.printBalanceSheetTable()
        #endif
    }
    
    func saveSimulation() {
        busySaveWheelAnimate.toggle()
        // executer l'enregistrement en tâche de fond
        DispatchQueue.global(qos: .userInitiated).async {
            self.simulation.save()
            // mettre à jour les variables d'état dans le thread principal
            DispatchQueue.main.async {
                self.busySaveWheelAnimate.toggle()
                self.simulation.isSaved = true
            }
        }
    }
}

struct ComputationView_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()
    
    static var previews: some View {
        NavigationView() {
            ComputationView()
                .environmentObject(uiState)
                .environmentObject(family)
                .environmentObject(patrimoine)
                .environmentObject(simulation)
        }
        //.colorScheme(.dark)
        //.padding()
        //.previewLayout(PreviewLayout.sizeThatFits)
    }
}

