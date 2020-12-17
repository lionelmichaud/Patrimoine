//
//  Demembrement.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Les droits de propriété d'un Owner

struct Owner : Codable, Hashable {
    
    // MARK: - Properties
    
    var name       : String = ""
    var fraction   : Double = 0.0 // % [0, 100]
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

// MARK: - Un tableau de Owner

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
    
    /// Transérer la propriété d'un Owner vers plusieurs autres
    /// - Parameters:
    ///   - thisOwner: celui qui sort
    ///   - theseNewOwners: ceux qui le remplacent
    mutating func replace(thisOwner           : String,
                          with theseNewOwners : [String]) {
        guard theseNewOwners.count != 0 else { return }
        
        if let ownerIdx = self.firstIndex(where: { thisOwner == $0.name }) {
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

// MARK: - La répartition des droits de propriété d'un bien entre personnes

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
//            } else {
//                fullOwners = usufructOwners
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
    
    /// Transférer l'usufruit du défunt aux nue-propriétaires
    /// - Note:
    ///   - le défunt était seulement usufruitier
    ///   - le défunt avait donné sa nue-propriété avant son décès, alors l'usufruit rejoint la nue-propriété
    ///   - cad que les nues-propriétaires deviennent PP
    /// - Parameters:
    ///   - decedentName: le nom du défunt
    ///   - chidrenNames: les enfants héritiers survivants
    private mutating func transferUsufruct(of decedentName         : String,
                                           toChildren chidrenNames : [String]?) {
        if let chidrenNames = chidrenNames {
            // on transmet l'UF aux nue-propriétaires (enfants seulement)
            // TODO: - Gérer le cas où la donnation de nue-propriété n'est pas faite qu'à des enfants
            if let ownerIdx = usufructOwners.firstIndex(where: { decedentName == $0.name }) {
                // la part d'usufruit à transmettre
                let ownerShare = usufructOwners[ownerIdx].fraction
                // on compte le nb d'enfants parmis les nue-propriétaires
                let nbChildren = bareOwners
                    .filter({ owner in
                        chidrenNames.contains(where: { $0 == owner.name })
                    })
                    .count
                // la part transmise à chauqe enfant
                let fraction = ownerShare / nbChildren.double()
                
                // on la transmet par part égales aux enfants nue-propriétaires
                chidrenNames.forEach { childName in
                    if bareOwners.contains(where: { $0.name == childName }) {
                        usufructOwners.append(Owner(name: childName, fraction: fraction))
                    }
                }
                // on supprime le défunt de la liste
                usufructOwners.remove(at: ownerIdx)
                // factoriser les parts des usufuitiers et des nue-propriétaires si nécessaire
                groupShares()
            }
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
                fatalError("pas d'option fiscale passée en paramètre de transferOwnershipOfDecedent")
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
            usufructOwners.groupShares()
            bareOwners.groupShares()
        } else {
            fullOwners.groupShares()
        }
    }
    
    /// Transférer la NP et UF  d'une assurance vie aux donataires selon la clause bénéficiaire
    ///
    /// - Parameters:
    ///   - decedentName: le nom du défunt
    ///   - spouseName: le conjoint survivant
    ///   - chidrenNames: les enfants héritiers survivants
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
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
    mutating func transferLifeInsuranceOfDecedent(of decedentName         : String,
                                                  toSpouse spouseName     : String?,
                                                  toChildren chidrenNames : [String]?,
                                                  accordingTo clause      : LifeInsuranceClause) {
        if isDismembered {
            // le capital de l'assurane vie est démembré
            if usufructOwners.contains(where: { decedentName == $0.name }) {
                // le défunt est usufruitier
                // l'usufruit rejoint la nue-propriété
                transfertLifeInsuranceUsufruct(clause: clause)
                
            } else if bareOwners.contains(where: { decedentName == $0.name }) {
                // le défunt est un nue-propriétaire
                // TODO: - traiter le cas où le capital de l'assurance vie est démembré et le défunt est nue-propriétaire
                fatalError("transferLifeInsuranceOfDecedent: cas non traité (capital démembré et le défunt est nue-propriétaire)")
            }

        } else {
            // le capital de l'assurane vie n'est pas démembré
            // le défunt est-il un des PP propriétaires du capital de l'assurance vie ?
            if fullOwners.contains(where: { decedentName == $0.name }) {
                if fullOwners.count == 1 {
                    if clause.isDismembered {
                        isDismembered = true
                        // Transférer l'usufruit et la bue-prorpiété de l'assurance vie séparement
                        transferLifeInsuranceUsufructAndBareOwnership(clause: clause)
                        
                    } else {
                        // la clause bénéficiaire de l'assurane vie n'est pas démembrée
                        // transférer le bien en PP aux donataires désignés dans la clause bénéficiaire par parts égales
                        isDismembered = false
                        transferLifeInsuranceFullOwnership(clause: clause)
                    }
                    
                } else {
                    // TODO: - traiter le cas où le capital est co-détenu en PP par plusieurs personnes
                    fatalError("transferLifeInsuranceOfDecedent: cas non traité (capital co-détenu en PP par plusieurs personnes)")
                }
            } // sinon on ne fait rien
        }
    }
    
    /// Transférer la propriété d'un bien d'un défunt vers ses héritiers en fonction de l'option
    ///  fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    mutating func transferOwnershipOfDecedent(decedentName       : String,
                                              chidrenNames       : [String]?,
                                              spouseName         : String?,
                                              spouseFiscalOption : InheritanceDonation.FiscalOption?) {
        if isDismembered {
            // le bien est démembré
            if let spouseName = spouseName {
                // il y a un conjoint survivant
                // le défunt peut être usufruitier et/ou nue-propriétaire
                
                // USUFRUIT
                if usufructOwners.contains(where: { decedentName == $0.name }) {
                    // le défunt était usufruitier
                    if bareOwners.contains(where: { decedentName == $0.name }) {
                        // le défunt était aussi nue-propriétaire
                        // le défunt possèdait encore la UF + NP et les deux sont transmis
                        // selon l'option du conjoint survivant comme une PP
                        transferUsufructAndBareOwnership(of                 : decedentName,
                                                         toSpouse           : spouseName,
                                                         toChildren         : chidrenNames,
                                                         spouseFiscalOption : spouseFiscalOption)
                        
                    } else {
                        // le défunt était seulement usufruitier
                        // le défunt avait donné sa nue-propriété avant son décès, alors l'usufruit rejoint la nue-propriété
                        // cad que les nues-propriétaires deviennent PP
                        transferUsufruct(of         : decedentName,
                                         toChildren : chidrenNames)

                    }
                } else if bareOwners.contains(where: { decedentName == $0.name }) {
                    // le défunt était seulement nue-propriétaire
                    // NUE-PROPRIETE
                    // retirer le défunt de la liste des nue-propriétaires
                    // et répartir sa part sur ses héritiers selon l'option retenue par le conjoint survivant
                    transferBareOwnership(of                 : decedentName,
                                          toSpouse           : spouseName,
                                          toChildren         : chidrenNames,
                                          spouseFiscalOption : spouseFiscalOption)

                } // sinon on ne fait rien

            } else if let chidrenNames = chidrenNames {
                // il n'y a pas de conjoint survivant
                // mais il y a des enfants survivants
                bareOwners.replace(thisOwner: decedentName, with: chidrenNames)
                // USUFRUIT
                // l'usufruit rejoint la nue-propriété cad que les nues-propriétaires
                // deviennent PP et le démembrement disparaît
                isDismembered  = false
                fullOwners     = bareOwners
                usufructOwners = [ ]
                bareOwners     = [ ]
            } // sinon on ne change rien
            
        } else {
            // le bien n'est pas démembré
            // est-ce que le défunt fait partie des co-propriétaires ?
            if isAFullOwner(ownerName: decedentName) {
                // on transfert sa part de propriété aux héritiers
                if let spouseName = spouseName {
                    // il y a un conjoint survivant
                    transferFullOwnership(of                 : decedentName,
                                          toSpouse           : spouseName,
                                          toChildren         : chidrenNames,
                                          spouseFiscalOption : spouseFiscalOption)
                    
                } else if let chidrenNames = chidrenNames {
                    // il n'y a pas de conjoint survivant
                    // mais il y a des enfants survivants
                    fullOwners.replace(thisOwner: decedentName, with: chidrenNames)
                }
            } // sinon on ne change rien
        }
    }
    
    /// Retourne true si la personne est un des usufruitier du bien
    /// - Parameter ownerName: nom de la personne
    func isAnUsufructOwner(ownerName: String) -> Bool {
        return isDismembered && usufructOwners.contains(where: { $0.name == ownerName })
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
            lhs.isvalid        == rhs.isvalid
    }
    
}
