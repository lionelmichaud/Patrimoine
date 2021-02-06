//
//  Demembrement.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.Ownership")

// MARK: - Méthode d'évaluation d'un Patrmoine (régles fiscales à appliquer)
enum EvaluationMethod: String, PickableEnum {
    case ifi                     = "IFI"
    case isf                     = "ISF"
    case legalSuccession         = "Succession Légale"
    case lifeInsuranceSuccession = "Succession Assurance Vie"
    case patrimoine              = "Patrimoniale"
    
    var pickerString: String {
        return self.rawValue
    }
}

// MARK: - La répartition des droits de propriété d'un bien entre personnes

enum OwnershipError: Error {
    case tryingToDismemberUnUndismemberedAsset
    case invalidOwnership
}

struct Ownership: Codable, CustomStringConvertible {
    
    // MARK: - Nested Types

    enum CodingKeys: String, CodingKey {
        case fullOwners     = "plein_propriétaires"
        case bareOwners     = "nue_propriétaires"
        case usufructOwners = "usufruitiers"
        case isDismembered  = "est_démembré"
    }
    
    // MARK: - Static Properties
    
    static var fiscalModel : Fiscal.Model = Fiscal.model
    
    // MARK: - Properties

    var fullOwners     : Owners = []
    var bareOwners     : Owners = []
    var usufructOwners : Owners = []
    // fonction qui donne l'age d'une personne à la fin d'une année donnée
    var ageOf          : ((_ name: String, _ year: Int) -> Int)?
    var isDismembered  : Bool   = false {
        didSet {
            if isDismembered {
                usufructOwners = fullOwners
                bareOwners     = fullOwners
            }
        }
    }
    var isValid        : Bool {
        if isDismembered {
            return (!bareOwners.isEmpty && bareOwners.isvalid) &&
                (!usufructOwners.isEmpty && usufructOwners.isvalid)
        } else {
            return !fullOwners.isEmpty && fullOwners.isvalid
        }
    }
    var description: String {
        let header = """
        OWNERSHIP:
         - Valide:   \(isValid)
         - Démembré: \(isDismembered)

        """
        let pp =
            !isDismembered ? " - Plein Propriétaires:\n    \(fullOwners.description)" : ""
        let uf =
            isDismembered ? " - Usufruitiers:\n    \(usufructOwners.description) \n" : ""
        let np =
        isDismembered ? " - Nu-Propriétaires:\n    \(bareOwners.description)" : ""
        return header + pp + uf + np + "\n"
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
                      atEndOf year       : Int) throws
    -> (usufructValue : Double,
        bareValue     : Double) {
        guard isDismembered else {
            customLog.log(level: .error, "Tentative de calul de valeur démembrée d'un bien qui ne l'est pas")
            throw OwnershipError.tryingToDismemberUnUndismemberedAsset
        }
        guard isValid else {
            customLog.log(level: .error, "Tentative de calul de valeur démembrée d'un bien dont le démembrement n'est pas valide")
            throw OwnershipError.invalidOwnership
        }
        guard ageOf != nil else {
            customLog.log(level: .fault, "Pas de closure permettant de calculer l'age d'un propriétaire")
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
            
            let (usuFruit, nueProp) =
                try! Ownership.fiscalModel.demembrement.demembrement(of              : ownedValue,
                                                                     usufructuaryAge : usufruiterAge)
            usufructValue += usuFruit
            bareValue     += nueProp
        }
        return (usufructValue: usufructValue, bareValue: bareValue)
    }
    
    func demembrementPercentage(atEndOf year: Int) throws
    -> (usufructPercent  : Double,
        bareValuePercent : Double) {
        let dem = try demembrement(ofValue: 100.0, atEndOf: year)
        return (usufructPercent : dem.usufructValue,
                bareValuePercent: dem.bareValue)
    }
    
    /// Calcule la valeur d'un bien possédée par un personne donnée à une date donnée
    /// selon la régle générale ou selon la règle de l'IFI, de l'ISF, de la succession...
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - totalValue: valeure totale du bien
    ///   - year: date d'évaluation
    ///   - evaluationMethod: règles fiscales à utiliser pour le calcul
    /// - Returns: valeur du bien possédée (part d'usufruit + part de nue-prop)
    func ownedValue(by ownerName       : String,
                    ofValue totalValue : Double,
                    atEndOf year       : Int,
                    evaluationMethod   : EvaluationMethod) -> Double {
        if isDismembered {
            switch evaluationMethod {
                case .ifi, .isf :
                    // calcul de la part de pleine-propriété détenue
                    if let owner = usufructOwners.owner(ownerName: ownerName) {
                        // on l'a trouvé parmis les usufruitiers => on prend la valeur en PP
                        return owner.ownedValue(from: totalValue)
                    } else {
                        // ne fait pas partie des usufruitiers
                        return 0.0
                    }
                    
                case .legalSuccession, .lifeInsuranceSuccession, .patrimoine:
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
                        let (usuFruit, nueProp) =
                            try! Ownership.fiscalModel.demembrement.demembrement(of              : ownedValue,
                                                                                 usufructuaryAge : usufruiterAge)
                        usufructValue += usuFruit
                        bareValue     += nueProp
                    }

                    // calcul de la part de nue-propriété détenue
                    if let owner = bareOwners.owner(ownerName: ownerName) {
                        // on a trouvé un nue-propriétaire
                        value += owner.ownedValue(from: bareValue)
                    }
                    
                    // calcul de la part d'usufuit détenue
                    if let owner = usufructOwners.owner(ownerName: ownerName) {
                        // on a trouvé un usufruitier
                        // prorata détenu par l'usufruitier
                        let ownedValue = totalValue * owner.fraction / 100.0
                        // valeur de son usufuit
                        let usufruiterAge = ageOf!(owner.name, year)
                        
                        value +=
                            try! Ownership.fiscalModel.demembrement.demembrement(of              : ownedValue,
                                                                                 usufructuaryAge : usufruiterAge).usufructValue
                    }
                    return value
            }

        } else {
            // pleine propriété
            if let owner = fullOwners.owner(ownerName: ownerName) {
                return owner.ownedValue(from: totalValue)
            } else {
                return 0.0
            }
        }
    }
    
    /// Transférer l'usufruit du défunt aux nue-propriétaires
    /// - Note:
    ///   - le défunt était seulement usufruitier
    ///   - le défunt avait donné sa nue-propriété avant son décès, alors l'usufruit rejoint la nue-propriété
    ///   - cad que les nues-propriétaires deviennent PP
    /// - Parameters:
    ///   - decedentName: le nom du défunt
    ///   - chidrenNames: les enfants héritiers survivants
    /// - Warning: Ne donne pas le bon résultat pour un bien indivis.
    private mutating func transferUsufruct(of decedentName         : String,
                                           toChildren chidrenNames : [String]?) {
        // TODO: - Gérer correctement les transferts de propriété des biens indivis et démembrés
        if let chidrenNames = chidrenNames {
            //if let decedent = usufructOwners.owner(ownerName: decedentName) {
                // la part d'usufruit à transmettre
                //let usufructShare = decedent.fraction
                
                // l'UF rejoint la nue-propriété (enfants seulement)
                chidrenNames.forEach { childName in
                    if let bareowner = bareOwners.owner(ownerName: childName) {
                        usufructOwners.append(Owner(name: bareowner.name,
                                                    fraction: bareowner.fraction))
                    }
                }
                
                // on supprime le défunt de la liste
                usufructOwners.removeAll(where: { $0.name == decedentName })
                
                // factoriser les parts des usufuitiers et des nue-propriétaires si nécessaire
                groupShares()
            //}
        }
    }
    
    /// Transférer la NP et UF  d'un copropriétaire d'un bien démembré à ses héritiers selon l'option retenue par le conjoint survivant
    /// - Note:
    ///  - le défunt était usufruitier et nue-propriétaire
    ///  - UF + NP sont transmis selon l'option du conjoint survivant comme une PP
    ///
    /// - Parameters:
    ///   - decedentName: le nom du défunt
    ///   - spouseName: le conjoint survivant
    ///   - chidrenNames: les enfants héritiers survivants
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    private mutating func transferUsufructAndBareOwnership(of decedentName         : String,
                                                           toSpouse spouseName     : String,
                                                           toChildren chidrenNames : [String]?,
                                                           spouseFiscalOption      : InheritanceDonation.FiscalOption?) {
        if let chidrenNames = chidrenNames {
            // il y a des enfants héritiers
            // transmission NP + UF selon l'option fiscale du conjoint survivant
            guard let spouseFiscalOption = spouseFiscalOption else {
                fatalError("pas d'option fiscale passée en paramètre de transferOwnershipOf")
            }
            // l'UF du défunt rejoint la nue propriété des enfants qui la détiennent
            transferUsufruct(of         : decedentName,
                             toChildren : chidrenNames)
            // la NP est transmise aux enfants nue-propriétaires
            transferBareOwnership(of                 : decedentName,
                                  toSpouse           : spouseName,
                                  toChildren         : chidrenNames,
                                  spouseFiscalOption : spouseFiscalOption)
            
        } else {
            // il n'y pas d'enfant héritier mais un conjoint survivant
            // tout revient au conjoint survivant en PP
            // on transmet l'UF au conjoint survivant
            if let ownerIdx = usufructOwners.firstIndex(where: { decedentName == $0.name }) {
                // la part d'usufruit à transmettre
                let ownerShare = usufructOwners[ownerIdx].fraction
                usufructOwners.append(Owner(name: spouseName, fraction: ownerShare))
                // on supprime le défunt de la liste
                usufructOwners.remove(at: ownerIdx)
            }
            // on transmet la NP au conjoint survivant
            if let ownerIdx = bareOwners.firstIndex(where: { decedentName == $0.name }) {
                let ownerShare = bareOwners[ownerIdx].fraction
                // la part de nue-propriété à transmettre
                bareOwners.append(Owner(name: spouseName, fraction: ownerShare))
                // on supprime le défunt de la liste
                bareOwners.remove(at: ownerIdx)
            }
        }
        // factoriser les parts des usufuitiers et des nue-propriétaires si nécessaire
        groupShares()
    }
    
    /// Factoriser les parts des usufuitier et les nue-propriétaires si nécessaire
    mutating func groupShares() {
        if isDismembered {
            fullOwners = [ ]
            usufructOwners.groupShares()
            bareOwners.groupShares()
        } else {
            fullOwners.groupShares()
            usufructOwners = [ ]
            bareOwners     = [ ]
        }
        // regrouper usufruit et nue-propriété si possible
        if isDismembered {
            if usufructOwners == bareOwners {
                isDismembered  = false
                fullOwners     = bareOwners
                usufructOwners = [ ]
                bareOwners     = [ ]
            }
        }
    }
    
    /// Transférer la NP et UF  d'une assurance vie aux donataires selon la clause bénéficiaire
    ///
    /// - Parameters:
    ///   - decedentName: le nom du défunt
    ///   - clause: la clause bénéficiare de l'assurance vie
    ///
    /// - Note:
    ///  + le capital peut être démembré
    ///  + la clause bénéficiare peut aussi être démembrée
    ///
    /// - Warning:
    ///   - Le cas du capital démembrée et le défunt est nue-propriétaire n'est pas traité
    ///   - Le cas du capital co-détenu en PP par plusieurs personnes n'est pas traité
    ///   - le cas de plusieurs usufruitiers bénéficiaires n'est pas traité
    ///   - Le cas de parts non égales entre nue-propriétaires n'est pas traité
    ///
    /// - Throws:
    ///   - OwnershipError.invalidOwnership: le ownership avant ou après n'est pas valide
    mutating func transferLifeInsuranceOfDecedent(of decedentName    : String,
                                                  accordingTo clause : LifeInsuranceClause) throws {
        guard isValid else {
            customLog.log(level: .error, "'transferOwnershipOf' a généré un 'ownership' invalide")
            throw OwnershipError.invalidOwnership
        }
        
        if isDismembered {
            // (A) le capital de l'assurane vie est démembré
            if usufructOwners.contains(where: { decedentName == $0.name }) {
                // (1) le défunt est usufruitier
                // l'usufruit rejoint la nue-propriété
                transfertLifeInsuranceUsufruct()
                
            } else if bareOwners.contains(where: { decedentName == $0.name }) {
                // (2) le défunt est un nue-propriétaire
                // TODO: - traiter le cas où le capital de l'assurance vie est démembré et le défunt est nue-propriétaire
                fatalError("transferLifeInsuranceOfDecedent: cas non traité (capital démembré et le défunt est nue-propriétaire)")
            } // (3) le défunt n'est ni usufruitier ni nue-propriétaire => on ne fait rien

        } else {
            // (B) le capital de l'assurance vie n'est pas démembré
            // le défunt est-il un des PP propriétaires du capital de l'assurance vie ?
            if fullOwners.contains(where: { decedentName == $0.name }) {
                // (1) le défunt est un des PP propriétaires du capital de l'assurance vie
                if fullOwners.count == 1 {
                    // (a) il n'y a qu'un seul PP de l'assurance vie
                    if clause.isDismembered {
                        // (1) la clause bénéficiaire de l'assurane vie est démembrée
                        isDismembered = true
                        // Transférer l'usufruit et la bue-prorpiété de l'assurance vie séparement
                        transferLifeInsuranceUsufructAndBareOwnership(clause: clause)
                        
                    } else {
                        // (2) la clause bénéficiaire de l'assurane vie n'est pas démembrée
                        // transférer le bien en PP aux donataires désignés dans la clause bénéficiaire par parts égales
                        isDismembered = false
                        transferLifeInsuranceFullOwnership(clause: clause)
                    }
                    
                } else {
                    // (b)
                    // TODO: - traiter le cas où le capital est co-détenu en PP par plusieurs personnes
                    fatalError("transferLifeInsuranceOfDecedent: cas non traité (capital co-détenu en PP par plusieurs personnes)")
                }
            } // (2) sinon on ne fait rien
        }
        groupShares()
        
        guard isValid else {
            customLog.log(level: .error, "'transferOwnershipOf' a généré un 'ownership' invalide")
            throw OwnershipError.invalidOwnership
        }
    }
    
    /// Transférer la propriété d'un bien d'un défunt vers ses héritiers en fonction de l'option
    ///  fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    /// - Warning: Ne donne pas le bon résultat pour un bien indivis.
    /// - Throws:
    ///   - OwnershipError.invalidOwnership: le ownership avant ou après n'est pas valide
    mutating func transferOwnershipOf(decedentName       : String,
                                      chidrenNames       : [String]?,
                                      spouseName         : String?,
                                      spouseFiscalOption : InheritanceDonation.FiscalOption?) throws {
        guard isValid else {
            customLog.log(level: .error, "Tentative de transfert de propriéta avec 'ownership' invalide")
            throw OwnershipError.invalidOwnership
        }
        
        if isDismembered {
            // (A) le bien est démembré
            if let spouseName = spouseName {
                // TODO: - Gérer correctement les transferts de propriété des biens indivis et démembrés
                // (1) il y a un conjoint survivant
                //     le défunt peut être usufruitier et/ou nue-propriétaire
                
                // USUFRUIT
                if usufructOwners.contains(ownerName: decedentName) {
                    // (a) le défunt était usufruitier
                    if bareOwners.contains(ownerName: decedentName) {
                        // (1) le défunt était aussi nue-propriétaire
                        // le défunt possèdait encore la UF + NP et les deux sont transmis
                        // selon l'option du conjoint survivant comme une PP
                        transferUsufructAndBareOwnership(of                 : decedentName,
                                                         toSpouse           : spouseName,
                                                         toChildren         : chidrenNames,
                                                         spouseFiscalOption : spouseFiscalOption)
                        
                    } else {
                        // (2) le défunt était seulement usufruitier
                        // le défunt avait donné sa nue-propriété avant son décès, alors l'usufruit rejoint la nue-propriété
                        // cad que les nues-propriétaires deviennent PP
                        transferUsufruct(of         : decedentName,
                                         toChildren : chidrenNames)

                    }
                } else if bareOwners.contains(ownerName: decedentName) {
                    // (b) le défunt était seulement nue-propriétaire
                    // NUE-PROPRIETE
                    // retirer le défunt de la liste des nue-propriétaires
                    // et répartir sa part sur ses héritiers selon l'option retenue par le conjoint survivant
                    transferBareOwnership(of                 : decedentName,
                                          toSpouse           : spouseName,
                                          toChildren         : chidrenNames,
                                          spouseFiscalOption : spouseFiscalOption)

                } // (c) sinon on ne fait rien

            } else if let chidrenNames = chidrenNames {
                // (2) il n'y a pas de conjoint survivant
                //     mais il y a des enfants survivants
                // NU-PROPRIETE
                // la nue-propriété du défunt est transmises aux enfants héritiers
                try? bareOwners.replace(thisOwner: decedentName, with: chidrenNames)
                // USUFRUIT
                // l'usufruit rejoint la nue-propriété cad que les nues-propriétaires
                // deviennent PP et le démembrement disparaît
                isDismembered  = false
                fullOwners     = bareOwners
                usufructOwners = [ ]
                bareOwners     = [ ]
            } // (3) sinon on ne change rien car il n'y a aucun héritier
            
        } else {
            // (B) le bien n'est pas démembré
            // est-ce que le défunt fait partie des co-propriétaires ?
            if isAFullOwner(ownerName: decedentName) {
                // (1) le défunt fait partie des co-propriétaires
                // on transfert sa part de propriété aux héritiers
                if let spouseName = spouseName {
                    // (a) il y a un conjoint survivant
                    transferFullOwnership(of                 : decedentName,
                                          toSpouse           : spouseName,
                                          toChildren         : chidrenNames,
                                          spouseFiscalOption : spouseFiscalOption)
                    
                } else if let chidrenNames = chidrenNames {
                    // (b) il n'y a pas de conjoint survivant
                    // mais il y a des enfants survivants
                    try? fullOwners.replace(thisOwner: decedentName, with: chidrenNames)
                }
            } // (2) sinon on ne change rien
        }
        guard isValid else {
            customLog.log(level: .error, "'transferOwnershipOf' a généré un 'ownership' invalide")
            throw OwnershipError.invalidOwnership
        }
    }
    
    /// Retourne true si la personne est un des usufruitiers du bien
    /// - Parameter ownerName: nom de la personne
    func isAnUsufructOwner(ownerName: String) -> Bool {
        return isDismembered && usufructOwners.contains(where: { $0.name == ownerName })
    }
    
    /// Retourne true si la personne est un des nupropriétaires du bien
    /// - Parameter ownerName: nom de la personne
    func isABareOwner(ownerName: String) -> Bool {
        return isDismembered && bareOwners.contains(where: { $0.name == ownerName })
    }
    
    /// Retourne true si la personne est un des détenteurs du bien en pleine propriété
    /// - Parameter ownerName: nom de la personne
    func isAFullOwner(ownerName: String) -> Bool {
        return !isDismembered && fullOwners.contains(where: { $0.name == ownerName })
    }
    
    /// Retourne true si la personne perçoit des revenus du bien
    /// - Parameter ownerName: nom de la personne
    func receivesRevenues(ownerName: String) -> Bool {
        return isAFullOwner(ownerName: ownerName) || isAnUsufructOwner(ownerName: ownerName)
    }
}

extension Ownership: Equatable {
    static func == (lhs: Ownership, rhs: Ownership) -> Bool {
        lhs.isDismembered  == rhs.isDismembered &&
            lhs.fullOwners     == rhs.fullOwners &&
            lhs.bareOwners     == rhs.bareOwners &&
            lhs.usufructOwners == rhs.usufructOwners &&
            lhs.isValid        == rhs.isValid
    }
    
}
