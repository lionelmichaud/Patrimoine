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
    
    /// Transférer la PP d'un copropriétaire d'un bien non démembré en la répartissant
    /// entre un usufruitier (qui récupère d'UF) et des Nue-propriétaires (qui récupèrent la NP)
    /// - Parameters:
    ///   - thisFullOwner: le PP celui qui sort
    ///   - toThisNewUsufructuary: celui qui prend l'UF
    ///   - toTheseNewBareowners: ceux qui prennent la NP
    mutating func transferFullOwnership(of thisFullOwner      : String,
                                        toThisNewUsufructuary : String,
                                        toTheseNewBareOwners  : [String]) {
        if let ownerIdx = fullOwners.firstIndex(where: { thisFullOwner == $0.name }) {
            // le bien doit être démembré
            isDismembered = true
            usufructOwners = [ ]
            bareOwners     = [ ]
            // démembrer les éventuels autres copropriétaire en PP sans réduire leurs parts
            // X% PP => X% NP + X% UF
            fullOwners.forEach { fullOwner in
                if fullOwner.name != thisFullOwner {
                    usufructOwners.append(fullOwner)
                    bareOwners.append(fullOwner)
                }
            }
            // part de PP à redistribuer
            let ownerShare = fullOwners[ownerIdx].fraction
            // UF => toThisNewUsufructuary
            usufructOwners.append(Owner(name: toThisNewUsufructuary, fraction: ownerShare))
            // NP => répartie par part égales entre les toTheseNewBareOwners
            toTheseNewBareOwners.forEach { newBareOwner in
                bareOwners.append(Owner(name: newBareOwner, fraction: ownerShare / toTheseNewBareOwners.count.double()))
            }
            fullOwners = [ ]
            
            // factoriser les parts des usufuitier et des nue-propriétaires si nécessaire
            groupShares()
        }
    }
    
    /// Transférer la PP d'un copropriétaire d'un bien non démembré en la répartissant
    /// entre un usufruitier (qui récupère la quotité disponile en PP) et des Nue-propriétaires (qui récupèrent la NP)
    /// - Parameters:
    ///   - thisFullOwner: le PP celui qui sort
    ///   - toSpouse: le conjoint survivant
    ///   - spouseShare: la quotité disponible pour le conjoint survivant
    ///   - toChildren: les enfants héritiers survivants
    mutating func transferFullOwnership(of thisFullOwner  : String,
                                        toSpouse          : String,
                                        quotiteDisponible : Double,
                                        toChildren        : [String]) {
        if let ownerIdx = fullOwners.firstIndex(where: { thisFullOwner == $0.name }) {
            // part de PP à redistribuer
            let ownerShare = fullOwners[ownerIdx].fraction
            // retirer le défunt de la liste des PP
            fullOwners.remove(at: ownerIdx)
            // alouer la quotité disponible au conjoint survivant
            fullOwners.append(Owner(name     : toSpouse,
                                    fraction : ownerShare * quotiteDisponible))
            // allouer le reste par parts égales aux enfants héritiers survivants
            toChildren.forEach { childName in
                fullOwners.append(Owner(name     : childName,
                                        fraction : ownerShare * (1.0 - quotiteDisponible) / toChildren.count.double()))
            }
            // factoriser les parts des usufuitier et des nue-propriétaires si nécessaire
            groupShares()
        }
    }
    
    /// Transférer la PP d'un copropriétaire d'un bien non démembré en la répartissant
    /// entre un usufruitier (qui récupère 1/4 en PP +3/4 en UF) et des Nue-propriétaires (qui récupèrent le reste)
    /// - Parameters:
    ///   - thisFullOwner: le PP celui qui sort
    ///   - toSpouse: le conjoint survivant
    ///   - toChildren: les enfants héritiers survivants
    ///   - shares: répartition des UF et NP entre conjoint et enfants
    mutating func transferFullOwnership(of thisFullOwner        : String,
                                        toSpouse                : String,
                                        toChildren              : [String],
                                        withThisSharing sharing : InheritanceSharing) {
        if let ownerIdx = fullOwners.firstIndex(where: { thisFullOwner == $0.name }) {
            // le bien doit être démembré
            isDismembered = true
            usufructOwners = [ ]
            bareOwners     = [ ]
            // démembrer les éventuels autres copropriétaire en PP sans réduire leurs parts
            // X% PP => X% NP + X% UF
            fullOwners.forEach { fullOwner in
                if fullOwner.name != thisFullOwner {
                    usufructOwners.append(fullOwner)
                    bareOwners.append(fullOwner)
                }
            }
            // part de PP à redistribuer
            let ownerShare = fullOwners[ownerIdx].fraction
            // redistribution de l'UF
            usufructOwners.append(Owner(name     : toSpouse,
                                        fraction : ownerShare * sharing.forSpouse.usufruct))
            toChildren.forEach { childName in
                usufructOwners.append(Owner(name     : childName,
                                            fraction : ownerShare * sharing.forChild.usufruct))
            }

            // redistribution de la NP
            bareOwners.append(Owner(name     : toSpouse,
                                    fraction : ownerShare * sharing.forSpouse.bare))
            toChildren.forEach { childName in
                bareOwners.append(Owner(name     : childName,
                                        fraction : ownerShare * sharing.forChild.bare))
            }
            
            fullOwners = [ ] // le bien est démembré

            // factoriser les parts des usufuitier et des nue-propriétaires si nécessaire
            groupShares()
        }
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
    
    mutating func transferFullOwnership(of decedentName         : String,
                                        toSpouse spouseName     : String,
                                        toChildren chidrenNames : [String]?,
                                        spouseFiscalOption      : InheritanceDonation.FiscalOption?) {
        // il y a un conoint survivant
        if let chidrenNames = chidrenNames {
            // il y a des enfants héritiers
            // selon l'option fiscale du conjoint survivant
            guard let spouseFiscalOption = spouseFiscalOption else {
                fatalError("pas d'option fiscale passée en paramètre de transferOwnershipOfDecedent")
            }
            switch spouseFiscalOption {
                case .fullUsufruct:
                    transferFullOwnership(of                    : decedentName,
                                          toThisNewUsufructuary : spouseName,
                                          toTheseNewBareOwners  : chidrenNames)
                    
                case .quotiteDisponible:
                    let shares = spouseFiscalOption.shares(nbChildren: chidrenNames.count)
                    transferFullOwnership(of                : decedentName,
                                          toSpouse          : spouseName,
                                          quotiteDisponible : shares.forSpouse.bare,
                                          toChildren        : chidrenNames)
                    
                case .usufructPlusBare:
                    let sharing = spouseFiscalOption.shares(nbChildren: chidrenNames.count)
                    transferFullOwnership(of              : decedentName,
                                          toSpouse        : spouseName,
                                          toChildren      : chidrenNames,
                                          withThisSharing : sharing)
            }
        } else {
            // il n'y pas d'enfant héritier mais un conoint survivant
            // tout revient au conjoint survivant en PP
            fullOwners = [Owner(name: spouseName, fraction: 1.0)]
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
                // il y a un conoint survivant
                // le défunt peut être usufruitier et/ou nue-propriétaire
                // USUFRUIT
                // l'usufruit rejoint la nue-propriété cad que les nues-propriétaires
                
                // NUE-PROPRIETE
                // retirer le défunt de la liste des nue-propriétaires
                // et répartir sa part sur ses enfants par parts égales
                
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
                    // il y a un conoint survivant
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
