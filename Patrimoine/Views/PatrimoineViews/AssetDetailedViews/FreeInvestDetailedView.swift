//
//  FreeInvestView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 25/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct FreeInvestDetailedView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    
    // commun
    private var originalItem     : FreeInvestement?
    @State private var localItem : FreeInvestement
    @State private var alertItem : AlertItem?
    @State private var index     : Int?
    // à adapter
    @State private var totalValue : Double = 0.0

    var body: some View {
        Form {
            LabeledTextField(label: "Nom", defaultText: "obligatoire", text: $localItem.name)
            LabeledTextEditor(label: "Note", text: $localItem.note)
            
            /// propriété
            OwnershipView(ownership  : $localItem.ownership,
                          totalValue : localItem.value(atEndOf  : Date.now.year))
            
            Section(header: Text("TYPE")) {
                TypeInvestEditView(investType: $localItem.type)
            }
            
            Section(header: Text("INITIALISATION")) {
                YearPicker(title    : "Année d'actualisation",
                           inRange  : Date.now.year - 20...Date.now.year + 100,
                           selection: $localItem.initialState.year)
                AmountEditView(label : "Valeure actualisée",
                               amount: $totalValue)
                    .onChange(of: totalValue) { newValue in
                        localItem.initialState.investment = newValue - localItem.initialState.interest
                    }
                AmountEditView(label: "dont plus-values",
                               amount: $localItem.initialState.interest)
                    .onChange(of: localItem.initialState.interest) { newValue in
                        localItem.initialState.investment = totalValue - newValue
                    }
            }
            
            Section(header: Text("RENTABILITE")) {
                InterestRateTypeEditView(rateType: $localItem.interestRateType)
                PercentView(label: "Rendement moyen net d'inflation",
                            percent: localItem.averageInterestRateNet/100.0)
                    .foregroundColor(.secondary)
            }
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .navigationTitle("Invest. Libre")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button(
                action : duplicate,
                label  : { Text("Dupliquer") })
                .capsuleButtonStyle()
                .disabled((index == nil) || changeOccured()),
            trailing: Button(
                action: applyChanges,
                label: { Text("Sauver") })
                .capsuleButtonStyle()
                .disabled(!changeOccured())
        )
        .alert(item: $alertItem, content: myAlert)
    }
    
    init(item       : FreeInvestement?,
         family     : Family,
         patrimoine : Patrimoin) {
        self.originalItem = item
        if let initialItemValue = item {
            // modification d'un élément existant
            _localItem  = State(initialValue: initialItemValue)
            _index      = State(initialValue: patrimoine.assets.freeInvests.items.firstIndex(of: initialItemValue))
            _totalValue = State(initialValue: initialItemValue.initialState.value)
            // specific
        } else {
            // création d'un nouvel élément
            var newItem = FreeInvestement(year             : Date.now.year - 1,
                                          name             : "",
                                          note             : "",
                                          type             : .other,
                                          interestRateType : .contractualRate(fixedRate: 0.0),
                                          initialValue     : 0,
                                          initialInterest  : 0)
            // définir le délégué pour la méthode ageOf qui par défaut est nil à la création de l'objet
            newItem.ownership.setDelegateForAgeOf(delegate: family.ageOf)
            _localItem = State(initialValue: newItem)
            index = nil
        }
    }
    
    private func resetSimulation() {
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()
    }
    
    private func duplicate() {
        // générer un nouvel identifiant pour la copie
        localItem.id = UUID()
        localItem.name += "-copie"
        // ajouter la copie
        patrimoine.assets.freeInvests.add(localItem)
        // revenir à l'élement avant duplication
        localItem = originalItem!
        
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }
    
    // sauvegarder les changements
    private func applyChanges() {
        // validation avant sauvegarde
        guard self.isValid() else { return }
        
        if let index = index {
            // modifier un éléménet existant
            patrimoine.assets.freeInvests.update(with: localItem, at: index)
        } else {
            // générer un nouvel identifiant pour le nouvel item
            localItem.id = UUID()
            // définir le délégué pour la méthode ageOf qui par défaut est nil à la création de l'objet
            localItem.ownership.setDelegateForAgeOf(delegate: family.ageOf)
            // ajouter le nouvel élément à la liste
            patrimoine.assets.freeInvests.add(localItem)
        }
        
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }
    
    private func isValid() -> Bool {
        /// vérifier que le nom n'est pas vide
        guard localItem.name != "" else {
            self.alertItem = AlertItem(title         : Text("Donner un nom"),
                                       dismissButton : .default(Text("OK")))
            return false
        }
        
        /// vérifier que les propriétaires sont correctements définis
        guard localItem.ownership.isValid else {
            self.alertItem = AlertItem(title         : Text("Les propriétaires ne sont pas correctements définis"),
                                       dismissButton : .default(Text("OK")))
            return false
        }
        
        /// vérifier que la clause bénéficiaire est valide
        switch localItem.type {
            case .lifeInsurance(_, let clause):
                guard clause.isValid else {
                    self.alertItem = AlertItem(title         : Text("La clause bénéficiare n'est pas valide"),
                                               dismissButton : .default(Text("OK")))
                    return false
                }

            default: ()
        }
        
        return true
    }
    
    private func changeOccured() -> Bool {
        return localItem != originalItem
    }
}

struct FreeInvestDetailedView_Previews: PreviewProvider {
    static var family     = Family()
    static var patrimoine = Patrimoin()

    static var previews: some View {
        return
            Group {
//                NavigationView() {
                    FreeInvestDetailedView(item       : patrimoine.assets.freeInvests[0],
                                           family     : family,
                                           patrimoine : patrimoine)
                        .environmentObject(patrimoine)
                }
                .previewDisplayName("FreeInvestDetailedView")
//            }
    }
}
