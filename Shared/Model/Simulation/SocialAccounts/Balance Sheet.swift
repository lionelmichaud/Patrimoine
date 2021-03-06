import Foundation
import Disk

// MARK: - Table des Bilans annuels

typealias BalanceSheetArray = [BalanceSheetLine]

extension BalanceSheetArray {
    func storeTableCSV(simulationTitle: String,
                       withMode mode  : SimulationModeEnum) {
        var heading = String()
        var rows    = [String]()
        
        func buildAssetsTableCSV(firstLine: BalanceSheetLine) {
            // pour chaque catégorie
            AssetsCategory.allCases.forEach { category in
                // heading
                heading += firstLine.assets.headersCSV(category)! + "; "
                // valeurs
                // values: For every element , extract the values as a comma-separated string.
                rows = zip(rows, self.map { "\($0.assets.valuesCSV(category)!); " }).map(+)
            }
            // total
            // heading
            heading += "ACTIF TOTAL; "
            // valeurs
            let rowsTotal = self.map { "\($0.assets.total.roundedString); " }
            rows = zip(rows, rowsTotal).map(+)
        }
        
        func buildLiabilitiesTableCSV(firstline: BalanceSheetLine) {
            // pour chaque catégorie
            LiabilitiesCategory.allCases.forEach { category in
                // heading
                heading += firstLine.liabilities.headersCSV(category)! + "; "
                // valeurs
                // values: For every element , extract the values as a comma-separated string.
                rows = zip(rows, self.map { "\($0.liabilities.valuesCSV(category)!); " }).map(+)
            }
            // total
            // heading
            heading += "PASSIF TOTAL; "
            // valeurs
            let rowsTotal = self.map { "\($0.liabilities.total.roundedString); " }
            rows = zip(rows, rowsTotal).map(+)
        }
        
        func buildNetTableCSV(firstline: BalanceSheetLine) {
            // heading
            heading += "ACTIF NET"
            // valeurs
            let rowsTotal = self.map { "\($0.netAssets.roundedString)" }
            rows = zip(rows, rowsTotal).map(+)
        }
        
        // si la table est vide alors quitter
        guard !self.isEmpty else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        
        let firstLine = self.first!
        
        // ligne de titre du tableau: utiliser la première ligne de la table de bilan
        heading = "YEAR; " // + self.first!.headerCSV
        rows = self.map { "\($0.year); " }

        // inflation
        // heading
        heading += "Inflation; "
        // valeurs
        let rowsInflationRate = self.map { _ in "\(Economy.model.randomizers.inflation.value(withMode: mode).percentString(digit: 1)); " }
        rows = zip(rows, rowsInflationRate).map(+)
        
        // taux des obligations
        // heading
        heading += "Taux Oblig; "
        // valeurs
        let rowsSecuredRate = self.map { "\(Economy.model.rates(in: $0.year, withMode: mode).securedRate.percentString(digit: 1)); " }
        rows = zip(rows, rowsSecuredRate).map(+)
        
        // taux des actions
        // heading
        heading += "Taux Action; "
        // valeurs
        let rowsStockRate = self.map { "\(Economy.model.rates(in: $0.year, withMode: mode).stockRate.percentString(digit: 1)); " }
        rows = zip(rows, rowsStockRate).map(+)
        
       // construire la partie Actifs du tableau
        buildAssetsTableCSV(firstLine: firstLine)
        
        // construire la partie Passifs du tableau
        buildLiabilitiesTableCSV(firstline: firstLine)
        
        // ajoute le total Actif Net au bout
        buildNetTableCSV(firstline: firstLine)
        
        // Turn all of the rows into one big string
        let csvString = heading + "\n" + rows.joined(separator: "\n")
        
        //        print(SocialAccounts.balanceSheetFileUrl ?? "nil")
        //        print(csvString)
        
        #if DEBUG
        // sauvegarder le fichier dans le répertoire Bundle/csv
        do {
            try csvString.write(to: SocialAccounts.balanceSheetFileUrl!, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file: \(error)")
        }
        #endif
        
        // sauvegarder le fichier dans le répertoire Data/Documents/csv
        let fileName = "BalanceSheet.csv"
        do {
            try Disk.save(Data(csvString.utf8),
                          to: .documents,
                          as: AppSettings.csvPath(simulationTitle) + fileName)
            #if DEBUG
            Swift.print("saving 'BalanceSheet.csv' to file: ", AppSettings.csvPath(simulationTitle) + fileName)
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

// MARK: - Ligne de Bilan annuel

struct BalanceSheetLine {
    
    // MARK: - Properties
    
    // année de début de la simulation
    var year: Int   = 0
    // actifs
    var assets      = ValuedAssets(name: "ACTIF")
    // passifs
    var liabilities = ValuedLiabilities(name: "PASSIF")
    // net
    var netAssets   : Double {
        assets.total + liabilities.total
    }
    // tous les actifs net sauf immobilier physique
    var netFinancialAssets : Double {
        netAssets - assets.perCategory[.realEstates]?.total ?? 0.0
    }
    // tous les actifs sauf immobilier physique
    var financialAssets: Double {
        assets.total - assets.perCategory[.realEstates]?.total ?? 0.0
    }
    
    // MARK: - Initializers
    
    init(withYear year             : Int,
         withPatrimoine patrimoine : Patrimoin) {
//        autoreleasepool {
        self.year = year
        
        // actifs
        for asset in patrimoine.assets.realEstates.items.sorted(by:<) {
            // populate real estate assets
            appendToAssets(.realEstates, asset, year)
        }
        for asset in patrimoine.assets.periodicInvests.items.sorted(by:<) {
            // populate periodic investments assets
            appendToAssets(.periodicInvests, asset, year)
        }
        for asset in patrimoine.assets.freeInvests.items.sorted(by:<) {
            // populate free investment assets
            appendToAssets(.freeInvests, asset, year)
        }
        for asset in patrimoine.assets.scpis.items.sorted(by:<) {
            // populate SCPI assets
            appendToAssets(.scpis, asset, year)
        }
        
        // actifs SCI - SCPI
        for asset in patrimoine.assets.sci.scpis.items.sorted(by:<) {
            // populate SCI assets
            appendToAssets(.sci, asset, year, "SCI - ")
        }
        
        // dettes
        for liability in patrimoine.liabilities.debts.items.sorted(by:<) {
            // populate debt liabilities
            appendToLiabilities(.debts, liability, year)
        }
        // emprunts
        for liability in patrimoine.liabilities.loans.items.sorted(by:<) {
            // populate loan liabilities
            appendToLiabilities(.loans, liability, year)
        }
//        }
    }
    
    // MARK: - Methods
    
    fileprivate mutating func appendToAssets(_ category       : AssetsCategory,
                                             _ asset          : NameableValuable,
                                             _ year           : Int,
                                             _ withNamePrefix : String = "") {
        assets.perCategory[category]?.namedValues.append(
            (name  : withNamePrefix + asset.name,
             value : asset.value(atEndOf: year).rounded()))
    }
    
    fileprivate mutating func appendToLiabilities(_ category       : LiabilitiesCategory,
                                                  _ liability      : NameableValuable,
                                                  _ year           : Int,
                                                  _ withNamePrefix : String = "") {
        liabilities.perCategory[category]?.namedValues.append(
            (name  : withNamePrefix + liability.name,
             value : liability.value(atEndOf: year).rounded()))
    }
    
    func print() {
        Swift.print("YEAR:", year)
        // actifs
        assets.print(level: 1)
        // passifs
        liabilities.print(level: 1)
        // net
        Swift.print("Net: \(netAssets)")
        Swift.print("-----------------------------------------")
    }
    
}
