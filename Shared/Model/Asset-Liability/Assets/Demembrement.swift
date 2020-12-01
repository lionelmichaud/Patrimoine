//
//  Demembrement.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct Owner : Codable, Hashable {
    
    // MARK: - Properties
    
    var name       : String = ""
    var age        : Int    = 0
    var fraction   : Double = 0.0 // %
    var ownedValue : Double = 0.0 // €
    
    // MARK: - Methods
    
    /// Calculer la répartition de valeur entre les co-ropriétaires, usufruitiers et nu-propriétaires
    /// - Parameter totalValue: Valeure totale du bien
    mutating func updateOwnedValue(with totalValue: Double) {
        ownedValue = totalValue * fraction / 100.0
    }
}

typealias Owners = [Owner]

extension Owners {
    
    // MARK: - Computed Properties
    
    var sumOfOwnedValues: Double {
        self.sum(for: \.ownedValue)
    }
    var sumOfOwnedFractions: Double {
        self.sum(for: \.fraction)
    }
    
    // MARK: - Methods
    
    /// Redistribuer les part d'un utilisateur qui aurait été supprimé de manière égale sur les autres
    ///  - Warning : penser ensuite à remettre à jour les valeurs respectives au niveau global avec ownership.updateSharedValues()
//    mutating func updateOwnersFraction(updateSharedValues: () -> ()) {
//        let missingFraction = Swift.max(0.0, 100.0 - self.sumOfOwnedFractions)
//        let toBeDistributed = missingFraction / self.count.double()
//        for idx in 0..<self.count {
//            self[idx].fraction += toBeDistributed
//        }
//        updateSharedValues()
//    }
}

struct Ownership: Codable {
    
    // MARK: - Properties
    
    var isDismembered : Bool   = false {
        didSet {
            if isDismembered {
                usufructOwners = fullOwners
            } else {
                fullOwners = usufructOwners
            }
            updateSharedValues()
        }
    }
    var totalValue : Double = 0.0 {
        didSet {
            updateSharedValues()
        }
    }
    var fullOwners     : Owners = [Owner(name: "Lionel",  age: 56, fraction: 60),
                                   Owner(name: "Vanessa", age: 49, fraction: 40)]
    var bareOwners     : Owners = [Owner(name: "Lou-Ann", fraction: 60),
                                   Owner(name: "Arthur",  fraction: 40)]
    var usufructOwners : Owners = []
    
    // MARK: - Methods
    
    mutating func updateSharedValues() {
        if isDismembered {
            // démembrement
            var usufructValue : Double = 0.0
            var bareValue     : Double = 0.0
            // calculer les valeurs des usufruit et nue prop
            usufructOwners.forEach { usufruitier in
                // prorata détenu par l'usufruitier
                let ownedValue = totalValue * usufruitier.fraction / 100.0
                // valeur de son usufuit
                let (usuFruit, nueProp) = Fiscal.model.demembrement.demembrement(of             : ownedValue,
                                                                                 usufruitierAge : usufruitier.age)
                usufructValue += usuFruit
                bareValue     += nueProp
            }
            let check = totalValue - (usufructValue + bareValue)
            print("check = totalValue - (usufructValue + bareValue) = \(check)")
            
            // mettre à jour la répartition de la valeur des usufruits
            for idx in 0..<usufructOwners.count {
                // prorata détenu par l'usufruitier
                let ownedValue = totalValue * usufructOwners[idx].fraction / 100.0
                // valeur de son usufruit
                usufructOwners[idx].ownedValue = Fiscal.model.demembrement.demembrement(of             : ownedValue,
                                                                                        usufruitierAge : usufructOwners[idx].age).usufructValue
            }
            
            // mettre à jour la répartition de la valeur des nue-propriétés
            for idx in 0..<bareOwners.count {
                bareOwners[idx].updateOwnedValue(with: bareValue)
            }
            
        } else {
            // pleine propriété
            for idx in 0..<fullOwners.count {
                fullOwners[idx].updateOwnedValue(with: totalValue)
            }
        }
    }
}
