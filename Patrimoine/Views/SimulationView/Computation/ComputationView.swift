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
    @EnvironmentObject var patrimoine       : Patrimoine
    @EnvironmentObject var simulation       : Simulation
    @State private var busySaveWheelAnimate : Bool = false
    @State private var busyCompWheelAnimate : Bool = false
    
    var body: some View {
        VStack {
            Form {
            HStack{
                Text("Titre")
                    .frame(width: 70, alignment: .leading)
                TextField("", text: $simulation.title)
            }
            HStack {
                Text("Nombre d'années à calculer: ") + Text(String(Int(uiState.computationState.nbYears)))
                Slider(value : $uiState.computationState.nbYears,
                       in    : 5 ... 50,
                       step  : 5,
                       onEditingChanged: {_ in
                })
            }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .avoidKeyboard()
            .padding(.top)

            Spacer()
            
            HStack {
                // bouton calculer
                    Button(action: computeSimulation,
                           label: {
                            HStack(alignment: .center) {
                                if busyCompWheelAnimate {
                                    ActivityIndicatorView(isVisible: $busyCompWheelAnimate, type: .flickeringDots)
                                        .frame(maxWidth: 50, maxHeight: 50)
                                } else {
                                    Image(systemName: "function")
                                        .imageScale(.large)//.padding(.trailing, 4.0)
                                }
                                Text("Calculer")
                            }
                    }
                    )
                        .myButtonStyle(width: 125)
                
                Spacer()
                
                // bouton sauvegarder
                Button(action: saveSimulation,
                       label: {
                        HStack(alignment: .center) {
                            if busySaveWheelAnimate {
                                ActivityIndicatorView(isVisible: $busySaveWheelAnimate,
                                                      type: .flickeringDots)
                                    .frame(maxWidth: 20, maxHeight: 20)
                            } else {
                                Image(systemName: "pencil.and.ellipsis.rectangle")
                                    .imageScale(.large)//.padding(.trailing)
                            }
                            Text("Enregistrer")
                        }
                }
                )
                    .myButtonStyle(width: 125)
                    .disabled(!(simulation.isComputed && !simulation.isSaved))
                    .opacity(!(simulation.isComputed && !simulation.isSaved) ? 0.5 : 1.0)
            }.padding()
        }
        .padding(.horizontal)
        .navigationBarTitle("Calcul", displayMode: .inline)
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
    static var family     = Family()
    static var patrimoine = Patrimoine()
    static var simulation = Simulation()
    
    static var previews: some View {
        ComputationView()
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
        //.colorScheme(.dark)
        //.padding()
        //.previewLayout(PreviewLayout.sizeThatFits)
    }
}
