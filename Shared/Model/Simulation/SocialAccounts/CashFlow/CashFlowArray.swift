//
//  CashFlowArray.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Disk

// MARK: - Table des cash flow annuels

typealias CashFlowArray = [CashFlowLine]

extension CashFlowArray {
    /// Rend la ligne de Cash Flow pour une année donnée
    /// - Parameter year: l'année recherchée
    /// - Returns: le cash flow de l'année
    subscript(year: Int) -> CashFlowLine? {
        self.first { line in
            line.year == year
        }
    }
    
    /// Sauvegarder dans un fichier au format Excel CSV
    /// - Parameter simulationTitle: titre de la simulation à utiliser dans le nom du fichier CSV créé
    func storeTableCSV(simulationTitle: String) {
        var heading = String()
        var rows    = [String]()
        
        func buildRevenusTableCSV(firstLine: CashFlowLine) {
            // pour chaque catégorie
            RevenueCategory.allCases.forEach { category in
                // heading
                heading += firstLine.revenues.headersCSV(category)! + "; "
                // valeurs
                // values: For every element , extract the values as a comma-separated string.
                rows = zip(rows, self.map { "\($0.revenues.valuesCSV(category)!); " }).map(+)
            }
            // total
            // heading
            heading += "REVENU PERCU TOTAL; "
            // valeurs
            let rowsTotal = self.map { "\($0.revenues.totalRevenue.roundedString); " }
            rows = zip(rows, rowsTotal).map(+)
            
            heading += "\(firstLine.revenues.taxableIrppRevenueDelayedFromLastYear.name);"
            let rowsRevenusReporte = self.map { "\($0.revenues.taxableIrppRevenueDelayedFromLastYear.value(atEndOf :0).roundedString); " }
            rows = zip(rows, rowsRevenusReporte).map(+)
        }
        
        func buildSciTableCSV(firstLine: CashFlowLine) {
            let sciDividendsNames = firstLine.sciCashFlowLine.revenues.sciDividends.headerCSV
            let sciSalesNames = firstLine.sciCashFlowLine.revenues.scpiSale.headerCSV
            heading += "\(sciDividendsNames); \(sciSalesNames); IS; REMB. SCI;"
            
            // For every element , extract the values as a comma-separated string.
            let rowsSciDividends   = self.map { "\($0.sciCashFlowLine.revenues.sciDividends.valuesCSV); " }
            let rowsSciSales       = self.map { "\($0.sciCashFlowLine.revenues.scpiSale.valuesCSV); " }
            let rowsSciIS          = self.map { "\((-$0.sciCashFlowLine.IS).roundedString); " }
            let rowsSciNetCashFlow = self.map { "\($0.sciCashFlowLine.netRevenues.roundedString); " }
            
            rows = zip(rows, rowsSciDividends).map(+)
            rows = zip(rows, rowsSciSales).map(+)
            rows = zip(rows, rowsSciIS).map(+)
            rows = zip(rows, rowsSciNetCashFlow).map(+)
        }
        
        func buildLifeExpensesTableCSV(firstLine: CashFlowLine) {
            let expensesNames = firstLine.lifeExpenses.headerCSV
            heading += "\(expensesNames); "
            
            // For every element , extract the values as a comma-separated string.
            let rowsExpenses = self.map { "\($0.lifeExpenses.valuesCSV); " }
            rows = zip(rows, rowsExpenses).map(+)
        }
        
        func buildTaxesTableCSV(firstLine: CashFlowLine) {
            heading += "QUOT FAMILIAL; "
            TaxeCategory.allCases.forEach { category in
                heading += firstLine.taxes.perCategory[category]!.headerCSV + "; "
            }
            let rowsCoef = self.map { "\($0.taxes.irpp.familyQuotient.roundedString); " }
            rows = zip(rows, rowsCoef).map(+)
            
            heading += "IMPOTS & TAXES TOTALES; "
            // For every element , extract the values as a comma-separated string.
            TaxeCategory.allCases.forEach { category in
                rows = zip(rows, self.map { "\($0.taxes.perCategory[category]!.valuesCSV); " }).map(+)
            }
            let rowsTotal = self.map { "\($0.taxes.total.roundedString); " }
            rows = zip(rows, rowsTotal).map(+)
        }
        
        func buildDebtsTableCSV(firstLine: CashFlowLine) {
            let debtsNames = firstLine.debtPayements.headerCSV
            heading += "\(debtsNames); "
            
            // For every element , extract the values as a comma-separated string.
            let rowsDebt = self.map { "\($0.debtPayements.valuesCSV); " }
            rows = zip(rows, rowsDebt).map(+)
        }
        
        func buildInvestsTableCSV(firstLine: CashFlowLine) {
            let investsNames = firstLine.investPayements.headerCSV
            heading += "\(investsNames); "
            
            // For every element , extract the values as a comma-separated string.
            let rowsInvest = self.map { "\($0.investPayements.valuesCSV); " }
            rows = zip(rows, rowsInvest).map(+)
        }
        
        // si la table est vide alors quitter
        guard !self.isEmpty else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        
        // ligne de titre du tableau: utiliser la première ligne de la table de bilan
        let firstLine = self.first!
        
        // Année et Ages
        let personsNames = firstLine.ages.persons
            .map( { "Age " + $0.name })
            .joined(separator: "; ")
        heading = "YEAR; \(personsNames);"
        rows = self.map {
            "\($0.year); \($0.ages.persons.map({ String($0.age) }).joined(separator: "; ")); "
        }
        
        // construire la partie Revenus du tableau
        buildRevenusTableCSV(firstLine: firstLine)
        
        // construire la partie SCI du tableau
        buildSciTableCSV(firstLine: firstLine)
        
        // somme des rentrées de trésorerie
        heading += "RENTREES TOTAL; "
        rows = zip(rows, self.map { "\($0.sumOfRevenues.roundedString); " }).map(+)
        
        // construire la partie Dépenses de vie du tableau
        buildLifeExpensesTableCSV(firstLine: firstLine)
        
        // construire la partie Taxes du tableau
        buildTaxesTableCSV(firstLine: firstLine)
        
        // construire la partie Dettes du tableau
        buildDebtsTableCSV(firstLine: firstLine)
        
        // construire la partie Investissements du tableau
        buildInvestsTableCSV(firstLine: firstLine)
        
        // somme des sorties de trésoreries
        heading += "SORTIES TOTAL; "
        rows = zip(rows, self.map { "\($0.sumOfExpenses.roundedString); " }).map(+)
        
        // Net cashflow
        heading += "NET CASHFLOW"
        rows = zip(rows, self.map { "\($0.netCashFlow.roundedString)" }).map(+)
        
        // Turn all of the rows into one big string
        let csvString = heading + "\n" + rows.joined(separator: "\n")
        //        print(csvString)
        
        #if DEBUG
        // sauvegarder le fichier dans le répertoire Bundle/csv
        do {
            try csvString.write(to: SocialAccounts.cashFlowFileUrl!,
                                atomically: true ,
                                encoding: .utf8)
        } catch {
            print("error creating file: \(error)")
        }
        #endif
        
        // sauvegarder le fichier dans le répertoire documents/csv
        let fileName = "CashFlow.csv"
        do {
            try Disk.save(Data(csvString.utf8),
                          to: .documents,
                          as: AppSettings.csvPath(simulationTitle) + fileName)
            #if DEBUG
            Swift.print("saving 'CashFlow.csv' to file: ", AppSettings.csvPath(simulationTitle) + fileName)
            #endif
        } catch let error as NSError {
            fatalError("""
                Domain         : \(error.domain)
                Code           : \(error.code)
                Description    : \(error.localizedDescription)
                Failure Reason : \(error.localizedFailureReason ?? "")
                Suggestions    : \(error.localizedRecoverySuggestion ?? "")
                """)
        }
    }
}
