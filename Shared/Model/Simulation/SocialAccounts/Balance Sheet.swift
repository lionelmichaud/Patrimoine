import Foundation
import Disk

// MARK: - BalanceSheetArray: Table des Bilans annuels

typealias BalanceSheetArray = [BalanceSheetLine]

// MARK: - BalanceSheetArray extension for CSV export

extension BalanceSheetArray {
    func storeTableCSV(simulationTitle: String,
                       withMode mode  : SimulationModeEnum) {
        var heading = String()
        var rows    = [String]()
        
        func buildAssetsTableCSV(firstLine: BalanceSheetLine) {
            // pour chaque catégorie
            AssetsCategory.allCases.forEach { category in
                // heading
                heading += firstLine.assets[AppSettings.shared.allPersonsLabel]!.headersCSV(category)! + "; "
                // valeurs
                // values: For every element , extract the values as a comma-separated string.
                rows = zip(rows,
                           self.map { "\($0.assets[AppSettings.shared.allPersonsLabel]!.valuesCSV(category)!); " })
                    .map(+)
            }
            // total
            // heading
            heading += "ACTIF TOTAL; "
            // valeurs
            let rowsTotal = self.map { "\($0.assets[AppSettings.shared.allPersonsLabel]!.total.roundedString); " }
            rows = zip(rows, rowsTotal).map(+)
        }
        
        func buildLiabilitiesTableCSV(firstline: BalanceSheetLine) {
            // pour chaque catégorie
            LiabilitiesCategory.allCases.forEach { category in
                // heading
                heading += firstLine.liabilities[AppSettings.shared.allPersonsLabel]!.headersCSV(category)! + "; "
                // valeurs
                // values: For every element , extract the values as a comma-separated string.
                rows = zip(rows,
                           self.map { "\($0.liabilities[AppSettings.shared.allPersonsLabel]!.valuesCSV(category)!); " })
                    .map(+)
            }
            // total
            // heading
            heading += "PASSIF TOTAL; "
            // valeurs
            let rowsTotal = self.map { "\($0.liabilities[AppSettings.shared.allPersonsLabel]!.total.roundedString); " }
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
    var assets      : [String : ValuedAssets]
    // passifs
    var liabilities : [String : ValuedLiabilities]
    // net
    var netAssets   : Double {
        assets[AppSettings.shared.allPersonsLabel]!.total
            + liabilities[AppSettings.shared.allPersonsLabel]!.total
    }
    // tous les actifs net sauf immobilier physique
    var netFinancialAssets : Double {
        netAssets
            - assets[AppSettings.shared.allPersonsLabel]!.perCategory[.realEstates]?.total ?? 0.0
    }
    // tous les actifs sauf immobilier physique
    var financialAssets: Double {
        assets[AppSettings.shared.allPersonsLabel]!.total
            - assets[AppSettings.shared.allPersonsLabel]!.perCategory[.realEstates]?.total ?? 0.0
    }
    
    // MARK: - Initializers
    
    init(withYear year             : Int,
         withFamily family         : Family,
         withPatrimoine patrimoine : Patrimoin) {
//        autoreleasepool {
        self.year        = year
        
        // initialiser les dictionnaires
        self.assets      = [AppSettings.shared.allPersonsLabel: ValuedAssets(name: "ACTIF")]
        self.liabilities = [AppSettings.shared.allPersonsLabel: ValuedLiabilities(name : "PASSIF")]
        family.members.forEach { person in
            self.assets[person.displayName]      = ValuedAssets(name : "ACTIF")
            self.liabilities[person.displayName] = ValuedLiabilities(name : "PASSIF")
        }

        // actifs
        for asset in patrimoine.assets.realEstates.items.sorted(by:<) {
            // populate real estate assets
            appendToAssets(.realEstates, family, asset, year)
        }
        for asset in patrimoine.assets.periodicInvests.items.sorted(by:<) {
            // populate periodic investments assets
            appendToAssets(.periodicInvests, family, asset, year)
        }
        for asset in patrimoine.assets.freeInvests.items.sorted(by:<) {
            // populate free investment assets
            appendToAssets(.freeInvests, family, asset, year)
        }
        for asset in patrimoine.assets.scpis.items.sorted(by:<) {
            // populate SCPI assets
            appendToAssets(.scpis, family, asset, year)
        }
        
        // actifs SCI - SCPI
        for asset in patrimoine.assets.sci.scpis.items.sorted(by:<) {
            // populate SCI assets
            appendToAssets(.sci, family, asset, year, "SCI - ")
        }
        
        // dettes
        for liability in patrimoine.liabilities.debts.items.sorted(by:<) {
            // populate debt liabilities
            appendToLiabilities(.debts, family, liability, year)
        }
        // emprunts
        for liability in patrimoine.liabilities.loans.items.sorted(by:<) {
            // populate loan liabilities
            appendToLiabilities(.loans, family, liability, year)
        }
//        }
    }
    
    // MARK: - Methods
    
    fileprivate mutating func appendToAssets(_ category       : AssetsCategory,
                                             _ family         : Family,
                                             _ asset          : Ownable,
                                             _ year           : Int,
                                             _ withNamePrefix : String = "") {
        assets[AppSettings.shared.allPersonsLabel]!.perCategory[category]?.namedValues.append(
            (name  : withNamePrefix + asset.name,
             value : asset.value(atEndOf: year).rounded()))
        
        family.members.forEach { person in
            assets[person.displayName]!.perCategory[category]?.namedValues.append(
                (name  : withNamePrefix + asset.name,
                 value : asset.providesRevenue(to: [person.displayName]) ?
                    asset.value(atEndOf: year).rounded() :
                    0))
        }
    }
    
    fileprivate mutating func appendToLiabilities(_ category       : LiabilitiesCategory,
                                                  _ family         : Family,
                                                  _ liability      : Ownable,
                                                  _ year           : Int,
                                                  _ withNamePrefix : String = "") {
        liabilities[AppSettings.shared.allPersonsLabel]!.perCategory[category]?.namedValues.append(
            (name  : withNamePrefix + liability.name,
             value : liability.value(atEndOf: year).rounded()))
        
        family.members.forEach { person in
            liabilities[person.displayName]!.perCategory[category]?.namedValues.append(
                (name  : withNamePrefix + liability.name,
                 value : liability.providesRevenue(to: [person.displayName]) ?
                    liability.value(atEndOf: year).rounded() :
                    0))
        }
    }
    
    func print() {
        Swift.print("YEAR:", year)
        // actifs
        assets["Tous"]!.print(level: 1)
        // passifs
        liabilities["Tous"]!.print(level: 1)
        // net
        Swift.print("Net: \(netAssets)")
        Swift.print("-----------------------------------------")
    }
}
