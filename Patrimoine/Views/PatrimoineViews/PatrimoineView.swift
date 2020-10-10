//
//  AssetListView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct PatrimoineView: View {
    @EnvironmentObject var patrimoine: Patrimoin

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {

                List {
                    // entête
                    PatrimoineHeaderView()
                    
                    // actifs
                    AssetView()

                    // passifs
                    LiabilityView()
                }
                .defaultSideBarListStyle()
                //.listStyle(GroupedListStyle())
                .environment(\.horizontalSizeClass, .regular)

            }
            .onAppear(perform: { self.patrimoine.resetFreeInvestementCurrentValue() })
            .navigationTitle("Patrimoine")
            .navigationBarItems(
                leading: EditButton())

            // vue par défaut
            PatrimoineSummaryView()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct PatrimoineHeaderView: View {
    @EnvironmentObject var patrimoine: Patrimoin
    
    var body: some View {
        Group {
            Section {
                NavigationLink(destination: PatrimoineSummaryView()) {
                    Text("Résumé").fontWeight(.bold)
                }.isDetailLink(true)
            }
            Section {
                HStack {
                    Text("Actif Net")
                        .font(Font.system(size: 17,
                                          design: Font.Design.default))
                        .fontWeight(.bold)
                    Spacer()
                    Text(patrimoine.value(atEndOf: Date.now.year).€String)
                        .font(Font.system(size: 17,
                                          design: Font.Design.default))
                }
                .listRowBackground(ListTheme.rowsBaseColor)
            }
        }
    }
}

struct AssetListView_Previews: PreviewProvider {
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var uiState    = UIState()

    static var previews: some View {
        PatrimoineView()
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(uiState)
        //.colorScheme(.dark)
    }
}
