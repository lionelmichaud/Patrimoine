//
//  RealEstateDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 10/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - View Model for RealEstateAsset

class RealEstateViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published var inhabitedFromVM : DateBoundaryViewModel
    @Published var inhabitedToVM   : DateBoundaryViewModel
    @Published var rentalFrom      : DateBoundaryViewModel
    @Published var rentalTo        : DateBoundaryViewModel
    
    // MARK: - Initializers of ViewModel from Model
    
    internal init(from asset: RealEstateAsset) {
        self.inhabitedFromVM = DateBoundaryViewModel(from: asset.inhabitedFrom)
        self.inhabitedToVM   = DateBoundaryViewModel(from: asset.inhabitedTo)
        self.rentalFrom      = DateBoundaryViewModel(from: asset.rentalFrom)
        self.rentalTo        = DateBoundaryViewModel(from: asset.rentalTo  )
    }
    
    // MARK: - Methods
    
    // construire l'objet de type LifeExpenseTimeSpan correspondant au ViewModel
    func update(thisAsset asset: inout RealEstateAsset) {
        asset.inhabitedFrom = self.inhabitedFromVM.dateBoundary
        asset.inhabitedTo   = self.inhabitedToVM.dateBoundary
        asset.rentalFrom    = self.rentalFrom.dateBoundary
        asset.rentalTo      = self.rentalTo.dateBoundary
    }
    
    func differs(from thisAsset: RealEstateAsset) -> Bool {
        return
            self.inhabitedFromVM != DateBoundaryViewModel(from: thisAsset.inhabitedFrom) ||
            self.inhabitedToVM != DateBoundaryViewModel(from: thisAsset.inhabitedTo) ||
            self.rentalFrom != DateBoundaryViewModel(from: thisAsset.rentalFrom) ||
            self.rentalTo   != DateBoundaryViewModel(from: thisAsset.rentalTo)
    }
}

// MARK: - View

struct RealEstateDetailedView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    
    private var originalItem: RealEstateAsset?
    // commun
    @EnvironmentObject var patrimoine: Patrimoin
    @Environment(\.presentationMode) var presentationMode
    @State private var index: Int?
    // à adapter
    @StateObject private var assetVM : RealEstateViewModel
    @State private var localItem     : RealEstateAsset
    
    var body: some View {
        Form {
            LabeledTextField(label: "Nom", defaultText: "obligatoire", text: $localItem.name)
            LabeledTextEditor(label: "Note", text: $localItem.note)
            
            /// acquisition
            Section(header: Text("ACQUISITION")) {
                IntegerEditView(label: "Année d'acquisition", integer: $localItem.buyingYear)
                AmountEditView(label: "Prix d'acquisition",
                               amount: $localItem.buyingPrice)
            }
            
            /// taxe
            Section(header: Text("TAXES")) {
                AmountEditView(label: "Taxe d'habitation annuelle",
                               amount: $localItem.yearlyTaxeHabitation)
                AmountEditView(label: "Taxe fonçière annuelle",
                               amount: $localItem.yearlyTaxeFonciere)
            }
            
            /// habitation
            Section(header: Text("HABITATION")) {
                Toggle("Période d'occupation", isOn: $localItem.willBeInhabited)
                if localItem.willBeInhabited {
                    FromToEditView(from : $assetVM.inhabitedFromVM,
                                   to   : $assetVM.inhabitedToVM)
                        .padding(.leading)
                }
            }
            
            /// location
            Section(header: Text("LOCATION")) {
                Toggle("Période de location", isOn: $localItem.willBeRented)
                if localItem.willBeRented {
                    Group {
                        FromToEditView(from : $assetVM.rentalFrom,
                                       to   : $assetVM.rentalTo  )
                        AmountEditView(label: "Loyer mensuel net de frais",
                                       amount: $localItem.monthlyRentAfterCharges)
                        AmountView(label: "Charges sociales annuelles sur loyers",
                                   amount: localItem.yearlyRentSocialTaxes)
                            .foregroundColor(.secondary)
                        PercentView(label: "Rendement locatif net de charges sociales",
                                    percent: localItem.profitability)
                            .foregroundColor(.secondary)
                    }.padding(.leading)
                }
            }
            
            /// vente
            Section(header: Text("VENTE")) {
                Toggle("Sera vendue", isOn: $localItem.willBeSold)
                if localItem.willBeSold {
                    Group {
                        IntegerEditView(label: "Année de vente", integer: $localItem.sellingYear)
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
        .navigationTitle("Immeuble")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button(
                action : duplicate,
                label  : { Text("Dupliquer")} )
                .capsuleButtonStyle()
                .disabled((index == nil) || changeOccured()),
            trailing: Button(
                action: applyChanges,
                label: { Text("Sauver") } )
                .capsuleButtonStyle()
                .disabled(!changeOccured())
        )
    }
    
    init(item: RealEstateAsset?, patrimoine: Patrimoin) {
        self.originalItem = item
        if let initialItemValue = item {
            // modification d'un élément existant
            _localItem = State(initialValue: initialItemValue)
            _assetVM   = StateObject(wrappedValue: RealEstateViewModel(from: initialItemValue))
            _index     = State(initialValue: patrimoine.assets.realEstates.items.firstIndex(of: initialItemValue))
            // specific
        } else {
            // création d'un nouvel élément
            _localItem = State(initialValue: RealEstateAsset.empty)
            _assetVM   = StateObject(wrappedValue : RealEstateViewModel(from : RealEstateAsset.empty))
            index      = nil
        }
    }
    
    func duplicate() {
        // générer un nouvel identifiant pour la copie
        localItem.id = UUID()
        localItem.name += "-copie"
        // ajouter un élément à la liste
        patrimoine.assets.realEstates.add(localItem)
        // revenir à l'élement avant duplication
        localItem = originalItem!
    }
    
    // sauvegarder les changements
    func applyChanges() {
        // mettre à jour l'élément local à partir du ViwModel avant sauvegarde
        assetVM.update(thisAsset: &localItem)
        
        if let index = index {
            // modifier un éléménet existant
            patrimoine.assets.realEstates.update(with: localItem, at: index)
        } else {
            // créer un nouvel élément
            patrimoine.assets.realEstates.add(localItem)
        }
        
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()
        
        //patrimoine.assets.realEstates.storeItemsToFile()
        self.presentationMode.wrappedValue.dismiss()
    }
    
    func changeOccured() -> Bool {
        if localItem != originalItem {
            return true
        } else {
            return assetVM.differs(from: originalItem!)
        }
    }
}

struct FromToEditView: View {
    @Binding var from : DateBoundaryViewModel
    @Binding var to   : DateBoundaryViewModel

    var body: some View {
        Group{
            NavigationLink(destination: Form { BoundaryEditView(label    : "Début",
                                                                boundary : $from)} ) {
                HStack {
                    Text("Début (année inclue)")
                    Spacer()
                    Text(String((from.description)))
                }.foregroundColor(.blue)
            }
            NavigationLink(destination: Form { BoundaryEditView(label    : "Fin",
                                                                boundary : $to)} ) {
                HStack {
                    Text("Fin (année exclue)")
                    Spacer()
                    Text(String((to.description)))
                }.foregroundColor(.blue)
            }
            
        }
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

