//
//  SwiftUIView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct FamilyView: View {
    @EnvironmentObject var family: Family
    @State var showingSheet = false
    
    var body: some View {
        NavigationView {
            List {
                // entête
                FamilyHeaderView()
                
                // liste des membres de la famille
                FamilyListView()
            }
                .listStyle(GroupedListStyle())
                .environment(\.horizontalSizeClass, .regular)
                .navigationBarTitle("Famille")
                .navigationBarItems(
                    leading: EditButton(),
                    trailing: Button(action: {
                        withAnimation {
                            self.showingSheet = true
                        }
                    },
                                     label: {
                                        Image(systemName: "plus").padding()
                    }))
            // vue par défaut
            FamilySummaryView()
        }
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
            // Vue modale de saisie d'un nouveau membre de la famille
            .sheet(isPresented: $showingSheet) {
                MemberAddView()
                    .environmentObject(self.family)
        }
    }
}

struct FamilyView_Previews: PreviewProvider {
    static let family  = Family()
    static let patrimoine = Patrimoin()
    static let uiState = UIState()

    static var previews: some View {
            FamilyView()
                .environmentObject(family)
                .environmentObject(patrimoine)
                .environmentObject(uiState)
                .colorScheme(.dark)
            //.previewLayout(.fixed(width: 1024, height: 768))
            //.previewLayout(.fixed(width: 896, height: 414))
            //.previewDevice(PreviewDevice(rawValue: "iPad Air (3rd generation)"))
            //.previewLayout(.sizeThatFits)
            //.environment(\.colorScheme, .dark)
            //.environment(\.colorScheme, .light)
            //.environment(\.locale, .init(identifier: "fr"))
    }
}

