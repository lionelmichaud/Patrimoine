//
//  AssetView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct AssetView: View {
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState

    var body: some View {
        Section {
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.assetViewState.colapseAsset,
                                label       : "Actif",
                                value       : patrimoine.assets.value(atEndOf: Date.now.year),
                                indentLevel : 0,
                                header      : true)
            
            if !uiState.patrimoineViewState.assetViewState.colapseAsset {
                // immobilier
                LabeledValueRowView(colapse     : $uiState.patrimoineViewState.assetViewState.colapseImmobilier,
                                    label       : "Immobilier",
                                    value       : patrimoine.assets.realEstates.value(atEndOf: Date.now.year) +
                                        patrimoine.assets.scpis.value(atEndOf: Date.now.year),
                                    indentLevel : 1,
                                    header      : true)
                if !uiState.patrimoineViewState.assetViewState.colapseImmobilier {
                    RealEstateView()
                    ScpiView()
                }
                
                // financier
                LabeledValueRowView(colapse     : $uiState.patrimoineViewState.assetViewState.colapseFinancier,
                                    label       : "Financier",
                                    value       : patrimoine.assets.periodicInvests.value(atEndOf: Date.now.year) +
                                        patrimoine.assets.freeInvests.value(atEndOf: Date.now.year),
                                    indentLevel : 1,
                                    header      : true)
                if !uiState.patrimoineViewState.assetViewState.colapseFinancier {
                    PeriodicInvestView()
                    FreeInvestView()
                }
                
                // SCI
                LabeledValueRowView(colapse     : $uiState.patrimoineViewState.assetViewState.colapseSCI,
                                    label       : "SCI",
                                    value       : patrimoine.assets.sci.scpis.value(atEndOf: Date.now.year) +
                                        patrimoine.assets.sci.bankAccount,
                                    indentLevel : 1,
                                    header      : true)
                if !uiState.patrimoineViewState.assetViewState.colapseSCI {
                    SciScpiView()
                }
            }
        }
    }
}
struct RealEstateView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState

    func removeItems(at offsets: IndexSet) {
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()

        patrimoine.assets.realEstates.delete(at: offsets)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        patrimoine.assets.realEstates.move(from: source, to: destination)
    }
    
    var body: some View {
        Group {
            // label
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.assetViewState.colapseEstate,
                                label       : "Immeuble",
                                value       : patrimoine.assets.realEstates.currentValue,
                                indentLevel : 2,
                                header      : true)
            if !uiState.patrimoineViewState.assetViewState.colapseEstate {
                // ajout d'un nouvel item à la liste
                NavigationLink(destination : RealEstateDetailedView(item      : nil,
                                                                    family     : family,
                                                                    patrimoine : patrimoine)) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                        Text("Ajouter un élément...")
                    }
                    .foregroundColor(.accentColor)
                }
                
                // liste des items
                ForEach(patrimoine.assets.realEstates.items) { item in
                    NavigationLink(destination: RealEstateDetailedView(item       : item,
                                                                       family     : family,
                                                                       patrimoine : patrimoine)) {
                        LabeledValueRowView(colapse     : self.$uiState.patrimoineViewState.assetViewState.colapseEstate,
                                            label       : item.name,
                                            value       : item.value(atEndOf: Date.now.year),
                                            indentLevel : 3,
                                            header      : false)
                    }
                    .isDetailLink(true)
                }
                .onDelete(perform: removeItems)
                .onMove(perform: move)
            }
        }
    }
}

struct ScpiView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState

    func removeItems(at offsets: IndexSet) {
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()

        patrimoine.assets.scpis.delete(at: offsets)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        patrimoine.assets.scpis.move(from: source, to: destination)
    }
    
    var body: some View {
        Group {
            // label
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.assetViewState.colapseSCPI,
                                label       : "SCPI",
                                value       : patrimoine.assets.scpis.currentValue,
                                indentLevel : 2,
                                header      : true)
            // items
            if !uiState.patrimoineViewState.assetViewState.colapseSCPI {
                // ajout d'un nouvel item à la liste
                NavigationLink(destination: ScpiDetailedView(item       : nil,
                                                             //family     : self.family,
                                                             updateItem : { (localItem, index) in
                                                                self.patrimoine.assets.scpis.update(with: localItem, at: index) },
                                                             addItem    : { (localItem) in
                                                                self.patrimoine.assets.scpis.add(localItem) },
                                                             family     : family,
                                                             firstIndex : { (localItem) in
                                                                self.patrimoine.assets.scpis.items.firstIndex(of: localItem) })) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                        Text("Ajouter un élément...")
                    }
                    .foregroundColor(.accentColor)
                }
                
                // liste des items
                ForEach(patrimoine.assets.scpis.items) { item in
                    NavigationLink(destination: ScpiDetailedView(item       : item,
                                                                 //family     : self.family,
                                                                 updateItem : { (localItem, index) in
                                                                    self.patrimoine.assets.scpis.update(with: localItem, at: index) },
                                                                 addItem    : { (localItem) in
                                                                    self.patrimoine.assets.scpis.add(localItem) },
                                                                 family     : family,
                                                                 firstIndex : { (localItem) in
                                                                    self.patrimoine.assets.scpis.items.firstIndex(of: localItem) })) {
                        LabeledValueRowView(colapse     : self.$uiState.patrimoineViewState.assetViewState.colapseSCPI,
                                            label       : item.name,
                                            value       : item.value(atEndOf: Date.now.year),
                                            indentLevel : 3,
                                            header      : false)
                    }
                    .isDetailLink(true)
                }
                .onDelete(perform: removeItems)
                .onMove(perform: move)
            }
        }
    }
}

struct PeriodicInvestView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState

    func removeItems(at offsets: IndexSet) {
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()

        patrimoine.assets.periodicInvests.delete(at: offsets)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        patrimoine.assets.periodicInvests.move(from: source, to: destination)
    }
    
    var body: some View {
        Group {
            // label
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.assetViewState.colapsePeriodic,
                                label       : "Invest Périodique",
                                value       : patrimoine.assets.periodicInvests.value(atEndOf: Date.now.year),
                                indentLevel : 2,
                                header      : true)
            // items
            if !uiState.patrimoineViewState.assetViewState.colapsePeriodic {
                // ajout d'un nouvel item à la liste
                NavigationLink(destination: PeriodicInvestDetailedView(item       : nil,
                                                                       family     : family,
                                                                       patrimoine : patrimoine)) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                        Text("Ajouter un élément...")
                    }
                    .foregroundColor(.accentColor)
                }
                
                // liste des items
                ForEach(patrimoine.assets.periodicInvests.items) { item in
                    NavigationLink(destination: PeriodicInvestDetailedView(item       : item,
                                                                           family     : family,
                                                                           patrimoine : self.patrimoine)) {
                        LabeledValueRowView(colapse     : self.$uiState.patrimoineViewState.assetViewState.colapsePeriodic,
                                            label       : item.name,
                                            value       : item.value(atEndOf: Date.now.year),
                                            indentLevel : 3,
                                            header      : false)
                    }
                    .isDetailLink(true)
                }
                .onDelete(perform: removeItems)
                .onMove(perform: move)
            }
        }
    }
}

struct FreeInvestView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState

    func removeItems(at offsets: IndexSet) {
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()

        patrimoine.assets.freeInvests.delete(at: offsets)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        patrimoine.assets.freeInvests.move(from: source, to: destination)
    }
    
    var body: some View {
        Group {
            // label
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.assetViewState.colapseFree,
                                label       : "Investissement Libre",
                                value       : patrimoine.assets.freeInvests.value(atEndOf: Date.now.year),
                                indentLevel : 2,
                                header      : true)
            
            // items
            if !uiState.patrimoineViewState.assetViewState.colapseFree {
                // ajout d'un nouvel item à la liste
                NavigationLink(destination: FreeInvestDetailedView(item       : nil,
                                                                   family     : family,
                                                                   patrimoine : patrimoine)) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                        Text("Ajouter un élément...")
                    }
                    .foregroundColor(.accentColor)
                }
                
                // liste des items
                ForEach(patrimoine.assets.freeInvests.items) { item in
                    NavigationLink(destination: FreeInvestDetailedView(item       : item,
                                                                       family     : family,
                                                                       patrimoine : self.patrimoine)) {
                        LabeledValueRowView(colapse     : self.$uiState.patrimoineViewState.assetViewState.colapseFree,
                                            label       : item.name,
                                            value       : item.value(atEndOf: Date.now.year),
                                            indentLevel : 3,
                                            header      : false)
                    }
                    .isDetailLink(true)
                }
                .onDelete(perform: removeItems)
                .onMove(perform: move)
            }
        }
    }
}

struct SciScpiView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState

    func removeItems(at offsets: IndexSet) {
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()

        patrimoine.assets.sci.scpis.delete(at: offsets)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        patrimoine.assets.sci.scpis.move(from: source, to: destination)
    }
    
    var body: some View {
        Group {
            // label
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.assetViewState.colapseSCISCPI,
                                label       : "SCPI",
                                value       : patrimoine.assets.sci.scpis.currentValue,
                                indentLevel : 2,
                                header      : true)
            // items
            if !uiState.patrimoineViewState.assetViewState.colapseSCISCPI {
                // ajout d'un nouvel item à la liste
                NavigationLink(destination: ScpiDetailedView(item       : nil,
                                                             //patrimoine : patrimoine,
                                                             updateItem : { (localItem, index) in
                                                                self.patrimoine.assets.sci.scpis.update(with: localItem, at: index) },
                                                             addItem    : { (localItem) in
                                                                self.patrimoine.assets.sci.scpis.add(localItem) },
                                                             family     : family,
                                                             firstIndex : { (localItem) in
                                                                self.patrimoine.assets.sci.scpis.items.firstIndex(of: localItem) })) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                        Text("Ajouter un élément...")
                    }
                    .foregroundColor(.accentColor)
                }
                
                // liste des items
                ForEach(patrimoine.assets.sci.scpis.items) { item in
                    NavigationLink(destination: ScpiDetailedView(item: item,
                                                                 //patrimoine : patrimoine,
                                                                 updateItem : { (localItem, index) in
                                                                    self.patrimoine.assets.sci.scpis.update(with: localItem, at: index) },
                                                                 addItem    : { (localItem) in
                                                                    self.patrimoine.assets.sci.scpis.add(localItem) },
                                                                 family     : family,
                                                                 firstIndex : { (localItem) in
                                                                    self.patrimoine.assets.sci.scpis.items.firstIndex(of: localItem) })) {
                        LabeledValueRowView(colapse     : self.$uiState.patrimoineViewState.assetViewState.colapseSCISCPI,
                                            label       : item.name,
                                            value       : item.value(atEndOf: Date.now.year),
                                            indentLevel : 3,
                                            header      : false)
                    }
                    .isDetailLink(true)
                }
                .onDelete(perform: removeItems)
                .onMove(perform: move)
            }
        }
    }
}

struct AssetView_Previews: PreviewProvider {
    static var simulation = Simulation()
    static var patrimoine = Patrimoin()
    static var uiState    = UIState()

    static var previews: some View {
        return
            Group {
                    NavigationView {
                        List {
                        AssetView()
                            .environmentObject(simulation)
                            .environmentObject(patrimoine)
                            .environmentObject(uiState)
                        }
                }
                    .colorScheme(.dark)
                    .previewDisplayName("AssetView")

                NavigationView {
                    List {
                        AssetView()
                            .environmentObject(simulation)
                            .environmentObject(patrimoine)
                            .environmentObject(uiState)
                    }
                }
                    .colorScheme(.light)
                    .previewDisplayName("AssetView")
            }
    }
}
