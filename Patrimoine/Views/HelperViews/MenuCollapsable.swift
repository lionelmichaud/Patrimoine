//
//  MenuCollapsable.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - Selection Menus View

struct MenuContentView: View {
    @Binding var itemSelection  : [(label  : String, selected  : Bool)]
    
    func setAll(selected: Bool) {
        for idx in 0 ..< itemSelection.count {
            itemSelection[idx].selected = selected
        }
    }
    
    var body: some View {
        // filtre des séries à (dé)sélectionner
        VStack {
            // Barre de titre
            HStack {
                Button(
                    action: {
                        self.setAll(selected: true)
                    },
                    label: {
                        HStack {
                            Text("Tout").font(.callout)
                            Image(systemName: "checkmark.square")
                        }
                    }).capsuleButtonStyle()
                Spacer()
                Button(
                    action: {
                        self.setAll(selected: false)
                    },
                    label: {
                        HStack {
                            Text("Rien").font(.callout)
                            Image(systemName: "square")
                        }
                    }).capsuleButtonStyle()
            }.padding(.horizontal)
            // menu
            List(0 ..< itemSelection.count) {idx in
                HStack {
                    Text(self.itemSelection[idx].label).font(.caption)
                    Spacer()
                    Image(systemName: self.itemSelection[idx].selected ? "checkmark.square" : "square")
                }
                .onTapGesture {
                    self.itemSelection[idx].selected.toggle()
                }
            }
            .listStyle(GroupedListStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Tests & Previews

struct MenuViews_Previews: PreviewProvider {
    static let itemSelection = [(label: "item 1", selected: true),
                                (label: "item 2", selected: true)]
    
    static var previews: some View {
        Group {
            Group {
                MenuContentView(itemSelection: .constant(itemSelection))
                    .previewLayout(PreviewLayout.fixed(width: 250, height: 250))
                    .padding()
                    .previewDisplayName("MenuContentView")
                Toggle(isOn: .constant(true), label: { Text("Toggle") })
                    .toggleStyle(CheckboxToggleStyle(size:.large))
                    .previewLayout(PreviewLayout.fixed(width: 250, height: 50))
                    .padding()
                    .previewDisplayName("CheckboxToggleStyle")
            }
        }
    }
}
