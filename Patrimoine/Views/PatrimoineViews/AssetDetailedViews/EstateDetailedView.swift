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
    @Published var rentalFromVM    : DateBoundaryViewModel
    @Published var rentalToVM      : DateBoundaryViewModel
    @Published var buyingYearVM    : DateBoundaryViewModel
    @Published var sellingYearVM   : DateBoundaryViewModel

    // MARK: - Initializers of ViewModel from Model
    
    internal init(from asset: RealEstateAsset) {
        self.inhabitedFromVM = DateBoundaryViewModel(from: asset.inhabitedFrom)
        self.inhabitedToVM   = DateBoundaryViewModel(from: asset.inhabitedTo)
        self.rentalFromVM    = DateBoundaryViewModel(from: asset.rentalFrom)
        self.rentalToVM      = DateBoundaryViewModel(from: asset.rentalTo  )
        self.buyingYearVM    = DateBoundaryViewModel(from: asset.buyingYear )
        self.sellingYearVM   = DateBoundaryViewModel(from: asset.sellingYear)
    }
    
    // MARK: - Methods
    
    // construire l'objet de type LifeExpenseTimeSpan correspondant au ViewModel
    func update(thisAsset asset: inout RealEstateAsset) {
        asset.inhabitedFrom = self.inhabitedFromVM.dateBoundary
        asset.inhabitedTo   = self.inhabitedToVM.dateBoundary
        asset.rentalFrom    = self.rentalFromVM.dateBoundary
        asset.rentalTo      = self.rentalToVM.dateBoundary
        asset.buyingYear    = self.buyingYearVM.dateBoundary
        asset.sellingYear   = self.sellingYearVM.dateBoundary
    }
    
    func differs(from thisAsset: RealEstateAsset) -> Bool {
        return
            self.inhabitedFromVM != DateBoundaryViewModel(from: thisAsset.inhabitedFrom) ||
            self.inhabitedToVM   != DateBoundaryViewModel(from: thisAsset.inhabitedTo) ||
            self.rentalFromVM    != DateBoundaryViewModel(from: thisAsset.rentalFrom) ||
            self.rentalToVM      != DateBoundaryViewModel(from: thisAsset.rentalTo) ||
            self.buyingYearVM    != DateBoundaryViewModel(from: thisAsset.buyingYear ) ||
            self.sellingYearVM   != DateBoundaryViewModel(from: thisAsset.sellingYear)
    }
}

// MARK: - View

struct RealEstateDetailedView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState

    // commun
    private var originalItem          : RealEstateAsset?
    @State private var localItem      : RealEstateAsset
    @State private var alertItem      : AlertItem?
    @State private var index          : Int?
    // à adapter
    @StateObject private var assetVM : RealEstateViewModel

    var body: some View {
        Form {
            LabeledTextField(label: "Nom", defaultText: "obligatoire", text: $localItem.name)
            LabeledTextEditor(label: "Note", text: $localItem.note)
            
            /// acquisition
            Section(header: Text("ACQUISITION")) {
                Group {
                    NavigationLink(destination: Form { BoundaryEditView(label    : "Première année de possession",
                                                                        boundary : $assetVM.buyingYearVM) } ) {
                        HStack {
                            Text("Première année de possession")
                            Spacer()
                            Text(String((assetVM.buyingYearVM.description)))
                        }.foregroundColor(.blue)
                    }
                    AmountEditView(label: "Prix d'acquisition",
                                   amount: $localItem.buyingPrice)
                }//.padding(.leading)
            }
            
            /// propriété
            OwnershipView(ownership: $localItem.ownership)
            
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
                        FromToEditView(from : $assetVM.rentalFromVM,
                                       to   : $assetVM.rentalToVM)
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
                        NavigationLink(destination: Form { BoundaryEditView(label    : "Dernière année de possession",
                                                                            boundary : $assetVM.sellingYearVM) } ) {
                            HStack {
                                Text("Dernière année de possession")
                                Spacer()
                                Text(String((assetVM.sellingYearVM.description)))
                            }.foregroundColor(.blue)
                        }
                        AmountEditView(label: "Prix de vente net de frais",
                                       amount: $localItem.sellingNetPrice)
                        AmountView(label: "Produit net de charges et impôts",
                                   amount: localItem.sellingPriceAfterTaxes)
                            .foregroundColor(.secondary)
                    }.padding(.leading)
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
        .alert(item: $alertItem, content: myAlert)
    }
    
    init(item       : RealEstateAsset?,
         family     : Family,
         patrimoine : Patrimoin) {
        self.originalItem = item
        if let initialItemValue = item {
            // modification d'un élément existant
            _localItem = State(initialValue: initialItemValue)
            _assetVM   = StateObject(wrappedValue: RealEstateViewModel(from: initialItemValue))
            _index     = State(initialValue: patrimoine.assets.realEstates.items.firstIndex(of: initialItemValue))
            // specific
//            // définir le délégué pour la méthode ageOf qui par défaut est nil à la création de l'objet
            localItem.ownership.setDelegateForAgeOf(delegate: family.ageOf)
        } else {
            // création d'un nouvel élément
            var newItem = RealEstateAsset(name: "")
            // définir le délégué pour la méthode ageOf qui par défaut est nil à la création de l'objet
            newItem.ownership.setDelegateForAgeOf(delegate: family.ageOf)
            _localItem = State(initialValue: newItem)
            _assetVM   = StateObject(wrappedValue : RealEstateViewModel(from : newItem))
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
        // validation avant sauvegarde
        guard self.isValid() else { return }

        // mettre à jour l'item à partir du ViewModel
        assetVM.update(thisAsset: &localItem)
        
        if let index = index {
            // modifier un éléménet existant
            patrimoine.assets.realEstates.update(with: localItem, at: index)
        } else {
            // générer un nouvel identifiant pour le nouvel item
            localItem.id = UUID()
            // définir le délégué pour la méthode ageOf qui par défaut est nil à la création de l'objet
            localItem.ownership.setDelegateForAgeOf(delegate: family.ageOf)
            // ajouter le nouvel élément à la liste
            patrimoine.assets.realEstates.add(localItem)
        }
        
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()
    }
    
    func isValid() -> Bool {
        /// vérifier que toutes les dates sont définies
        guard let _ = assetVM.buyingYearVM.year else {
            self.alertItem = AlertItem(title         : Text("La date d'achat doit être définie"),
                                       dismissButton : .default(Text("OK")))
            return false
        }
        if localItem.willBeInhabited {
            guard let _ = assetVM.inhabitedFromVM.year else {
                self.alertItem = AlertItem(title         : Text("La date de début d'habitation doit être définie"),
                                           dismissButton : .default(Text("OK")))
                return false
            }
            guard let _ = assetVM.inhabitedToVM.year else {
                self.alertItem = AlertItem(title         : Text("La date de fin d'habitation doit être définie"),
                                           dismissButton : .default(Text("OK")))
                return false
            }
        }
        if localItem.willBeRented {
            guard let _ = assetVM.rentalFromVM.year else {
                self.alertItem = AlertItem(title         : Text("La date de début de location doit être définie"),
                                           dismissButton : .default(Text("OK")))
                return false
            }
            guard let _ = assetVM.rentalToVM.year else {
                self.alertItem = AlertItem(title         : Text("La date de fin de location doit être définie"),
                                           dismissButton : .default(Text("OK")))
                return false
            }
        }
        if localItem.willBeSold {
            guard let _ = assetVM.sellingYearVM.year else {
                self.alertItem = AlertItem(title         : Text("La date de vente doit être définie"),
                                           dismissButton : .default(Text("OK")))
                return false
            }
        }
        
        /// vérifier que les dates sont dans le bon ordre
        if localItem.willBeSold {
            if assetVM.buyingYearVM.year! > assetVM.sellingYearVM.year! {
                self.alertItem = AlertItem(title         : Text("La date d'achat doit précéder la date de vente"),
                                           dismissButton : .default(Text("OK")))
                return false
            }
        }
        if localItem.willBeInhabited {
            if assetVM.inhabitedFromVM.year! > assetVM.inhabitedToVM.year! {
                self.alertItem = AlertItem(title         : Text("La date de début doit précéder la date de fin"),
                                           dismissButton : .default(Text("OK")))
                return false
            }
        }
        if localItem.willBeRented {
            if assetVM.rentalFromVM.year! > assetVM.rentalToVM.year! {
                self.alertItem = AlertItem(title         : Text("La date de début doit précéder la date de fin"),
                                           dismissButton : .default(Text("OK")))
                return false
            }
        }
        if localItem.willBeRented && localItem.willBeInhabited {
            if (assetVM.rentalFromVM.year! ... assetVM.rentalToVM.year!)
                .hasIntersection(with: assetVM.inhabitedFromVM.year! ... assetVM.inhabitedToVM.year!) {
                self.alertItem = AlertItem(title         : Text("Les périodes de location et d'habitation ne doivent pas avoir de recouvrement"),
                                           dismissButton : .default(Text("OK")))
                return false
            }
        }
        
        /// vérifier que le nom n'est pas vide
        guard localItem.name != "" else {
            self.alertItem = AlertItem(title         : Text("Donner un nom"),
                                       dismissButton : .default(Text("OK")))
            return false
        }
        
        /// vérifier que les propriétaires sont correctements définis
        guard localItem.ownership.isvalid else {
            self.alertItem = AlertItem(title         : Text("Les propriétaires ne sont pas correctements définis"),
                                       dismissButton : .default(Text("OK")))
            return false
        }
        
        return true
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
    static var family     = Family()
    static var patrimoine = Patrimoin()

    static var previews: some View {
        return
            NavigationView() {
                RealEstateDetailedView(item       : patrimoine.assets.realEstates[0],
                                       family     : family,
                                       patrimoine : patrimoine)
                    .environmentObject(family)
                    .environmentObject(patrimoine)
            }
            .previewDisplayName("RealEstateDetailedView")
    }
}

