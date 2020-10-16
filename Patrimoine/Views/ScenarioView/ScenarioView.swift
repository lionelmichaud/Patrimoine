//
//  ScenarioView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ScenarioView: View {

    enum PushedItem {
        case computation, charts
    }
    
    var body: some View {
        NavigationView {
            /// Primary view
            List {
                // entête
                ScenarioHeaderView()
                
                // liste des items de la side bar
                ScenarioListView()
            }
            .defaultSideBarListStyle()
            .environment(\.horizontalSizeClass, .regular)
            .navigationTitle("Scénario")
//            .navigationBarItems(
//                leading: EditButton(),
//                trailing: Button(
//                    action: {
//                        withAnimation {
//                            self.showingSheet = true
//                        }
//                    },
//                    label: {
//                        Image(systemName: "plus").padding()
//                    }))
            
            /// vue par défaut
            ScenarioSummaryView()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct ScenarioHeaderView: View {
    var body: some View {
        Section {
            NavigationLink(destination: ScenarioSummaryView()) {
                Text("Résumé").fontWeight(.bold)
            }
            .isDetailLink(true)
        }
    }
}

struct ScenarioListView: View {
    var body: some View {
        ScenarioModelListView()
    }
}


struct ScenarioView_Previews: PreviewProvider {
    static var family     = Family()
    static var simulation = Simulation()
    
    static var previews: some View {
        ScenarioView()
            .environmentObject(family)
            .environmentObject(simulation)
    }
}
