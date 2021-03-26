//
//  LoanDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 30/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct LoanDetailedView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState

    // commun
    private var originalItem     : Loan?
    @State private var alertItem : AlertItem?
    @State private var localItem : Loan
    @State private var index     : Int?
    // à adapter
    
    var body: some View {
        Form {
            LabeledTextField(label: "Nom", defaultText: "obligatoire", text: $localItem.name)
            LabeledTextEditor(label: "Note", text: $localItem.note)
            
            /// propriété
            OwnershipView(ownership  : $localItem.ownership,
                          totalValue : localItem.value(atEndOf : Date.now.year))
            
            // acquisition
            Section(header: Text("CARCTERISTIQUES")) {
                AmountEditView(label  : "Montant emprunté",
                               amount : $localItem.loanedValue)
                YearPicker(title     : "Première année (inclue)",
                           inRange   : Date.now.year - 20 ... min(localItem.lastYear, Date.now.year + 50),
                           selection : $localItem.firstYear)
                YearPicker(title     : "Dernière année (inclue)",
                           inRange   : max(localItem.firstYear, Date.now.year - 20) ... Date.now.year + 50,
                           selection : $localItem.lastYear)
                LabeledText(label: "Durée du prêt",
                                text : "\(localItem.lastYear - localItem.firstYear + 1) ans")
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("CONDITIONS")) {
                PercentEditView(label   : "Taux d'intérêt annuel",
                                percent : $localItem.interestRate)
                AmountEditView(label  : "Montant mensuel de l'assurance",
                               amount : $localItem.monthlyInsurance)
                AmountView(label  : "Remboursement annuel (de janvier \(localItem.firstYear) à décembre \(localItem.lastYear))",
                           amount : localItem.yearlyPayement(localItem.firstYear))
                    .foregroundColor(.secondary)
                AmountView(label  : "Remboursement mensuel (de janvier \(localItem.firstYear) à décembre \(localItem.lastYear))",
                           amount : localItem.yearlyPayement(localItem.firstYear)/12.0)
                    .foregroundColor(.secondary)
                AmountView(label  : "Remboursement restant (au 31/12/\(Date.now.year))",
                           amount : localItem.value(atEndOf: Date.now.year))
                    .foregroundColor(.secondary)
                AmountView(label  : "Remboursement total",
                           amount : localItem.totalPayement)
                    .foregroundColor(.secondary)
                AmountView(label  : "Coût total du crédit",
                           amount : localItem.costOfCredit)
                    .foregroundColor(.secondary)
            }
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        //.onAppear(perform: onAppear)
        .navigationTitle("Emprunt")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button(
                action : duplicate,
                label  : { Text("Dupliquer") })
                .capsuleButtonStyle()
                .disabled((index == nil) || changeOccured()),
            trailing: Button(
                action: applyChanges,
                label: {
                    Text("Sauver")
                })
                .disabled(!changeOccured())
        )
        .alert(item: $alertItem, content: myAlert)
    }
    
    init(item       : Loan?,
         family     : Family,
         patrimoine : Patrimoin) {
        self.originalItem = item
        if let initialItemValue = item {
            // modification d'un élément existant
            _localItem = State(initialValue: initialItemValue)
            _index     = State(initialValue: patrimoine.liabilities.loans.items.firstIndex(of: initialItemValue))
            // specific
        } else {
            // création d'un nouvel élément
            var newItem = Loan(firstYear : Date.now.year,
                               lastYear  : Date.now.year)
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
        // ajouter un élément à la liste
        patrimoine.liabilities.loans.add(localItem)
        // revenir à l'élement avant duplication
        localItem = originalItem!
        
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }
    
    // sauvegarder les changements
    private func applyChanges() {
        guard self.isValid() else { return }

        if let index = index {
            // modifier un éléménet existant
            patrimoine.liabilities.loans.update(with: localItem, at: index)
        } else {
            // générer un nouvel identifiant pour le nouvel item
            localItem.id = UUID()
            // définir le délégué pour la méthode ageOf qui par défaut est nil à la création de l'objet
            localItem.ownership.setDelegateForAgeOf(delegate: family.ageOf)
            // ajouter le nouvel élément à la liste
            patrimoine.liabilities.loans.add(localItem)
        }
        
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }
    
    private func changeOccured() -> Bool {
        return localItem != originalItem
    }
    
    private func isValid() -> Bool {
        if localItem.loanedValue > 0 {
            self.alertItem = AlertItem(title         : Text("Erreur"),
                                       message       : Text("Le montant emprunté doit être négatif"),
                                       dismissButton : .default(Text("OK")))
            return false
        }
        
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
}

struct LoanDetailedView_Previews: PreviewProvider {
    static var family     = Family()
    static var patrimoine = Patrimoin()
    
    static var previews: some View {
        return
            NavigationView {
                LoanDetailedView(item       : patrimoine.liabilities.loans[0],
                                 family     : family,
                                 patrimoine : patrimoine)
                    .environmentObject(family)
                    .environmentObject(patrimoine)
            }
            .previewDisplayName("LoanDetailedView")
    }
}
