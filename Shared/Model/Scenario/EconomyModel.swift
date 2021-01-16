//
//  Economy.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 12/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import RNGExtension

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
    struct RandomizersModel: BundleCodable {
        static var defaultFileName : String = "EconomyModelConfig.json"

        // MARK: - Properties
        
        var inflation   : ModelRandomizer<BetaRandomGenerator>
        var securedRate : ModelRandomizer<BetaRandomGenerator> // moyenne annuelle
        var stockRate   : ModelRandomizer<BetaRandomGenerator> // moyenne annuelle
        var simulateVolatility: Bool = false
        var securedVolatility : Double // % [0, 100]
        var stockVolatility   : Double // % [0, 100]
        
        // MARK: - Initializers
        
        /// Lit le modèle dans un fichier JSON du Bundle Main
        func initialized() -> RandomizersModel {
            var model = self
            model.inflation.rndGenerator.initialize()
            model.securedRate.rndGenerator.initialize()
            model.stockRate.rndGenerator.initialize()
            return model
        }
        
        // MARK: - Methods
        
        /// Enregistre le modèle au format JSON dans un fichier du Bundle Main
        /// - Parameter fileNamePrefix: préfixe du nom de fichier
//        func saveToBundleFile(fileNamePrefix: String = "") {
//            // encode to JSON file
//            self.encodeToBundle(to                   : "EconomyModelConfig.json",
//                        dateEncodingStrategy : .iso8601,
//                        keyEncodingStrategy  : .useDefaultKeys)
//        }
        
        /// Vide l'ihistorique des tirages de chaque variable aléatoire du modèle
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
        
        /// Retourne un dictionnaire donnant pour chaque variable aléatoire son historique de tirage
        /// Retourne la suite de valeurs aléatoires tirées pour chaque Run d'un Monté-Carlo
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
        
        var randomizers        : RandomizersModel = RandomizersModel().initialized() // les modèles de générateurs aléatoires
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
        ///   - withMode: mode de simulation qui détermine quelle sera la valeure moyenne retenue
        private mutating func generateRandomSamples(withMode  : SimulationModeEnum,
                                                    firstYear : Int,
                                                    lastYear  : Int) {
            if randomizers.simulateVolatility {
                guard lastYear >= firstYear else {
                    fatalError("nbOfYears ≤ 0 in generateRandomSamples")
                }
                firstYearSampled        = firstYear
                securedRateSamples      = []
                stockRateSamples        = []
                for _ in firstYear...lastYear {
                    securedRateSamples.append(Random.default.normal.next(mu   : randomizers.securedRate.value(withMode: withMode),
                                                                         sigma: randomizers.securedVolatility))
                    stockRateSamples.append(Random.default.normal.next(mu   : randomizers.stockRate.value(withMode: withMode),
                                                                       sigma: randomizers.stockVolatility))
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
        mutating func nextRun(withMode  : SimulationModeEnum,
                              firstYear : Int,
                              lastYear  : Int) -> DictionaryOfRandomVariable {
            // tirer au hazard une nouvelle valeure moyenne pour le prochain run
            let dico = randomizers.next()
            // à partir de la nouvelle valeure moyenne, tirer au hazard une valeur pour chaque année
            generateRandomSamples(withMode  : withMode,
                                  firstYear : firstYear,
                                  lastYear  : lastYear)
            return dico
        }

        /// Définir une valeur pour la variable aléatoire avant un rejeu
        /// - Parameters:
        ///   - value: nouvelle valeure à rejouer
        ///   - firstYear: première année
        ///   - lastYear: dernière année
        mutating func setRandomValue(to values : DictionaryOfRandomVariable,
                                     withMode  : SimulationModeEnum,
                                     firstYear : Int,
                                     lastYear  : Int) {
            randomizers.setRandomValue(to: values)
            // à partir de la nouvelle valeure moyenne, tirer au hazard une valeur pour chaque année
            generateRandomSamples(withMode  : withMode,
                                  firstYear : firstYear,
                                  lastYear  : lastYear)
        }
    }
    
    // MARK: - Static Properties
    
    static var model: Model = Model()
}
