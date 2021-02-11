//
//  Sociology.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - DI: Protocol InflationProviderProtocol

protocol PensionDevaluationRateProviderProtocol {
    func pensionDevaluationRate(withMode simulationMode: SimulationModeEnum) -> Double
}

protocol NbTrimTauxPleinProviderProtocol {
    func nbTrimTauxPlein(withMode simulationMode: SimulationModeEnum) -> Double
}

protocol ExpensesUnderEvaluationRateProviderProtocol {
    func expensesUnderEvaluationRate(withMode simulationMode: SimulationModeEnum) -> Double
}

typealias SocioEconomyModelProvider = PensionDevaluationRateProviderProtocol &
    NbTrimTauxPleinProviderProtocol &
    ExpensesUnderEvaluationRateProviderProtocol

// MARK: - SINGLETON: SocioEconomic Model

struct SocioEconomy {
    
    // MARK: - Nested Types
    
    enum RandomVariable: String, PickableEnum {
        case pensionDevaluationRate      = "Dévaluation de Pension"
        case nbTrimTauxPlein             = "Trimestres Supplémentaires"
        case expensesUnderEvaluationRate = "Sous-etimation dépenses"

        var pickerString: String {
            return self.rawValue
        }
    }
    
    typealias DictionaryOfRandomVariable = [RandomVariable: Double]
    
    struct Model: BundleCodable, SocioEconomyModelProvider {
        static var defaultFileName : String = "SocioEconomyModelConfig.json"
        var pensionDevaluationRate     : ModelRandomizer<BetaRandomGenerator>
        var nbTrimTauxPlein            : ModelRandomizer<DiscreteRandomGenerator>
        var expensesUnderEvaluationRate: ModelRandomizer<BetaRandomGenerator>
        
        /// Initialise le modèle après l'avoir chargé à partir d'un fichier JSON du Bundle Main
        func initialized() -> Model {
            var model = self
            model.pensionDevaluationRate.rndGenerator.initialize()
            model.nbTrimTauxPlein.rndGenerator.initialize()
            model.expensesUnderEvaluationRate.rndGenerator.initialize()
            return model
        }
        
        /// Vide l'ihistorique des tirages de chaque variable aléatoire du modèle
        mutating func resetRandomHistory() {
            pensionDevaluationRate.resetRandomHistory()
            nbTrimTauxPlein.resetRandomHistory()
            expensesUnderEvaluationRate.resetRandomHistory()
        }
        
        /// Générer les nombres aléatoires suivants et retourner leur valeur pour historisation
        mutating func next() -> DictionaryOfRandomVariable {
            var dicoOfRandomVariable = DictionaryOfRandomVariable()
            dicoOfRandomVariable[.pensionDevaluationRate]      = pensionDevaluationRate.next()
            dicoOfRandomVariable[.nbTrimTauxPlein]             = nbTrimTauxPlein.next()
            dicoOfRandomVariable[.expensesUnderEvaluationRate] = expensesUnderEvaluationRate.next()
            return dicoOfRandomVariable
        }
        
        /// Définir une valeur pour la variable aléaoitre avant un rejeu
        /// - Parameter value: nouvelle valeure à rejouer
        mutating func setRandomValue(to values: DictionaryOfRandomVariable) {
            pensionDevaluationRate.setRandomValue(to: values[.pensionDevaluationRate]!)
            nbTrimTauxPlein.setRandomValue(to: values[.nbTrimTauxPlein]!)
            expensesUnderEvaluationRate.setRandomValue(to: values[.expensesUnderEvaluationRate]!)
        }
        
        /// Retourne un dictionnaire donnant pour chaque variable aléatoire son historique de tirage
        /// Retourne la suite de valeurs aléatoires tirées pour chaque Run d'un Monté-Carlo
        func randomHistories() -> [RandomVariable: [Double]?] {
            var dico = [RandomVariable: [Double]?]()
            for randomVariable in RandomVariable.allCases {
                switch randomVariable {
                    case .pensionDevaluationRate:
                        dico[randomVariable] = pensionDevaluationRate.randomHistory
                    case .nbTrimTauxPlein:
                        dico[randomVariable] = nbTrimTauxPlein.randomHistory
                    case .expensesUnderEvaluationRate:
                        dico[randomVariable] = expensesUnderEvaluationRate.randomHistory
                }
            }
            return dico
        }

        func pensionDevaluationRate(withMode simulationMode: SimulationModeEnum) -> Double {
            pensionDevaluationRate.value(withMode: simulationMode)
        }

        func nbTrimTauxPlein(withMode simulationMode: SimulationModeEnum) -> Double {
            nbTrimTauxPlein.value(withMode: simulationMode)
        }

        func expensesUnderEvaluationRate(withMode simulationMode: SimulationModeEnum) -> Double {
            expensesUnderEvaluationRate.value(withMode: simulationMode)
        }
    }

    // MARK: - Static Properties

    static var model: Model = Model().initialized()

    // MARK: - Initializer
    
    private init() {
    }
}
