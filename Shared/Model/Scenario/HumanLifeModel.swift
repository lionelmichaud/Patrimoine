//
//  HumanLifeModel.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - SINGLETON: Human Life Model

struct HumanLife {
    
    // MARK: - Nested Types
    
    enum RandomVariable: String, PickableEnum {
        case menLifeExpectation    = "Espérance de Vie d'un Homme"
        case womenLifeExpectation  = "Espérance de Vie d'uns Femme"
        case nbOfYearsOfdependency = "Nombre d'années de Dépendance"
        
        var pickerString: String {
            return self.rawValue
        }
    }
    
    struct Model: BundleCodable {
        static var defaultFileName : String = "HumanLifeModelConfig.json"
        var menLifeExpectation    : ModelRandomizer<DiscreteRandomGenerator>
        var womenLifeExpectation  : ModelRandomizer<DiscreteRandomGenerator>
        var nbOfYearsOfdependency : ModelRandomizer<DiscreteRandomGenerator>
        
        /// Lit le modèle dans un fichier JSON du Bundle Main
        func initialized() -> Model {
            var model = self
            model.menLifeExpectation.rndGenerator.initialize()
            model.womenLifeExpectation.rndGenerator.initialize()
            model.nbOfYearsOfdependency.rndGenerator.initialize()
            return model
        }
        
        /// Vide l'ihistorique des tirages de chaque variable aléatoire du modèle
        mutating func resetRandomHistory() {
            menLifeExpectation.resetRandomHistory()
            womenLifeExpectation.resetRandomHistory()
            nbOfYearsOfdependency.resetRandomHistory()
        }
        
        /// Retourne un dictionnaire donnant pour chaque variable aléatoire son historique de tirage
        /// Retourne la suite de valeurs aléatoires tirées pour chaque Run d'un Monté-Carlo
        /// - Returns: dictionnaire donnant pour chaque variable aléatoire son historique de tirage
        func randomHistories() -> [RandomVariable: [Double]?] {
            var dico = [RandomVariable: [Double]?]()
            for randomVariable in RandomVariable.allCases {
                switch randomVariable {
                    case .menLifeExpectation:
                        dico[randomVariable] = menLifeExpectation.randomHistory
                    case .womenLifeExpectation:
                        dico[randomVariable] = womenLifeExpectation.randomHistory
                    case .nbOfYearsOfdependency:
                        dico[randomVariable] = nbOfYearsOfdependency.randomHistory
                }
            }
            return dico
        }    
    }
    
    // MARK: - Static Properties
    
    static var model: Model = Model().initialized()
}
