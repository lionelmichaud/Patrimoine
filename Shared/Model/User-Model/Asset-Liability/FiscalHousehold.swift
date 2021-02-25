//
//  FiscalHousehold.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 08/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct FiscalHousehold {
    /// calcule une valeur cumulée sur l'ensemble des membres d'un foyer fiscal
    /// - Parameters:
    ///   - year: année de calcul
    ///   - ownedValue: méthode d'évaluation de la valeur du patrimoine d'un membre du foyer fiscal
    /// - Returns: valeur cumulée sur l'ensemble des membres d'un foyer fiscal
    static func value(atEndOf year : Int,
                      for family   : Family,
                      ownedValue   : (String) -> Double) -> Double {
        /// pour: adultes + enfants non indépendants
        var cumulatedvalue: Double = 0.0
        
        for member in family.members {
            var toBeConsidered : Bool
            
            if member is Adult {
                toBeConsidered = true
            } else if member is Child {
                let child = member as! Child
                toBeConsidered = !child.isIndependant(during: year)
            } else {
                toBeConsidered = false
            }
            
            if toBeConsidered {
                cumulatedvalue +=
                    ownedValue(member.displayName)
            }
        }
        return cumulatedvalue
    }
    
    static func nbOfMembers(in family    : Family,
                            atEndOf year : Int) -> Int {
        family.nbOfAdultAlive(atEndOf: year) +
            family.nbOfFiscalChildren(during: year)
    }
}
