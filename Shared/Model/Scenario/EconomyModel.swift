//
//  Economy.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 12/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Economy Model

struct Economy {
    
    // MARK: - Nested Types

    enum RandomVariable: String, PickableEnum, CaseIterable {
        case inflation   = "Inflation"
        case securedRate = "Rendements Sûrs"
        case stockRate   = "Rendements Actions"
        
        var pickerString: String {
            return self.rawValue
        }
    }
    
    typealias DictionaryOfRandomVariable = [RandomVariable: Double]
    
    // MARK: - Modèles statistiques de générateurs aléatoires
    struct RandomizersModel: Codable {
        
        // MARK: - Properties
        
        var inflation   : ModelRandomizer<BetaRandomGenerator>
        var securedRate : ModelRandomizer<BetaRandomGenerator> // moyenne annuelle
        var stockRate   : ModelRandomizer<BetaRandomGenerator> // moyenne annuelle
        var simulateVolatility: Bool = false
        var securedVolatility : Double // % [0, 100]
        var stockVolatility   : Double // % [0, 100]

        // MARK: - Initializers
        
        init() {
            self = Bundle.main.decode(RandomizersModel.self,
                                      from                 : "EconomyModelConfig.json",
                                      dateDecodingStrategy : .iso8601,
                                      keyDecodingStrategy  : .useDefaultKeys)
            inflation.rndGenerator.initialize()
            securedRate.rndGenerator.initialize()
            stockRate.rndGenerator.initialize()
        }

        // MARK: - Methods
        
        func storeItemsToFile(fileNamePrefix: String = "") {
            // encode to JSON file
            Bundle.main.encode(self,
                               to                   : "EconomyModelConfig.json",
                               dateEncodingStrategy : .iso8601,
                               keyEncodingStrategy  : .useDefaultKeys)
        }
        
        /// Remettre à zéro les historiques des tirages aléatoires
        fileprivate mutating func resetRandomHistory() {
            inflation.resetRandomHistory()
            securedRate.resetRandomHistory()
            stockRate.resetRandomHistory()
        }
        
        /// Générer les nombres aléatoires suivants et retourner leur valeur pour historisation
        fileprivate mutating func next() -> DictionaryOfRandomVariable {
            var dicoOfRandomVariable           = DictionaryOfRandomVariable()
            dicoOfRandomVariable[.inflation]   = inflation.next()
            dicoOfRandomVariable[.securedRate] = securedRate.next()
            dicoOfRandomVariable[.stockRate]   = stockRate.next()
            return dicoOfRandomVariable
        }
        
        /// Définir une valeur pour la variable aléatoire avant un rejeu
        /// - Parameter value: nouvelle valeure à rejouer
        fileprivate mutating func setRandomValue(to values: DictionaryOfRandomVariable) {
            inflation.setRandomValue(to: values[.inflation]!)
            securedRate.setRandomValue(to: values[.securedRate]!)
            stockRate.setRandomValue(to: values[.stockRate]!)
        }
        
        /// Retourne la suite de valeurs aléatoires tirées pour chque Run d'un Monté-Carlo
        func randomHistories() -> [RandomVariable: [Double]?] {
            var dico = [RandomVariable: [Double]?]()
            for randomVariable in RandomVariable.allCases {
                switch randomVariable {
                    case .inflation:
                        dico[randomVariable] = inflation.randomHistory
                    case .securedRate:
                        dico[randomVariable] = securedRate.randomHistory
                    case .stockRate:
                        dico[randomVariable] = stockRate.randomHistory
                }
            }
            return dico
        }
    }
    
    // MARK: - Modèles statistiques de générateurs aléatoires + échantillons tirés pour une simulation
    struct Model {
        
        // MARK: - Properties
        
        var randomizers        : RandomizersModel = RandomizersModel() // les modèles de générateurs aléatoires
        var firstYearSampled   : Int = 0
        var securedRateSamples : [Double] = [ ] // les échatillons tirés aléatoirement à chaque simulation
        var stockRateSamples   : [Double] = [ ] // les échatillons tirés aléatoirement à chaque simulation
        
        // MARK: - Methods
        
        func rates(in year       : Int,
                   withMode mode : SimulationModeEnum)
        -> (securedRate : Double,
            stockRate   : Double) {
            if mode == .random && randomizers.simulateVolatility {
                return (securedRate : securedRateSamples[year - firstYearSampled],
                        stockRate   : stockRateSamples[year - firstYearSampled])
                
            } else {
                return (securedRate : randomizers.securedRate.value(withMode: mode),
                        stockRate   : randomizers.stockRate.value(withMode: mode))
            }
        }
        
        /// Tirer au hazard une valeur pour chaque année
        /// - Parameters:
        ///   - firstYear: première année
        ///   - lastYear: dernière année
        private mutating func generateRandomSamples(firstYear : Int,
                                                    lastYear  : Int) {
            if randomizers.simulateVolatility {
                guard lastYear >= firstYear else {
                    fatalError("nbOfYears ≤ 0 in generateRandomSamples")
                }
                firstYearSampled = firstYear
                securedRateSamples = []
                stockRateSamples   = []
                for _ in firstYear...lastYear {
                    securedRateSamples.append(0)
                    stockRateSamples.append(0)
                }
            }
        }
        
        /// Remettre à zéro les historiques des tirages aléatoires
        mutating func resetRandomHistory() {
            randomizers.resetRandomHistory()
        }
        
        /// Générer les nombres aléatoires suivants et retourner leur valeur pour historisation
        /// - Parameters:
        ///   - firstYear: première année
        ///   - lastYear: dernière année
        /// - Returns: dictionnaire des échantillon de valeurs moyennes pour le prochain Run
        mutating func nextRun(firstYear : Int,
                              lastYear  : Int) -> DictionaryOfRandomVariable {
            // tirer au hazard une nouvelle valeure moyenne pour le prochain run
            let dico = randomizers.next()
            // à partir de la nouvelle valeure moyenne, tirer au hazard une valeur pour chaque année
            generateRandomSamples(firstYear : firstYear,
                                  lastYear  : lastYear)
            return dico
        }

        /// Définir une valeur pour la variable aléatoire avant un rejeu
        /// - Parameters:
        ///   - value: nouvelle valeure à rejouer
        ///   - firstYear: première année
        ///   - lastYear: dernière année
        mutating func setRandomValue(to values : DictionaryOfRandomVariable,
                                     firstYear : Int,
                                     lastYear  : Int) {
            randomizers.setRandomValue(to: values)
            // à partir de la nouvelle valeure moyenne, tirer au hazard une valeur pour chaque année
            generateRandomSamples(firstYear : firstYear,
                                  lastYear  : lastYear)
        }
    }
    
    // MARK: - Static Properties
    
    static var model: Model = Model()
}
