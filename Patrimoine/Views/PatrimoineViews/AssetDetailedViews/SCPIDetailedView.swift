//
//  SCPIDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct SCPIDetailedView: View {
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState

    var item: SCPI?
    var updateItem: (_ item: SCPI, _ index: Int) -> ()
    var addItem: (_ item: SCPI) -> ()
    // commun
    @EnvironmentObject var family: Family
    @Environment(\.presentationMode) var presentationMode
    @State private var index: Int?
    // à adapter
    @State private var localItem = SCPI(name : "",
                                        buyingDate   : Date.now,
                                        buyingPrice  : 0,
                                        interestRate : 0,
                                        revaluatRate : 0)
    
    var body: some View {
        Form {
            HStack{
                Text("Nom")
                    .frame(width: 70, alignment: .leading)
                TextField("obligatoire", text: $localItem.name)
            }
            // acquisition
            Section(header: Text("ACQUISITION")) {
                DatePicker(selection: $localItem.buyingDate,
                           displayedComponents: .date,
                           label: { Text("Date d'acquisition") })
                AmountEditView(label: "Prix d'acquisition",
                               amount: $localItem.buyingPrice)
            }
            // taxe
            Section(header: Text("RENDEMENT")) {
                PercentEditView(label: "Taux de rendement annuel brut",
                                percent: $localItem.interestRate)
                AmountView(label: "Revenu annuel brut",
                           amount: localItem.yearlyRevenue(atEndOf: Date.now.year).revenue)
                    .foregroundColor(.secondary)
                AmountView(label: "Revenu annuel net de charges",
                           amount: localItem.yearlyRevenue(atEndOf: Date.now.year).taxableIrpp)
                    .foregroundColor(.secondary)
                AmountView(label: "Charges sociales",
                           amount: localItem.yearlyRevenue(atEndOf: Date.now.year).socialTaxes)
                    .foregroundColor(.secondary)
                PercentEditView(label: "Taux de réévaluation annuel",
                                percent: $localItem.revaluatRate)
            }
            // vente
            Section(header: Text("VENTE")) {
                Toggle("Sera vendue", isOn: $localItem.willBeSold)
                if localItem.willBeSold {
                    Group {
                        DatePicker(selection: $localItem.sellingDate,
                                   in: localItem.buyingDate...100.years.fromNow!,
                                   displayedComponents: .date,
                                   label: { Text("Date de vente") })
                        AmountView(label: "Valeur à la date de vente",
                                   amount: localItem.value(atEndOf: localItem.sellingDate.year))
                            .foregroundColor(.secondary)
                        AmountView(label: "Produit net de charge et d'impôts",
                                   amount: localItem.liquidatedValue(localItem.sellingDate.year).netRevenue)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading)
                }
            }
            
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .avoidKeyboard()
            //.onAppear(perform: onAppear)
            .navigationBarTitle(Text("SCPI"), displayMode: .inline)
            .navigationBarItems(
                leading: Button(
                    action : duplicate,
                    label  : { Text("Dupliquer")} )
                        .disabled(index == nil),
                trailing: Button(
                    action: applyChanges,
                    label: { Text("Sauver") } )
                    .disabled(!changeOccured())
        )
    }
    
    init(item       : SCPI?,
         //patrimoine : Patrimoine,
         updateItem : @escaping (SCPI, Int) -> (),
         addItem    : @escaping (SCPI) -> (),
         firstIndex : (SCPI) -> Int?) {
        // store closure to differentiate between SCPI and SCI.SCPI
        self.updateItem = updateItem
        self.addItem    = addItem
        
        self.item = item
        if let initialItemValue = item {
            // modification d'un élément existant
            _localItem = State(initialValue: initialItemValue)
            _index     = State(initialValue: firstIndex(initialItemValue))
            // specific
        } else {
            index = nil
        }
    }
    
    func duplicate() {
        if index != nil {
            addItem(localItem)
        }
    }
    
    // sauvegarder les changements
    func applyChanges() {
        if let index = index {
            // modifier un éléménet existant
            updateItem(localItem, index)
        } else {
            // créer un nouvel élément
            addItem(localItem)
        }
        
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.simulationViewState.selectedItem = nil

        self.presentationMode.wrappedValue.dismiss()
    }
    
    func changeOccured() -> Bool {
        return localItem != item
    }
}

struct SCPIDetailedView_Previews: PreviewProvider {
    static var patrimoine  = Patrimoin()

    static var previews: some View {
        return
            Group {
                NavigationView() {
                    SCPIDetailedView(item       : patrimoine.assets.scpis[0],
                                     //patrimoine     : patrimoine,
                                     updateItem : { (localItem, index) in patrimoine.assets.scpis.update(with: localItem, at: index) },
                                     addItem    : { (localItem) in patrimoine.assets.scpis.add(localItem) },
                                     firstIndex : { (localItem) in patrimoine.assets.scpis.items.firstIndex(of: localItem) })
                        .environmentObject(patrimoine)
                }
                .previewDisplayName("SCPIDetailedView")
        }
    }
}
