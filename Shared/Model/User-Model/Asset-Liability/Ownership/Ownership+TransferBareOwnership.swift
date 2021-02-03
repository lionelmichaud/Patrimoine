//
//  Ownership+transferBareOwnership.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 14/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

extension Ownership {
    
    /// Transférer la NP du défunt aux enfants héritiers par part égales
    /// on la transmet par part égales aux enfants nue-propriétaires
    mutating func transferBareOwnership(of decedentName         : String,
                                        toChildren chidrenNames : [String]) {
        if let ownerIdx = bareOwners.firstIndex(where: { decedentName == $0.name }) {
            // la part de NP à transmettre
            let ownerShare = bareOwners[ownerIdx].fraction
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
                    bareOwners.append(Owner(name: childName, fraction: fraction))
                }
            }
        }
    }
    
    /// Transférer la quotité disponible de la NP du défunt au conjoint et le reste aux enfants
    mutating func transferBareOwnership(of decedentName         : String,
                                        toSpouse spouseName     : String,
                                        toChildren chidrenNames : [String],
                                        quotiteDisponible       : Double) {
        if let ownerIdx = bareOwners.firstIndex(where: { decedentName == $0.name }) {
            // part de NP à redistribuer
            let ownerShare = bareOwners[ownerIdx].fraction
            // retirer le défunt de la liste des NP
            bareOwners.remove(at: ownerIdx)
            // alouer la quotité disponible au conjoint survivant
            bareOwners.append(Owner(name     : spouseName,
                                    fraction : ownerShare * quotiteDisponible))
            // allouer le reste par parts égales aux enfants héritiers survivants
            chidrenNames.forEach { childName in
                bareOwners.append(Owner(name     : childName,
                                        fraction : ownerShare * (1.0 - quotiteDisponible) / chidrenNames.count.double()))
            }
        }
    }
    
    /// Transférer la NP d'un copropriétaire d'un bien démembré en la répartissant
    /// entre un usufruitier (qui en récupère 1/4) et des Nue-propriétaires (qui récupèrent le reste)
    mutating func transferBareOwnership(of decedentName         : String,
                                        toSpouse spouseName     : String,
                                        toChildren chidrenNames : [String],
                                        withThisSharing sharing : InheritanceSharing) {
        
        if let ownerIdx = bareOwners.firstIndex(where: { decedentName == $0.name }) {
            // part de NP à redistribuer
            let ownerShare = bareOwners[ownerIdx].fraction
            // retirer le défunt de la liste des NP
            bareOwners.remove(at: ownerIdx)
            // alouer la part de NP au conjoint survivant
            bareOwners.append(Owner(name     : spouseName,
                                    fraction : ownerShare * sharing.forSpouse.bare))
            // allouer le reste par parts égales aux enfants héritiers survivants
            chidrenNames.forEach { childName in
                bareOwners.append(Owner(name     : childName,
                                        fraction : ownerShare * sharing.forChild.bare))
            }
        }
    }
    
    /// Transférer la nue-propriété du défunt aux nue-propriétaires
    /// - Note:
    ///   - le défunt était seulement nue-propriétaire
    ///   - retirer le défunt de la liste des nue-propriétaires
    ///   - et répartir sa part sur ses héritiers selon l'option retenue par le conjoint survivant
    /// - Parameters:
    ///   - decedentName: le nom du défunt
    ///   - spouseName: le conjoint survivant
    ///   - chidrenNames: les enfants héritiers survivants
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    mutating func transferBareOwnership(of decedentName         : String,
                                        toSpouse spouseName     : String,
                                        toChildren chidrenNames : [String]?,
                                        spouseFiscalOption      : InheritanceDonation.FiscalOption?) {
        if let chidrenNames = chidrenNames {
            // il y a des enfants héritiers
            // selon l'option fiscale du conjoint survivant
            guard let spouseFiscalOption = spouseFiscalOption else {
                fatalError("pas d'option fiscale passée en paramètre de transferOwnershipOf")
            }
            switch spouseFiscalOption {
                case .fullUsufruct:
                    // transmettre la NP du défunt aux enfants héritiers par part égales
                    // on la transmet par part égales aux enfants nue-propriétaires
                    transferBareOwnership(of         : decedentName,
                                          toChildren : chidrenNames)
                    
                case .quotiteDisponible:
                    // transmettre la quotité disponible de la NP du défunt au conjoint et le reste aux enfants
                    let shares = spouseFiscalOption.shares(nbChildren: chidrenNames.count)
                    transferBareOwnership(of                : decedentName,
                                          toSpouse          : spouseName,
                                          toChildren        : chidrenNames,
                                          quotiteDisponible : shares.forSpouse.bare)
                    
                case .usufructPlusBare:
                    // Transférer la NP d'un copropriétaire d'un bien démembré en la répartissant
                    // entre un usufruitier (qui en récupère 1/4) et des Nue-propriétaires (qui récupèrent le reste)
                    let sharing = spouseFiscalOption.shares(nbChildren: chidrenNames.count)
                    transferBareOwnership(of              : decedentName,
                                          toSpouse        : spouseName,
                                          toChildren      : chidrenNames,
                                          withThisSharing : sharing)
            }
            
        } else {
            // il n'y pas d'enfant héritier mais un conjoint survivant
            // la NP revient au conjoint survivant en PP
            // on transmet la NP au conjoint survivant
            if let ownerIdx = bareOwners.firstIndex(where: { decedentName == $0.name }) {
                let ownerShare = bareOwners[ownerIdx].fraction
                // la part de nue-propriété à transmettre
                bareOwners.append(Owner(name: spouseName, fraction: ownerShare))
                // on supprime le défunt de la liste
                bareOwners.remove(at: ownerIdx)
            }
        }
        
        // factoriser les parts des usufuitier et des nue-propriétaires si nécessaire
        groupShares()
    }
}
