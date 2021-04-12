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
    
    init(withYear year               : Int,
         withMembersName membersName : [String],
         withAssets assets           : [(ownable: Ownable, category: AssetsCategory)],
         withLiabilities liabilities : [(ownable: Ownable, category: LiabilitiesCategory)]) {
        //        autoreleasepool {
        self.year = year
        
        // initialiser les dictionnaires
        self.assets      = [AppSettings.shared.allPersonsLabel: ValuedAssets(name: "ACTIF")]
        self.liabilities = [AppSettings.shared.allPersonsLabel: ValuedLiabilities(name : "PASSIF")]
        membersName.forEach { name in
            self.assets[name]      = ValuedAssets(name : "ACTIF")
            self.liabilities[name] = ValuedLiabilities(name : "PASSIF")
        }
        
        // actifs
        for asset in assets {
            appendToAssets(asset.category, membersName, asset.ownable, year)
        }
        
        // dettes
        for liability in liabilities {
            appendToLiabilities(liability.category, membersName, liability.ownable, year)
        }
        //        }
    }
    
    // MARK: - Methods
    
    fileprivate mutating func appendToAssets(_ category       : AssetsCategory,
                                             _ membersName    : [String],
                                             _ asset          : Ownable,
                                             _ year           : Int) {
        let namePrefix: String
        switch category {
            
            case .sci:
                namePrefix = "SCI - "
                
            default:
                namePrefix = ""
        }
        
        assets[AppSettings.shared.allPersonsLabel]!.perCategory[category]?.namedValues
            .append((name  : namePrefix + asset.name,
                     value : asset.value(atEndOf: year).rounded()))
        
        membersName.forEach { name in
            let selected = isSelected(ownable  : asset, name  : name)
            let value    = graphicValueOf(ownable : asset, isSelected : selected, name : name)
            
            assets[name]!.perCategory[category]?.namedValues
                .append((name  : namePrefix + asset.name,
                         value : value))
        }
    }
    
    fileprivate mutating func appendToLiabilities(_ category       : LiabilitiesCategory,
                                                  _ membersName    : [String],
                                                  _ liability      : Ownable,
                                                  _ year           : Int) {
        liabilities[AppSettings.shared.allPersonsLabel]!.perCategory[category]?.namedValues
            .append((name  : liability.name,
                     value : liability.value(atEndOf: year).rounded()))
        
        membersName.forEach { name in
            let selected = isSelected(ownable: liability, name: name)
            let value    = graphicValueOf(ownable : liability, isSelected : selected, name : name)

            liabilities[name]!.perCategory[category]?.namedValues
                .append( (name  : liability.name,
                          value : value))
        }
    }
    
    fileprivate func isSelected(ownable: Ownable, name: String) -> Bool {
        switch UserSettings.shared.ownershipSelection {
            
            case .generatesRevenue:
                return ownable.providesRevenue(to: [name])
                
            case .sellable:
                return ownable.isFullyOwned(partlyBy: [name])
                
            case .all:
                return ownable.isPartOfPatrimoine(of: [name])
        }
    }
    
    fileprivate func graphicValueOf(ownable: Ownable, isSelected: Bool, name: String) -> Double {
        switch UserSettings.shared.assetEvaluationMethod {
            
            case .totalValue:
                return isSelected ?
                    ownable.value(atEndOf: year).rounded()
                    : 0
                
            case .ownedValue:
                return isSelected ?
                    ownable.ownedValue(by              : name,
                                       atEndOf         : year,
                                       evaluationMethod: .patrimoine).rounded()
                    : 0
        }
    }
    
    func print() {
        Swift.print("YEAR:", year)
        // actifs
        assets[AppSettings.shared.allPersonsLabel]!.print(level: 1)
        // passifs
        liabilities[AppSettings.shared.allPersonsLabel]!.print(level: 1)
        // net
        Swift.print("Net: \(netAssets)")
        Swift.print("-----------------------------------------")
    }
}
