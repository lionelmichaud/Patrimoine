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
    var fraction   : Double = 0.0 // %
    var isValid    : Bool {
        name != ""
    }
    
    // MARK: - Methods
    
    /// Calculer la quote part de valeur possédée
    /// - Parameter totalValue: Valeure totale du bien
    func ownedValue(from totalValue: Double) -> Double {
        return totalValue * fraction / 100.0
    }
    
}

typealias Owners = [Owner]

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
    
}

struct Ownership: Codable {
    
    enum CodingKeys: String, CodingKey {
        case fullOwners     = "plein_propriétaires"
        case bareOwners     = "nue_propriétaires"
        case usufructOwners = "usufruitiers"
        case isDismembered  = "est_démembré"
    }
    
    // MARK: - Properties
    
    var isDismembered  : Bool   = false {
        didSet {
            if isDismembered {
                usufructOwners = fullOwners
                bareOwners     = fullOwners
            } else {
                fullOwners = usufructOwners
            }
        }
    }
    var fullOwners     : Owners = []
    var bareOwners     : Owners = []
    var usufructOwners : Owners = []
    // fonction qui donne l'age d'une personne à la fin d'une année donnée
    var ageOf          : ((_ name: String, _ year: Int) -> Int)?
    var isvalid        : Bool {
        if isDismembered {
            return (!bareOwners.isEmpty && bareOwners.isvalid) &&
                (!usufructOwners.isEmpty && usufructOwners.isvalid)
        } else {
            return !fullOwners.isEmpty && fullOwners.isvalid
        }
    }

    // MARK: - Initializers
    
    init(ageOf: @escaping (_ name: String, _ year: Int) -> Int) {
        self.ageOf = ageOf
    }
    
    init() {    }
    
    // MARK: - Methods
    
    mutating func setDelegateForAgeOf(delegate: ((_ name: String, _ year: Int) -> Int)?) {
        ageOf = delegate
    }
    
    /// Calcule les valeurs démembrées d'un bien en fonction de la date d'évaluation
    /// - Parameters:
    ///   - totalValue: valeur du bien en pleine propriété
    ///   - year: date d'évaluation
    /// - Returns: velurs de l'usufruit et de la nue-propriété
    func demembrement(ofValue totalValue : Double,
                      atEndOf year       : Int)
    -> (usufructValue : Double,
        bareValue     : Double) {
        guard isDismembered else {
            fatalError("Tentative de calul de valeur démembrée d'un bien qui ne l'est pas")
        }
        guard isvalid else {
            fatalError("Tentative de calul de valeur démembrée d'un bien dont le démembrement n'est pas valide")
        }
        guard ageOf != nil else {
            fatalError("Pas de closure permettant de calculer l'age d'un propriétaire")
        }
        
        // démembrement
        var usufructValue : Double = 0.0
        var bareValue     : Double = 0.0
        // calculer les valeurs des usufruit et nue prop
        usufructOwners.forEach { usufruitier in
            // prorata détenu par l'usufruitier
            let ownedValue = totalValue * usufruitier.fraction / 100.0
            // valeur de son usufuit
            let usufruiterAge = ageOf!(usufruitier.name, year)
            
            let (usuFruit, nueProp) = Fiscal.model.demembrement.demembrement(of              : ownedValue,
                                                                             usufructuaryAge : usufruiterAge)
            usufructValue += usuFruit
            bareValue     += nueProp
        }
        return (usufructValue: usufructValue, bareValue: bareValue)
    }
    
    func demembrementPercentage(atEndOf year: Int)
    -> (usufructPercent  : Double,
        bareValuePercent : Double) {
        let dem = demembrement(ofValue: 100.0, atEndOf: year)
        return (usufructPercent: dem.usufructValue,
                bareValuePercent: dem.bareValue)
    }
    
    /// Calcule la valeur d'un bien possédée par un personne donnée à une date donnée
    /// selon la régle générale ou selon la règle de l'IFI, de l'ISF, de la succession...
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - totalValue: valeure totale du bien
    ///   - year: date d'évaluation
    ///   - forIFI: calcul à faire selon les régles de l'IFI
    /// - Returns: valeur du bien possédée (part d'usufruit + part de nue-prop)
    func ownedValue(by ownerName       : String,
                    ofValue totalValue : Double,
                    atEndOf year       : Int,
                    evaluationMethod   : EvaluationMethod) -> Double {
        if isDismembered {
            switch evaluationMethod {
                case .ifi, .isf :
                    // calcul de la part de pleine-propriété détenue
                    if let owner = usufructOwners.first(where: { $0.name == ownerName }) {
                        // on a trouvé un usufruitier
                        return owner.ownedValue(from: totalValue)
                    } else {
                        return 0.0
                    }
                    
                default:
                    // démembrement
                    var usufructValue : Double = 0.0
                    var bareValue     : Double = 0.0
                    var value         : Double = 0.0
                    // calculer les valeurs des usufruit et nue prop
                    usufructOwners.forEach { usufruitier in
                        // prorata détenu par l'usufruitier
                        let ownedValue = totalValue * usufruitier.fraction / 100.0
                        // valeur de son usufuit
                        let usufruiterAge = ageOf!(usufruitier.name, year)
                        let (usuFruit, nueProp) = Fiscal.model.demembrement.demembrement(of              : ownedValue,
                                                                                         usufructuaryAge : usufruiterAge)
                        usufructValue += usuFruit
                        bareValue     += nueProp
                    }

                    // calcul de la part de nue-propriété détenue
                    if let owner = bareOwners.first(where: { $0.name == ownerName }) {
                        // on a trouvé un nue-propriétaire
                        value += owner.ownedValue(from: bareValue)
                    }
                    
                    // calcul de la part d'usufuit détenue
                    if let owner = usufructOwners.first(where: { $0.name == ownerName }) {
                        // on a trouvé un usufruitier
                        // prorata détenu par l'usufruitier
                        let ownedValue = totalValue * owner.fraction / 100.0
                        // valeur de son usufuit
                        let usufruiterAge = ageOf!(owner.name, year)
                        
                        value += Fiscal.model.demembrement.demembrement(of              : ownedValue,
                                                                        usufructuaryAge : usufruiterAge).usufructValue
                    }
                    return value
            }

        } else {
            // pleine propriété
            if let owner = fullOwners.first(where: { $0.name == ownerName }) {
                return owner.ownedValue(from: totalValue)
            } else {
                return 0.0
            }
        }
    }
    
    /// Retourne true si la personne est un des usufruitier du bien
    /// - Parameter ownerName: nom de la personne
    /// - Returns: true si la personne est un des usufruitiers du bien
    func isAnUsufructOwner(ownerName: String) -> Bool {
        return isDismembered && usufructOwners.contains(where: { $0.name == ownerName })
    }
}

extension Ownership: Equatable {
    static func == (lhs: Ownership, rhs: Ownership) -> Bool {
        lhs.isDismembered  == rhs.isDismembered &&
            lhs.fullOwners     == rhs.fullOwners &&
            lhs.bareOwners     == rhs.bareOwners &&
            lhs.usufructOwners == rhs.usufructOwners &&
            lhs.isvalid        == rhs.isvalid
    }
    
}
