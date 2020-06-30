//
//  RealEstateDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 10/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct RealEstateDetailedView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState

    var item: RealEstateAsset?
    // commun
    @EnvironmentObject var patrimoine: Patrimoin
    @Environment(\.presentationMode) var presentationMode
    @State private var index: Int?
    // à adapter
    @State private var localItem = RealEstateAsset(name : "",
                                                   buyingDate           : Date.now,
                                                   buyingPrice          : 0,
                                                   yearlyTaxeHabitation : 0,
                                                   yearlyTaxeFonciere   : 0)
    
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
            Section(header: Text("TAXES")) {
                AmountEditView(label: "Taxe d'habitation annuelle",
                               amount: $localItem.yearlyTaxeHabitation)
                AmountEditView(label: "Taxe fonçière annuelle",
                               amount: $localItem.yearlyTaxeFonciere)
            }
            // habitation
            Section(header: Text("HABITATION")) {
                Toggle("Période d'occupation", isOn: $localItem.willBeInhabited)
                if localItem.willBeInhabited {
                    DateRangeEditView(fromLabel : "Début d'habitation",
                                      fromDate  : $localItem.inhabitedFromDate,
                                      toLabel   : "Fin d'habitation",
                                      toDate    : $localItem.inhabitedToDate,
                                      in        : localItem.buyingDate ... min(localItem.sellingDate, 100.years.fromNow!))
                        .padding(.leading)
                }
            }
            // location
            Section(header: Text("LOCATION")) {
                Toggle("Période de location", isOn: $localItem.willBeRented)
                if localItem.willBeRented {
                    Group {
                        DateRangeEditView(fromLabel: "Début de location",
                                          fromDate: $localItem.rentalFromDate,
                                          toLabel: "Fin de location",
                                          toDate: $localItem.rentalToDate,
                                          in: localItem.buyingDate ... min(localItem.sellingDate, 100.years.fromNow!))
                        AmountEditView(label: "Loyer mensuel net de frais",
                                       amount: $localItem.monthlyRentAfterCharges)
                        AmountView(label: "Charges sociales sur loyers",
                                   amount: localItem.yearlyRentSocialTaxes)
                            .foregroundColor(.secondary)
                        PercentView(label: "Rendement locatif net de charges sociales",
                                    percent: localItem.profitability)
                            .foregroundColor(.secondary)
                    }.padding(.leading)
                }
            }
            // vente
            Section(header: Text("VENTE")) {
                Toggle("Sera vendue", isOn: $localItem.willBeSold)
                if localItem.willBeSold {
                    Group {
                        DatePicker(selection: $localItem.sellingDate,
                                   in: localItem.buyingDate ... 100.years.fromNow!,
                                   displayedComponents: .date,
                                   label: { Text("Date de vente") })
                        AmountEditView(label: "Prix de vente net de frais",
                                       amount: $localItem.sellingNetPrice)
                        AmountView(label: "Produit net de charges et impôts",
                                   amount: localItem.sellingPriceAfterTaxes)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading)
                }
            }
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .avoidKeyboard()
            //.onAppear(perform: onAppear)
            .navigationBarTitle(Text("Immeuble"), displayMode: .inline)
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

    init(item: RealEstateAsset?, patrimoine: Patrimoin) {
        self.item = item
        if let initialItemValue = item {
            // modification d'un élément existant
            _localItem = State(initialValue: initialItemValue)
            _index     = State(initialValue: patrimoine.assets.realEstates.items.firstIndex(of: initialItemValue))
            // specific
        } else {
            index = nil
        }
    }
    
    func duplicate() {
        if index != nil {
            patrimoine.assets.realEstates.add(localItem)
        }
    }
    
    // sauvegarder les changements
    func applyChanges() {
        if let index = index {
            // modifier un éléménet existant
            patrimoine.assets.realEstates.update(with: localItem, at: index)
        } else {
            // créer un nouvel élément
            patrimoine.assets.realEstates.add(localItem)
        }
        
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.simulationViewState.selectedItem = nil

        //patrimoine.assets.realEstates.storeItemsToFile()
        self.presentationMode.wrappedValue.dismiss()
    }
    
    func changeOccured() -> Bool {
        return localItem != item
    }
}

struct RealEstateDetailedView_Previews: PreviewProvider {
    static var patrimoine  = Patrimoin()

    static var previews: some View {
        return
            NavigationView() {
                RealEstateDetailedView(item: patrimoine.assets.realEstates[0], patrimoine: patrimoine)
                    .environmentObject(patrimoine)
            }
            .previewDisplayName("RealEstateDetailedView")
    }
}

