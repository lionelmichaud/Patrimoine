//
//  LoanDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 30/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct LoanDetailedView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    
    var item: Loan?
    // commun
    @EnvironmentObject var patrimoine: Patrimoin
    @Environment(\.presentationMode) var presentationMode
    @State private var alertData: AlertData? = nil
    @State private var index: Int?
    
    // à adapter
    @State private var localItem = Loan(name: "",
                                        firstYear: Date.now.year,
                                        lastYear: Date.now.year,
                                        initialValue: 0,
                                        interestRate: 0,
                                        monthlyInsurance: 0)
    var body: some View {
        Form {
            HStack{
                Text("Nom")
                    .frame(width: 70, alignment: .leading)
                TextField("obligatoire", text: $localItem.name)
            }
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
                LabeledTextView(label: "Durée du prêt",
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
                           amount : localItem.value (atEndOf: Date.now.year))
                    .foregroundColor(.secondary)
                AmountView(label  : "Remboursement total",
                           amount : localItem.totalPayement)
                    .foregroundColor(.secondary)
                AmountView(label  : "Coût total du crédit",
                           amount : localItem.costOfCredit)
                    .foregroundColor(.secondary)
            }
        }
        .alert(item: $alertData) { alertData in
            Alert(title: Text(alertData.title),
                  message: Text(alertData.message))
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        //.onAppear(perform: onAppear)
        .navigationTitle("Emprunt")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button(
                action : duplicate,
                label  : { Text("Dupliquer")} )
                .capsuleButtonStyle()
                .disabled((index == nil) || changeOccured()),
            trailing: Button(
                action: applyChanges,
                label: {
                    Text("Sauver")
                } )
                .disabled(!changeOccured())
        )
    }
    
    init(item: Loan?, patrimoine: Patrimoin) {
        self.item = item
        if let initialItemValue = item {
            // modification d'un élément existant
            _localItem = State(initialValue: initialItemValue)
            _index     = State(initialValue: patrimoine.liabilities.loans.items.firstIndex(of: initialItemValue))
            // specific
        } else {
            index = nil
        }
    }
    
    func duplicate() {
        // générer un nouvel identifiant pour la copie
        localItem.id = UUID()
        localItem.name += "-copie"
        patrimoine.liabilities.loans.add(localItem)
    }
    
    // sauvegarder les changements
    func applyChanges() {
        guard isValid() else {
            return
        }
        if let index = index {
            // modifier un éléménet existant
            patrimoine.liabilities.loans.update(with: localItem, at: index)
        } else {
            // créer un nouvel élément
            patrimoine.liabilities.loans.add(localItem)
        }
        
        // remettre à zéro la simulation et sa vue
        simulation.reset(withPatrimoine: patrimoine)
        uiState.resetSimulation()
        
        self.presentationMode.wrappedValue.dismiss()
    }
    
    func changeOccured() -> Bool {
        return localItem != item
    }
    
    func isValid() -> Bool {
        if localItem.loanedValue > 0 {
            self.alertData = AlertData(title: "Erreur",
                                       message: "Le montant emprunté doit être négatif")
            return false
        } else {
            return true
        }
    }
}

struct LoanDetailedView_Previews: PreviewProvider {
    static var patrimoine  = Patrimoin()
    
    static var previews: some View {
        return
            NavigationView() {
                LoanDetailedView(item: patrimoine.liabilities.loans[0],
                                 patrimoine: patrimoine)
                    .environmentObject(patrimoine)
            }
            .previewDisplayName("LoanDetailedView")
    }
}
