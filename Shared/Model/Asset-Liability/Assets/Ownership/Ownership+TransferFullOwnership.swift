//
//  Ownership+TransferFullOwnership.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 14/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

extension Ownership {
    /// Transférer la PP d'un copropriétaire d'un bien non démembré en la répartissant
    /// entre un usufruitier (qui récupère d'UF) et des Nue-propriétaires (qui récupèrent la NP)
    /// - Parameters:
    ///   - thisFullOwner: le PP celui qui sort
    ///   - toThisNewUsufructuary: celui qui prend l'UF
    ///   - toTheseNewBareowners: ceux qui prennent la NP
    private mutating func transferFullOwnership(of thisFullOwner      : String,
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
            
            fullOwners = [ ] // le bien est démembré
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
        }
    }
    
    /// Transférer la PP d'un copropriétaire d'un bien non démembré à ses héritiers selon l'option retnue par le conjoint survivant
    /// - Parameters:
    ///   - decedentName: le nom du défunt
    ///   - spouseName: le conjoint survivant
    ///   - chidrenNames: les enfants héritiers survivants
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
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
            // factoriser les parts des usufuitier et des nue-propriétaires si nécessaire
            groupShares()

        } else {
            // il n'y pas d'enfant héritier mais un conjoint survivant
            // tout revient au conjoint survivant en PP
            fullOwners = [Owner(name: spouseName, fraction: 1.0)]
        }
    }
}
