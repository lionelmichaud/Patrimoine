//
//  SCPIDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct SCPIDetailedView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    
    // commun
    private var originalItem      : SCPI?
    @State private var localItem  : SCPI
    @State private var alertItem  : AlertItem?
    @State private var index      : Int?
    // à adapter
    var updateItem : (_ item: SCPI, _ index: Int) -> Void
    var addItem    : (_ item: SCPI) -> Void

    var body: some View {
        Form {
            LabeledTextField(label: "Nom", defaultText: "obligatoire", text: $localItem.name)
            LabeledTextEditor(label: "Note", text: $localItem.note)
            
            /// acquisition
            Section(header: Text("ACQUISITION")) {
                DatePicker(selection: $localItem.buyingDate,
                           displayedComponents: .date,
                           label: { Text("Date d'acquisition") })
                AmountEditView(label: "Prix d'acquisition",
                               amount: $localItem.buyingPrice)
            }

            /// propriété
            OwnershipView(ownership  : $localItem.ownership,
                          totalValue : localItem.value(atEndOf : Date.now.year))
            
            /// rendement
            Section(header: Text("RENDEMENT")) {
                PercentEditView(label: "Taux de rendement annuel brut",
                                percent: $localItem.interestRate)
                AmountView(label: "Revenu annuel brut (avant prélèvements sociaux et IRPP)",
                           amount: localItem.yearlyRevenue(during: Date.now.year).revenue)
                    .foregroundColor(.secondary)
                AmountView(label: "Charges sociales",
                           amount: localItem.yearlyRevenue(during: Date.now.year).socialTaxes)
                    .foregroundColor(.secondary)
                AmountView(label: "Revenu annuel net de charges sociales (remboursable par une SCI)",
                           amount: localItem.yearlyRevenue(during: Date.now.year).taxableIrpp)
                    .foregroundColor(.secondary)
                PercentEditView(label: "Taux de réévaluation annuel",
                                percent: $localItem.revaluatRate)
            }
            
            /// vente
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
        .navigationTitle("SCPI")
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
    
    init(item       : SCPI?,
         updateItem : @escaping (SCPI, Int) -> Void,
         addItem    : @escaping (SCPI) -> Void,
         family     : Family,
         firstIndex : (SCPI) -> Int?) {
        // store closure to differentiate between SCPI and SCI.SCPI
        self.updateItem = updateItem
        self.addItem    = addItem
        
        self.originalItem = item
        if let initialItemValue = item {
            // modification d'un élément existant
            _localItem = State(initialValue: initialItemValue)
            _index     = State(initialValue: firstIndex(initialItemValue))
            // specific
        } else {
            // création d'un nouvel élément
            var newItem = SCPI(name: "", buyingDate: Date.now)
            // définir le délégué pour la méthode ageOf qui par défaut est nil à la création de l'objet
            newItem.ownership.setDelegateForAgeOf(delegate: family.ageOf)
            _localItem = State(initialValue: newItem)
            index = nil
        }
    }
    
    func duplicate() {
        // générer un nouvel identifiant pour la copie
        localItem.id = UUID()
        localItem.name += "-copie"
        // ajouter un élément à la liste
        addItem(localItem)
        // revenir à l'élement avant duplication
        localItem = originalItem!
    }
    
    // sauvegarder les changements
    func applyChanges() {
        // validation avant sauvegarde
        guard self.isValid() else { return }
        
        if let index = index {
            // modifier un éléménet existant
            updateItem(localItem, index)
        } else {
            // générer un nouvel identifiant pour le nouvel item
            localItem.id = UUID()
            // définir le délégué pour la méthode ageOf qui par défaut est nil à la création de l'objet
            localItem.ownership.setDelegateForAgeOf(delegate: family.ageOf)
            // ajouter le nouvel élément à la liste
            addItem(localItem)
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
        
        return true
    }

    func changeOccured() -> Bool {
        return localItem != originalItem
    }
}

struct SCPIDetailedView_Previews: PreviewProvider {
    static var family     = Family()
    static var patrimoine = Patrimoin()
    
    static var previews: some View {
        return
            Group {
                NavigationView {
                    SCPIDetailedView(item       : patrimoine.assets.scpis[0],
                                     //patrimoine     : patrimoine,
                                     updateItem : { (localItem, index) in patrimoine.assets.scpis.update(with: localItem, at: index) },
                                     addItem    : { (localItem) in patrimoine.assets.scpis.add(localItem) },
                                     family     : family,
                                     firstIndex : { (localItem) in patrimoine.assets.scpis.items.firstIndex(of: localItem) })
                        .environmentObject(family)
                        .environmentObject(patrimoine)
                }
                .previewDisplayName("SCPIDetailedView")
            }
    }
}
