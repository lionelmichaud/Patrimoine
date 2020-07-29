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
        // si la table est vide alors quitter
        guard !balanceArray.isEmpty else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        // ligne de titre du tableau: utiliser la première ligne de la table de bilan
        let heading = "YEAR; " + balanceArray.first!.headerCSV
        
        // For every element , extract the values as a comma-separated string.
        let rows = balanceArray.map {
            "\($0.year); \($0.valuesCSV)"
        }
        
        // Turn all of the rows into one big string
        let csvString = heading + rows.joined(separator: "\n")
        
        print(SocialAccounts.balanceSheetFileUrl ?? "nil")
        print(csvString)
        
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
            let personsNames                = firstLine.ages.persons.map(\.name).joined(separator: "; ")
            let revenusWorkIncomeNames      = firstLine.revenues.perCategory[.workIncomes]?.credits.headerCSV
            let revenusFinancialNames       = firstLine.revenues.perCategory[.financials]?.credits.headerCSV
            let revenusScpiNames            = firstLine.revenues.perCategory[.scpis]?.credits.headerCSV
            let revenusrealEstateRentsNames = firstLine.revenues.perCategory[.realEstateRents]?.credits.headerCSV
            let revenusScpiSaleNames        = firstLine.revenues.perCategory[.scpiSale]?.credits.headerCSV
            let revenusRealEstateSaleNames  = firstLine.revenues.perCategory[.realEstateSale]?.credits.headerCSV
            heading = "YEAR; \(personsNames); \(revenusWorkIncomeNames ?? ""); \(revenusFinancialNames ?? ""); \(revenusScpiNames ?? ""); \(revenusrealEstateRentsNames ?? ""); \(revenusScpiSaleNames ?? ""); \(revenusRealEstateSaleNames ?? ""); \(firstLine.revenues.taxableIrppRevenueDelayedFromLastYear.name);"

            // For every element , extract the values as a comma-separated string.
            // - Ages: year, age, age...
            let rowsOfAges = cashFlowArray.map { "\($0.year); \($0.ages.persons.map { (person: (name: String, age: Int)) -> String in String(person.age) }.joined(separator: "; ")); "
            }
            // - Revenues.workIncomes: credits, credits, credits...
            let rowsRevenusWorkIncome      = cashFlowArray.map { "\($0.revenues.perCategory[.workIncomes]?.credits.valuesCSV ?? ""); " }
            let rowsRevenusFinancial       = cashFlowArray.map { "\($0.revenues.perCategory[.financials]?.credits.valuesCSV ?? ""); " }
            let rowsRevenusScpi            = cashFlowArray.map { "\($0.revenues.perCategory[.scpis]?.credits.valuesCSV ?? ""); " }
            let rowsRevenusRealEstateRents = cashFlowArray.map { "\($0.revenues.perCategory[.realEstateRents]?.credits.valuesCSV ?? ""); " }
            let rowsRevenusScpiSale        = cashFlowArray.map { "\($0.revenues.perCategory[.scpiSale]?.credits.valuesCSV ?? ""); " }
            let rowsRevenusRealEstateSale  = cashFlowArray.map { "\($0.revenues.perCategory[.realEstateSale]?.credits.valuesCSV ?? ""); " }
            let rowsRevenusReporte         = cashFlowArray.map { "\($0.revenues.taxableIrppRevenueDelayedFromLastYear.value(atEndOf :0).roundedString); " }
            
            rows = zip(rowsOfAges, rowsRevenusWorkIncome).map(+)
            rows = zip(rows, rowsRevenusFinancial).map(+)
            rows = zip(rows, rowsRevenusScpi).map(+)
            rows = zip(rows, rowsRevenusRealEstateRents).map(+)
            rows = zip(rows, rowsRevenusScpiSale).map(+)
            rows = zip(rows, rowsRevenusRealEstateSale).map(+)
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
            let localTaxesNames  = firstLine.taxes.localTaxes.headerCSV
            let socialTaxesNames = firstLine.taxes.socialTaxes.headerCSV
            heading += "COEF FAMILIAL; IRPP; \(localTaxesNames); \(socialTaxesNames); TAXES TOTALES;"
            
            // For every element , extract the values as a comma-separated string.
            let rowsCoef        = cashFlowArray.map { "\($0.taxes.familyQuotient.roundedString); " }
            let rowsIrpp        = cashFlowArray.map { "\($0.taxes.irpp.roundedString); " }
            let rowsLocalTaxes  = cashFlowArray.map { "\($0.taxes.localTaxes.valuesCSV); " }
            let rowsSocialTaxes = cashFlowArray.map { "\($0.taxes.socialTaxes.valuesCSV); " }
            let rowsTotal       = cashFlowArray.map { "\($0.taxes.total.roundedString); " }
            
            rows = zip(rows, rowsCoef).map(+)
            rows = zip(rows, rowsIrpp).map(+)
            rows = zip(rows, rowsLocalTaxes).map(+)
            rows = zip(rows, rowsSocialTaxes).map(+)
            rows = zip(rows, rowsTotal).map(+)
        }
        
        func buildDebtsTableCSV(firstLine: CashFlowLine) {
            let debtsNames = firstLine.debtPayements.headerCSV
            heading += "\(debtsNames)\n"
            
            // For every element , extract the values as a comma-separated string.
            let rowsDebt = cashFlowArray.map { "\($0.debtPayements.valuesCSV)"
            }
            
            rows = zip(rows, rowsDebt).map(+)
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
        
        // construire la partie Revenus du tableau
        buildRevenusTableCSV(firstLine: firstLine)
        
        // construire la partie SCI du tableau
        buildSciTableCSV(firstLine: firstLine)
        
        // construire la partie Taxes du tableau
        buildTaxesTableCSV(firstLine: firstLine)
        
        // construire la partie Dettes du tableau
        buildDebtsTableCSV(firstLine: firstLine)
        
        // Turn all of the rows into one big string
        let csvString = heading + rows.joined(separator: "\n")
        print(csvString)
        
        #if DEBUG
        // sauvegarder le fichier dans le répertoire Bundle/csv

        do {
            try csvString.write(to: SocialAccounts.cashFlowFileUrl!, atomically: true , encoding: .utf8)
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
