//
//  Ownable.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: Protocol d'Item qui peut être Possédé, Valuable et Nameable

protocol Ownable: NameableValuable {
    var ownership: Ownership { get set }
    
    /// Calcule la valeur d'un bien possédée par un personne donnée à une date donnée
    /// selon la régle générale ou selon la règle de l'IFI, de l'ISF, de la succession...
    ///  - Note:
    ///  Pour l'IFI:
    ///
    ///  Foyer taxable:
    ///  - adultes + enfants non indépendants
    ///
    ///  Patrimoine taxable à l'IFI =
    ///  - tous les actifs immobiliers dont un propriétaire ou usufruitier
    ///  est un membre du foyer taxable
    ///
    ///  Valeur retenue:
    ///  - actif détenu en pleine-propriété: valeur de la part détenue en PP
    ///  - actif détenu en usufuit : valeur de la part détenue en PP
    ///  - la résidence principale faire l’objet d’une décote de 30 %
    ///  - les immeubles que vous donnez en location peuvent faire l’objet d’une décote de 10 % à 30 % environ
    ///  - en indivision : dans ce cas, ils sont imposables à hauteur de votre quote-part minorée d’une décote de l’ordre de 30 % pour tenir compte des contraintes liées à l’indivision)
    ///
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - year: date d'évaluation
    ///   - evaluationMethod: méthode d'évaluation de la valeure des bien
    /// - Returns: valeur du bien possédée (part d'usufruit + part de nue-prop)
    func ownedValue(by ownerName     : String,
                    atEndOf year     : Int,
                    evaluationMethod : EvaluationMethod) -> Double
    
    /// Rend un dictionnaire [Owner, Valeur possédée] en appelalnt la méthode ownedValue()
    /// - Parameters:
    ///   - year: date d'évaluation
    ///   - evaluationMethod: méthode d'évaluation de la valeure des bien
    /// - Returns: dictionnaire [Owner, Valeur possédée]
    func ownedValues(atEndOf year     : Int,
                     evaluationMethod : EvaluationMethod) -> [String : Double]
    
    func ownedValues(ofValue totalValue : Double,
                     atEndOf year       : Int,
                     evaluationMethod   : EvaluationMethod) -> [String : Double]

    /// True si une des personnes listées perçoit des revenus de ce bien.
    /// Cad si elle est une des UF ou une des PP
    /// - Parameter names: liste de noms de membres de la famille
    func providesRevenue(to names: [String]) -> Bool
    
    /// True si une des personnes listées fait partie des PP de ce bien.
    /// - Parameter names: liste de noms de membres de la famille
    func isFullyOwned(by names: [String]) -> Bool
    
    /// True si le bien fait partie du patrimoine d'une des personnes listées.
    /// Cad si elle est une des UF ou une des PP ou une des NP
    /// - Parameter names: liste de noms de membres de la famille
    func isPartOfPatrimoine(of names: [String]) -> Bool
}

extension Ownable {
    // implémentation par défaut
    func ownedValue(by ownerName     : String,
                    atEndOf year     : Int,
                    evaluationMethod : EvaluationMethod) -> Double {
        switch evaluationMethod {
            case .legalSuccession:
                // cas particulier d'une succession:
                //   le défunt est-il usufruitier ?
                if ownership.isAnUsufructOwner(ownerName: ownerName) {
                    // si oui alors l'usufruit rejoint la nu-propriété sans droit de succession
                    // l'usufruit n'est donc pas intégré à la masse successorale du défunt
                    return 0
                }
                
            case .lifeInsuranceSuccession:
                // cas particulier d'une succession:
                // on recherche uniquement les assurances vies
                return 0
                
            case .ifi, .isf, .patrimoine:
                ()
        }
        // prendre la valeur totale du bien sans aucune décote (par défaut)
        let evaluatedValue = value(atEndOf: year)
        // prendre la part de propriété
        let value = evaluatedValue == 0 ? 0 : ownership.ownedValue(by               : ownerName,
                                                                   ofValue          : evaluatedValue,
                                                                   atEndOf          : year,
                                                                   evaluationMethod : evaluationMethod)
        return value
    }
    
    // implémentation par défaut
    func ownedValues(atEndOf year     : Int,
                     evaluationMethod : EvaluationMethod) -> [String : Double] {
        var dico: [String : Double] = [:]
        if ownership.isDismembered {
            for owner in ownership.bareOwners {
                dico[owner.name] = ownedValue(by               : owner.name,
                                              atEndOf          : year,
                                              evaluationMethod : evaluationMethod)
            }
            for owner in ownership.usufructOwners {
                dico[owner.name] = ownedValue(by               : owner.name,
                                              atEndOf          : year,
                                              evaluationMethod : evaluationMethod)
            }
            
        } else {
            // valeur en pleine propriété
            for owner in ownership.fullOwners {
                dico[owner.name] = ownedValue(by               : owner.name,
                                              atEndOf          : year,
                                              evaluationMethod : evaluationMethod)
            }
        }
        return dico
    }

    func ownedValues(ofValue totalValue : Double,
                     atEndOf year       : Int,
                     evaluationMethod   : EvaluationMethod) -> [String : Double] {
        var dico: [String : Double] = [:]
        if ownership.isDismembered {
            for owner in ownership.bareOwners {
                dico[owner.name] = ownership.ownedValue(by               : owner.name,
                                                        ofValue          : totalValue,
                                                        atEndOf          : year,
                                                        evaluationMethod : evaluationMethod)
            }
            for owner in ownership.usufructOwners {
                dico[owner.name] = ownership.ownedValue(by               : owner.name,
                                                        ofValue          : totalValue,
                                                        atEndOf          : year,
                                                        evaluationMethod : evaluationMethod)
            }
            
        } else {
            // valeur en pleine propriété
            for owner in ownership.fullOwners {
                dico[owner.name] = ownership.ownedValue(by               : owner.name,
                                                        ofValue          : totalValue,
                                                        atEndOf          : year,
                                                        evaluationMethod : evaluationMethod)
            }
        }
        return dico
    }
    
    func providesRevenue(to names: [String]) -> Bool {
        (names.first(where: {
            ownership.isAFullOwner(ownerName: $0) || ownership.isAnUsufructOwner(ownerName: $0)
        }) != nil)
    }
    
    func isFullyOwned(by names: [String]) -> Bool {
        (names.first(where: {
            ownership.isAFullOwner(ownerName: $0)
        }) != nil)
    }
    
    func isPartOfPatrimoine(of names: [String]) -> Bool {
        (names.first(where: {
            ownership.isAFullOwner(ownerName: $0) || ownership.isAnUsufructOwner(ownerName: $0) || ownership.isABareOwner(ownerName: $0)
        }) != nil)
    }
}

extension Array where Element: Ownable {
    /// Calcule la valeur d'un bien possédée par un personne donnée à une date donnée
    /// selon la régle générale ou selon la règle de l'IFI, de l'ISF, de la succession...
    ///  - Note:
    ///  Pour l'IFI:
    ///
    ///  Foyer taxable:
    ///  - adultes + enfants non indépendants
    ///
    ///  Patrimoine taxable à l'IFI =
    ///  - tous les actifs immobiliers dont un propriétaire ou usufruitier
    ///  est un membre du foyer taxable
    ///
    ///  Valeur retenue:
    ///  - actif détenu en pleine-propriété: valeur de la part détenue en PP
    ///  - actif détenu en usufuit : valeur de la part détenue en PP
    ///  - la résidence principale faire l’objet d’une décote de 30 %
    ///  - les immeubles que vous donnez en location peuvent faire l’objet d’une décote de 10 % à 30 % environ
    ///  - en indivision : dans ce cas, ils sont imposables à hauteur de votre quote-part minorée d’une décote de l’ordre de 30 % pour tenir compte des contraintes liées à l’indivision)
    ///
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - year: date d'évaluation
    ///   - evaluationMethod: méthode d'évaluation de la valeure des bien
    /// - Returns: valeur du bien possédée (part d'usufruit + part de nue-prop)
    func sumOfOwnedValues (by ownerName     : String,
                           atEndOf year     : Int,
                           evaluationMethod : EvaluationMethod) -> Double {
        return reduce(.zero, {result, element in
            return result + element.ownedValue(by               : ownerName,
                                               atEndOf          : year,
                                               evaluationMethod : evaluationMethod)
        })
    }
}
