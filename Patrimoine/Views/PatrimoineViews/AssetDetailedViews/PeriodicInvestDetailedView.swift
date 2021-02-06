//
//  PeriodicInvestDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 25/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct PeriodicInvestDetailedView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    
    // commun
    private var originalItem     : PeriodicInvestement?
    @State private var localItem : PeriodicInvestement
    @State private var alertItem : AlertItem?
    @State private var index     : Int?
    // à adapter

    var body: some View {
        Form {
            LabeledTextField(label: "Nom", defaultText: "obligatoire", text: $localItem.name)
            LabeledTextEditor(label: "Note", text: $localItem.note)
            
            /// propriété
            OwnershipView(ownership  : $localItem.ownership,
                          totalValue : localItem.value(atEndOf  : Date.now.year))
            
            // acquisition
            Section(header: Text("TYPE")) {
                TypeInvestEditView(investType: $localItem.type)
                AmountEditView(label: "Versement annuel - net de frais",
                               amount: $localItem.yearlyPayement)
                AmountEditView(label: "Frais annuels sur versements",
                               amount: $localItem.yearlyCost)
            }
            
            Section(header: Text("INITIALISATION")) {
                YearPicker(title: "Année de départ (fin d'année)",
                           inRange: Date.now.year - 20...Date.now.year + 100,
                           selection: $localItem.firstYear)
                AmountEditView(label: "Valeure initiale",
                               amount: $localItem.initialValue)
                AmountEditView(label: "Intérêts initiaux",
                               amount: $localItem.initialInterest)
            }
            
            Section(header: Text("RENTABILITE")) {
                InterestRateTypeEditView(rateType: $localItem.interestRateType)
                PercentView(label: "Rendement moyen net d'inflation",
                            percent: localItem.averageInterestRateNet/100.0)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("LIQUIDATION")) {
                YearPicker(title: "Année de liquidation (fin d'année)",
                           inRange: localItem.firstYear...localItem.firstYear + 100,
                           selection: $localItem.lastYear)
                AmountView(label: "Valeur liquidative avant prélèvements sociaux et IRPP",
                           amount: liquidatedValue())
                    .foregroundColor(.secondary)
                AmountView(label: "Prélèvements sociaux",
                           amount: socialTaxes())
                    .foregroundColor(.secondary)
                AmountView(label: "Valeure liquidative net de prélèvements sociaux",
                           amount: liquidatedValueAfterSocialTaxes())
                    .foregroundColor(.secondary)
                AmountView(label: "Intérêts cumulés avant prélèvements sociaux",
                           amount: cumulatedInterests())
                    .foregroundColor(.secondary)
                AmountView(label: "Intérêts cumulés après prélèvements sociaux",
                           amount: netCmulatedInterests())
                    .foregroundColor(.secondary)
                AmountView(label: "Intérêts cumulés taxables à l'IRPP",
                           amount: netCmulatedInterests())
                    .foregroundColor(.secondary)
            }
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .navigationTitle("Invest. Périodique")
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
    
    init(item       : PeriodicInvestement?,
         family     : Family,
         patrimoine : Patrimoin) {
        self.originalItem = item
        if let initialItemValue = item {
            // modification d'un élément existant
            _localItem = State(initialValue: initialItemValue)
            _index     = State(initialValue: patrimoine.assets.periodicInvests.items.firstIndex(of: initialItemValue))
            // specific
        } else {
            // création d'un nouvel élément
            var newItem = PeriodicInvestement(name             : "",
                                              note             : "",
                                              type             : .other,
                                              firstYear        : Date.now.year,
                                              lastYear         : Date.now.year + 100,
                                              interestRateType : .contractualRate(fixedRate: 0.0))
            // définir le délégué pour la méthode ageOf qui par défaut est nil à la création de l'objet
            newItem.ownership.setDelegateForAgeOf(delegate: family.ageOf)
            _localItem = State(initialValue: newItem)
            // création d'un nouvel élément
            index = nil
        }
    }
    
    func duplicate() {
        // générer un nouvel identifiant pour la copie
        localItem.id = UUID()
        localItem.name += "-copie"
        // ajouter la copie
        patrimoine.assets.periodicInvests.add(localItem)
        // revenir à l'élement avant duplication
        localItem = originalItem!
    }
    
    // sauvegarder les changements
    func applyChanges() {
        // validation avant sauvegarde
        guard self.isValid() else { return }
        
        if let index = index {
            // modifier un éléménet existant
            patrimoine.assets.periodicInvests.update(with: localItem, at: index)
        } else {
            // générer un nouvel identifiant pour le nouvel item
            localItem.id = UUID()
            // définir le délégué pour la méthode ageOf qui par défaut est nil à la création de l'objet
            localItem.ownership.setDelegateForAgeOf(delegate: family.ageOf)
            // ajouter le nouvel élément à la liste
            patrimoine.assets.periodicInvests.add(localItem)
        }
        
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()
    }
    
    func isValid() -> Bool {
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
    
    func changeOccured() -> Bool {
        return localItem != originalItem
    }
    
    func liquidatedValue() -> Double {
        let liquidationDate = self.localItem.lastYear
        return self.localItem.value(atEndOf: liquidationDate)
    }
    func cumulatedInterests() -> Double {
        let liquidationDate = self.localItem.lastYear
        return self.localItem.cumulatedInterests(atEndOf: liquidationDate)
    }
    func netCmulatedInterests() -> Double {
        let liquidationDate = self.localItem.lastYear
        return self.localItem.liquidatedValue(atEndOf: liquidationDate).netInterests
    }
    func taxableCmulatedInterests() -> Double {
        let liquidationDate = self.localItem.lastYear
        return self.localItem.liquidatedValue(atEndOf: liquidationDate).taxableIrppInterests
    }
    func socialTaxes() -> Double {
        let liquidationDate = self.localItem.lastYear
        return self.localItem.liquidatedValue(atEndOf: liquidationDate).socialTaxes
    }
    func liquidatedValueAfterSocialTaxes() -> Double {
        let liquidationDate = self.localItem.lastYear
        let liquidatedValue = self.localItem.liquidatedValue(atEndOf: liquidationDate)
        return liquidatedValue.revenue - liquidatedValue.socialTaxes
    }
}

struct PeriodicInvestDetailedView_Previews: PreviewProvider {
    static var family     = Family()
    static var patrimoine = Patrimoin()

    static var previews: some View {
        return
            Group {
//                NavigationView() {
                    PeriodicInvestDetailedView(item       : patrimoine.assets.periodicInvests[0],
                                               family     : family,
                                               patrimoine : patrimoine)
                        .environmentObject(patrimoine)
                }
                .previewDisplayName("PeriodicInvestDetailedView")
//            }
    }
}
