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
                if !simulation.isComputed {
                    // pas de données à afficher
                    VStack(alignment: .leading) {
                        Text("Aucune données à présenter")
                        Text("Calculer une simulation au préalable").foregroundColor(.red)
                    }
                    
                } else {
                    Text("Simulation disponible: \(simulation.firstYear!) à \(simulation.lastYear!)")
                        .font(.callout)
                }
            }
        }
    }
    
    var body: some View {
        ComputationForm()
            .navigationTitle("Calcul")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
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
                    .disabled(!(simulation.isComputed && !simulation.isSaved))
                    .opacity(!(simulation.isComputed && !simulation.isSaved) ? 0.5 : 1.0)
                }
                ToolbarItem(placement: .bottomBar) {
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
                }
            }
    }
    
    func computeSimulation() {
        busyCompWheelAnimate.toggle()
        // executer les calculs en tâche de fond
        //DispatchQueue.global(qos: .userInitiated).async {
        simulation.compute(nbOfYears      : Int(uiState.computationState.nbYears),
                           withFamily     : family,
                           withPatrimoine : patrimoine)
        // mettre à jour les variables d'état dans le thread principal
        //DispatchQueue.main.async {
        uiState.bsChartState.itemSelection = simulation.socialAccounts.getBalanceSheetLegend(.both)
        uiState.cfChartState.itemSelection = simulation.socialAccounts.getCashFlowLegend(.both)
        //}
        //}
        busyCompWheelAnimate.toggle()
        #if DEBUG
        self.simulation.socialAccounts.printBalanceSheetTable()
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

