//
//  Sociology.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - SocioEconomic Model

struct SocioEconomy {
    
    // MARK: - Nested Types
    
    enum RandomVariable: String, PickableEnum {
        case pensionDevaluationRate      = "Dévaluation de Pension"
        case nbTrimTauxPlein             = "Trimestres Supplémentaires"
        case expensesUnderEvaluationrate = "Sous-etimation dépenses"

        var pickerString: String {
            return self.rawValue
        }
    }
    
    typealias DictionaryOfRandomVariable = [RandomVariable: Double]
    
    struct Model: BundleCodable {
        static var defaultFileName : String = "SocioEconomyModelConfig.json"
        var pensionDevaluationRate     : ModelRandomizer<BetaRandomGenerator>
        var nbTrimTauxPlein            : ModelRandomizer<DiscreteRandomGenerator>
        var expensesUnderEvaluationrate: ModelRandomizer<BetaRandomGenerator>
        
        /// Lit le modèle dans un fichier JSON du Bundle Main
        func initialized() -> Model {
            var model = self
            model.pensionDevaluationRate.rndGenerator.initialize()
            model.nbTrimTauxPlein.rndGenerator.initialize()
            model.expensesUnderEvaluationrate.rndGenerator.initialize()
            return model
        }
        
//        /// Enregistre le modèle au format JSON dans un fichier du Bundle Main
//        /// - Parameter fileNamePrefix: préfixe du nom de fichier
//        func saveToBundleFile(fileNamePrefix: String = "") {
//            // encode to JSON file
//            self.encodeToBundle(to                   : "SocioEconomyModelConfig.json",
//                                dateEncodingStrategy : .iso8601,
//                                keyEncodingStrategy  : .useDefaultKeys)
//        }
        
        /// Vide l'ihistorique des tirages de chaque variable aléatoire du modèle
        mutating func resetRandomHistory() {
            pensionDevaluationRate.resetRandomHistory()
            nbTrimTauxPlein.resetRandomHistory()
            expensesUnderEvaluationrate.resetRandomHistory()
        }
        
        /// Générer les nombres aléatoires suivants et retourner leur valeur pour historisation
        mutating func next() -> DictionaryOfRandomVariable {
            var dicoOfRandomVariable = DictionaryOfRandomVariable()
            dicoOfRandomVariable[.pensionDevaluationRate]      = pensionDevaluationRate.next()
            dicoOfRandomVariable[.nbTrimTauxPlein]             = nbTrimTauxPlein.next()
            dicoOfRandomVariable[.expensesUnderEvaluationrate] = expensesUnderEvaluationrate.next()
            return dicoOfRandomVariable
        }
        
        /// Définir une valeur pour la variable aléaoitre avant un rejeu
        /// - Parameter value: nouvelle valeure à rejouer
        mutating func setRandomValue(to values: DictionaryOfRandomVariable) {
            pensionDevaluationRate.setRandomValue(to: values[.pensionDevaluationRate]!)
            nbTrimTauxPlein.setRandomValue(to: values[.nbTrimTauxPlein]!)
            expensesUnderEvaluationrate.setRandomValue(to: values[.expensesUnderEvaluationrate]!)
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
                    case .expensesUnderEvaluationrate:
                        dico[randomVariable] = expensesUnderEvaluationrate.randomHistory
                }
            }
            return dico
        }
    }
    
    // MARK: - Static Properties
    
    static var model: Model = Model().initialized()
}
