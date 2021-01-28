//
//  Unemployment.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - SINGLETON: Modèle d'indemnité de licenciement et de Chomage
struct Unemployment {
    
    // nested types
    
    enum Cause: String, PickableEnum, Codable {
        case demission                          = "Démission"
        case licenciement                       = "Licenciement"
        case ruptureConventionnelleIndividuelle = "Rupture individuelle"
        case ruptureConventionnelleCollective   = "Rupture collective"
        case planSauvegardeEmploi               = "PSE"
        
        // methods
        
        var pickerString: String {
            return self.rawValue
        }
    }
    
    struct Model: BundleCodable {
        static var defaultFileName : String = "UnemploymentModelConfig.json"
        var indemniteLicenciement  : LayoffCompensation
        var allocationChomage      : UnemploymentCompensation
    }
    
    // properties
    
    static var model: Model = Model()
    // methods
    
    /// Indique si la personne à droit à une allocation et une indemnité
    /// - Parameter cause: cause de la cessation d'activité
    /// - Returns: vrai si a droit
    static func canReceiveAllocation(for cause: Cause) -> Bool {
        cause != .demission
    }
}
