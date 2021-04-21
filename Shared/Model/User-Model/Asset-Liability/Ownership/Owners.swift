//
//  Owners.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Les droits de propriété d'un Owner

struct Owner : Codable, Hashable {
    
    // MARK: - Properties
    
    var name     : String = ""
    var fraction : Double = 0.0 // % [0, 100] part de propriété
    var isValid  : Bool {
        name != ""
    }
    
    // MARK: - Methods
    
    /// Calculer la quote part de valeur possédée
    /// - Parameter totalValue: Valeure totale du bien
    func ownedValue(from totalValue: Double) -> Double {
        return totalValue * fraction / 100.0
    }
}

extension Owner: CustomStringConvertible {
    var description: String {
        "(\(name), \(fraction) %) "
    }
}

// MARK: - Un tableau de Owner

typealias Owners = [Owner]

enum OwnersError: Error {
    case ownerDoesNotExist
    case noNewOwners
}

extension Owners {
    
    // MARK: - Computed Properties
    
    var sumOfOwnedFractions: Double {
        self.sum(for: \.fraction)
    }
    var percentageOk: Bool {
        sumOfOwnedFractions.isApproximatelyEqual(to: 100.0, absoluteTolerance: 0.0001)
    }
    var isvalid: Bool {
        // il la liste est vide alors elle est valide
        guard !self.isEmpty else {
            return true
        }
        // tous les owners sont valides
        var validity = self.allSatisfy { $0.isValid }
        // somes des parts = 100%
        validity = validity && percentageOk
        return validity
    }
    
    // MARK: - Methods
    
    subscript(ownerName: String) -> Owner? {
        self.first(where: { ownerName == $0.name })
    }

    static func == (lhs: Owners, rhs: Owners) -> Bool {
        for owner in lhs {
            guard let found = rhs[owner.name] else { return false }
            if !found.fraction.isApproximatelyEqual(to: owner.fraction,
                                                    absoluteTolerance: 0.0001) { return false }
        }
        for owner in rhs {
            guard let found = lhs[owner.name] else { return false }
            if !found.fraction.isApproximatelyEqual(to: owner.fraction,
                                                    absoluteTolerance: 0.0001) { return false }
        }
        return true
    }
    
    func contains(ownerName: String) -> Bool {
        self[ownerName] != nil
    }
    
    func ownerIdx(ownerName: String) -> Int? {
        self.firstIndex(where: { ownerName == $0.name })
    }
    
    /// Transérer la propriété d'un Owner vers plusieurs autres par parts égales
    /// - Parameters:
    ///   - thisOwner: celui qui sort
    ///   - theseNewOwners: ceux qui le remplacent par parts égales
    /// - Throws:
    ///  - `ownerDoesNotExist`: le propriétaire recherché n'est pas dans la liste des propriétaire
    ///  - `noNewOwners`: la liste des nouveaux propriétaires est vide
    mutating func replace(thisOwner           : String,
                          with theseNewOwners : [String]) throws {
        guard theseNewOwners.count != 0 else { throw OwnersError.noNewOwners }
        
        if let ownerIdx = self.ownerIdx(ownerName: thisOwner) {
            // part à redistribuer
            let ownerShare = self[ownerIdx].fraction
            // retirer l'ancien propriétaire
            self.remove(at: ownerIdx)
            // ajouter les nouveaux propriétaires par parts égales
            theseNewOwners.forEach { newOwner in
                self.append(Owner(name: newOwner, fraction: ownerShare / theseNewOwners.count.double()))
            }
            // Factoriser les parts des owners si nécessaire
            groupShares()
        } else {
            throw OwnersError.ownerDoesNotExist
        }
    }
    
    /// Factoriser les parts des owners si nécessaire
    mutating func groupShares() {
        // identifer les owners et compter les occurences de chaque owner dans le tableau
        let dicOfOwnersNames = self.reduce(into: [:]) { counts, owner in
            counts[owner.name, default: 0] += 1
        }
        var newTable = [Owner]()
        // factoriser toutes les parts détenues par un même owner
        for (ownerName, _) in dicOfOwnersNames {
            // calculer le cumul des parts détenues par ownerName
            let totalShare = self.reduce(0, { result, owner in
                result + (owner.name == ownerName ? owner.fraction : 0)
            })
            newTable.append(Owner(name: ownerName, fraction: totalShare))
        }
        // retirer les owners ayant une part nulle
        self = newTable.filter { $0.fraction != 0 }
    }
    
}
