//
//  BalanceSheet+CSV.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 11/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Disk

// MARK: - Impression dans un fichier CSV
extension SocialAccounts {
    
    func storeBalanceSheetTableCSV(simulationTitle: String) {
        var heading = String()
        var rows    = [String]()
        
        func buildAssetsTableCSV(firstLine: BalanceSheetLine) {
            // pour chaque catégorie
            AssetsCategory.allCases.forEach { category in
                // heading
                heading += firstLine.assets.headersCSV(category)! + "; "
                // valeurs
                // values: For every element , extract the values as a comma-separated string.
                rows = zip(rows, balanceArray.map { "\($0.assets.valuesCSV(category)!); " }).map(+)
            }
            // total
            // heading
            heading += "ACTIF TOTAL; "
            // valeurs
            let rowsTotal = balanceArray.map { "\($0.assets.total.roundedString); " }
            rows = zip(rows, rowsTotal).map(+)
        }
        
        func buildLiabilitiesTableCSV(firstline: BalanceSheetLine) {
            // pour chaque catégorie
            LiabilitiesCategory.allCases.forEach { category in
                // heading
                heading += firstLine.liabilities.headersCSV(category)! + "; "
                // valeurs
                // values: For every element , extract the values as a comma-separated string.
                rows = zip(rows, balanceArray.map { "\($0.liabilities.valuesCSV(category)!); " }).map(+)
            }
            // total
            // heading
            heading += "PASSIF TOTAL; "
            // valeurs
            let rowsTotal = balanceArray.map { "\($0.liabilities.total.roundedString); " }
            rows = zip(rows, rowsTotal).map(+)
        }
        
        func builNetTableCSV(firstline: BalanceSheetLine) {
            // heading
            heading += "ACTIF NET"
            // valeurs
            let rowsTotal = balanceArray.map { "\($0.net.roundedString)" }
            rows = zip(rows, rowsTotal).map(+)
        }
        
        // si la table est vide alors quitter
        guard !balanceArray.isEmpty else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        
        let firstLine = balanceArray.first!
        
        // ligne de titre du tableau: utiliser la première ligne de la table de bilan
        heading = "YEAR; " // + balanceArray.first!.headerCSV
        rows = balanceArray.map { "\($0.year); " }
        
        // construire la partie Actifs du tableau
        buildAssetsTableCSV(firstLine: firstLine)
        
        // construire la partie Passifs du tableau
        buildLiabilitiesTableCSV(firstline: firstLine)
        
        // ajoute le total Actif Net au bout
        builNetTableCSV(firstline: firstLine)
        
        // Turn all of the rows into one big string
        let csvString = heading + "\n" + rows.joined(separator: "\n")
        
        //        print(SocialAccounts.balanceSheetFileUrl ?? "nil")
        //        print(csvString)
        
        #if DEBUG
        // sauvegarder le fichier dans le répertoire Bundle/csv
        do {
            try csvString.write(to: SocialAccounts.balanceSheetFileUrl!, atomically: true , encoding: .utf8)
        }
        catch {
            print("error creating file: \(error)")
        }
        #endif
        
        // sauvegarder le fichier dans le répertoire Data/Documents/csv
        let fileName = "BalanceSheet.csv"
        do {
            try Disk.save(Data(csvString.utf8),
                          to: .documents,
                          as: Config.csvPath(simulationTitle) + fileName)
            #if DEBUG
            Swift.print("saving 'BalanceSheet.csv' to file: ", Config.csvPath(simulationTitle) + fileName)
            #endif
            
        }
        catch let error as NSError {
            fatalError("""
                Domain         : \(error.domain)
                Code           : \(error.code)
                Description    : \(error.localizedDescription)
                Failure Reason : \(error.localizedFailureReason ?? "")
                Suggestions    : \(error.localizedRecoverySuggestion ?? "")
                """)
        }
    }
    
    func storeCashFlowTableCSV(simulationTitle: String) {
        var heading = String()
        var rows    = [String]()
        
        func buildRevenusTableCSV(firstLine: CashFlowLine) {
            // pour chaque catégorie
            RevenueCategory.allCases.forEach { category in
                // heading
                heading += firstLine.revenues.headersCSV(category)! + "; "
                // valeurs
                // values: For every element , extract the values as a comma-separated string.
                rows = zip(rows, cashFlowArray.map { "\($0.revenues.valuesCSV(category)!); " }).map(+)
            }
            // total
            // heading
            heading += "REVENU PERCU TOTAL; "
            // valeurs
            let rowsTotal = cashFlowArray.map { "\($0.revenues.totalCredited.roundedString); " }
            rows = zip(rows, rowsTotal).map(+)
                        
            heading += "\(firstLine.revenues.taxableIrppRevenueDelayedFromLastYear.name);"
            let rowsRevenusReporte = cashFlowArray.map { "\($0.revenues.taxableIrppRevenueDelayedFromLastYear.value(atEndOf :0).roundedString); " }
            rows = zip(rows, rowsRevenusReporte).map(+)
        }
        
        func buildSciTableCSV(firstLine: CashFlowLine) {
            let sciDividendsNames = firstLine.sciCashFlowLine.revenues.sciDividends.headerCSV
            let sciSalesNames = firstLine.sciCashFlowLine.revenues.scpiSale.headerCSV
            heading += "\(sciDividendsNames); \(sciSalesNames); IS; REMB. SCI;"
            
            // For every element , extract the values as a comma-separated string.
            let rowsSciDividends   = cashFlowArray.map { "\($0.sciCashFlowLine.revenues.sciDividends.valuesCSV); " }
            let rowsSciSales       = cashFlowArray.map { "\($0.sciCashFlowLine.revenues.scpiSale.valuesCSV); " }
            let rowsSciIS          = cashFlowArray.map { "\((-$0.sciCashFlowLine.IS).roundedString); " }
            let rowsSciNetCashFlow = cashFlowArray.map { "\($0.sciCashFlowLine.netCashFlow.roundedString); " }
            
            rows = zip(rows, rowsSciDividends).map(+)
            rows = zip(rows, rowsSciSales).map(+)
            rows = zip(rows, rowsSciIS).map(+)
            rows = zip(rows, rowsSciNetCashFlow).map(+)
        }
        
        func buildTaxesTableCSV(firstLine: CashFlowLine) {
            heading += "QUOT FAMILIAL; "
            TaxeCategory.allCases.forEach { category in
                heading += firstLine.taxes.perCategory[category]!.headerCSV + "; "
            }
            heading += "TAXES TOTALES; "
            
            // For every element , extract the values as a comma-separated string.
            let rowsCoef = cashFlowArray.map { "\($0.taxes.familyQuotient.roundedString); " }
            rows = zip(rows, rowsCoef).map(+)
            
            TaxeCategory.allCases.forEach { category in
                rows = zip(rows, cashFlowArray.map { "\($0.taxes.perCategory[category]!.valuesCSV); " }).map(+)
            }
            let rowsTotal = cashFlowArray.map { "\($0.taxes.total.roundedString); " }
            rows = zip(rows, rowsTotal).map(+)
        }
        
        func buildLifeExpensesTableCSV(firstLine: CashFlowLine) {
            let expensesNames = firstLine.lifeExpenses.namedValueTable.headerCSV
            heading += "\(expensesNames); TOTAL DEPENSES \n"
            
            // For every element , extract the values as a comma-separated string.
            let rowsExpenses = cashFlowArray.map { "\($0.lifeExpenses.namedValueTable.valuesCSV)" }
            rows = zip(rows, rowsExpenses).map(+)
            
            let rowsTotal = cashFlowArray.map { "\($0.lifeExpenses.namedValueTable.total.roundedString); " }
            rows = zip(rows, rowsTotal).map(+)
        }
        
        func buildDebtsTableCSV(firstLine: CashFlowLine) {
            let debtsNames = firstLine.debtPayements.namedValueTable.headerCSV
            heading += "\(debtsNames); TOTAL LOAN \n"
            
            // For every element , extract the values as a comma-separated string.
            let rowsDebt = cashFlowArray.map { "\($0.debtPayements.namedValueTable.valuesCSV)" }
            rows = zip(rows, rowsDebt).map(+)
            
            let rowsTotal = cashFlowArray.map { "\($0.debtPayements.namedValueTable.total.roundedString); " }
            rows = zip(rows, rowsTotal).map(+)
        }
        
        func buildInvestsTableCSV(firstLine: CashFlowLine) {
            let investsNames = firstLine.investPayements.namedValueTable.headerCSV
            heading += "\(investsNames); TOTAL INVEST \n"
            
            // For every element , extract the values as a comma-separated string.
            let rowsInvest = cashFlowArray.map { "\($0.investPayements.namedValueTable.valuesCSV)" }
            rows = zip(rows, rowsInvest).map(+)
            
            let rowsTotal = cashFlowArray.map { "\($0.investPayements.namedValueTable.total.roundedString); " }
            rows = zip(rows, rowsTotal).map(+)
        }
        
        // si la table est vide alors quitter
        guard !cashFlowArray.isEmpty else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        
        // ligne de titre du tableau: utiliser la première ligne de la table de bilan
        let firstLine = cashFlowArray.first!
        
        // Année et Ages
        let personsNames = firstLine.ages.persons.map( { "Age " + $0.name } ).joined(separator: "; ")
        heading = "YEAR; \(personsNames);"
        rows = cashFlowArray.map {
            "\($0.year); \($0.ages.persons.map( { String($0.age) } ).joined(separator: "; ")); "
        }
        
        // construire la partie Revenus du tableau
        buildRevenusTableCSV(firstLine: firstLine)
        
        // construire la partie SCI du tableau
                buildSciTableCSV(firstLine: firstLine)
        
        // construire la partie Dépenses de vie du tableau
        //        buildLifeExpensesTableCSV(firstLine: firstLine)
        
        // construire la partie Taxes du tableau
        //        buildTaxesTableCSV(firstLine: firstLine)
        
        // construire la partie Dettes du tableau
        //        buildDebtsTableCSV(firstLine: firstLine)
        
        // construire la partie Investissements du tableau
        //        buildInvestsTableCSV(firstLine: firstLine)
        
        // Turn all of the rows into one big string
        let csvString = heading + "\n" + rows.joined(separator: "\n")
        //        print(csvString)
        
        #if DEBUG
        // sauvegarder le fichier dans le répertoire Bundle/csv
        do {
            try csvString.write(to: SocialAccounts.cashFlowFileUrl!,
                                atomically: true ,
                                encoding: .utf8)
        }
        catch {
            print("error creating file: \(error)")
        }
        #endif
        
        // sauvegarder le fichier dans le répertoire documents/csv
        let fileName = "CashFlow.csv"
        do {
            try Disk.save(Data(csvString.utf8),
                          to: .documents,
                          as: Config.csvPath(simulationTitle) + fileName)
            #if DEBUG
            Swift.print("saving 'CashFlow.csv' to file: ", Config.csvPath(simulationTitle) + fileName)
            #endif
        }
        catch let error as NSError {
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
