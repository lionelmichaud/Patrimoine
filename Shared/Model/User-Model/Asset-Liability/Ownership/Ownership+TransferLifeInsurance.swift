//
//  Ownership+TransferLifeInsurance.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 17/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

extension Ownership {
    
    /// Transférer l'usufruit qui rejoint la nue-propriété
    mutating func transfertLifeInsuranceUsufruct() {
        guard bareOwners.isNotEmpty else {
            fatalError("transfertLifeInsuranceUsufruct: Aucun nue-propriétaire à qui transmettre l'usufruit de l'assurance vie")
        }
        isDismembered = false
        fullOwners = []
        // chaque nue-propriétaire devient PP de sa propre part
        bareOwners.forEach {bareOwner in
            fullOwners.append(Owner(name: bareOwner.name, fraction: bareOwner.fraction))
        }
        bareOwners     = []
        usufructOwners = []
    }
    
    /// Transférer l'usufruit et la nue-prorpiété de l'assurance vie séparement
    /// aux bénéficiaires selon la clause bénéficiaire
    ///
    /// - Parameters:
    ///   - clause: la clause bénéficiare de l'assurance vie
    ///
    /// - Warning:
    ///   - le cas de plusieurs usufruitiers bénéficiaires n'est pas traité
    ///   - le cas de parts non égales entre bénéficiaires en PP n'est pas traité
    ///
    mutating func transferLifeInsuranceUsufructAndBareOwnership(clause: LifeInsuranceClause) {
        guard clause.bareRecipients.isNotEmpty else {
            fatalError("transferLifeInsuranceUsufructAndBareOwnership: Aucun nue-propriétaire désigné dans la clause bénéficiaire démembrée de l'assurance vie")
        }
        guard clause.usufructRecipient.isNotEmpty else {
            fatalError("transferLifeInsuranceUsufructAndBareOwnership: Aucun usufruitier désigné dans la clause bénéficiaire démembrée de l'assurance vie")
        }
        isDismembered = true
        self.fullOwners = []
        // un seul usufruitier
        self.usufructOwners = [Owner(name     : clause.usufructRecipient,
                                     fraction : 100)]

        // TODO: - traiter le cas des parts non égales chez les donataires désignés dans une clause bénéficiaire
        // répartition des parts de NP entre bénéficiaires en NP
        let nbOfRecipients = clause.bareRecipients.count
        let share          = 100.0 / nbOfRecipients.double()
        
        self.bareOwners = []
        // plusieurs nue-propriétaires possible
        clause.bareRecipients.forEach { recipient in
            self.bareOwners.append(Owner(name: recipient, fraction: share))
        }
    }
    
    /// Transférer la PP de l'assurance vie aux donataires désignés dans la clause bénéficiaire par parts égales
    ///
    /// - Parameters:
    ///   - clause: la clause bénéficiare de l'assurance vie
    ///
    /// - Warning: le cas de parts non égales entre bénéficiaires en PP n'est pas traité
    ///
    mutating func transferLifeInsuranceFullOwnership(clause: LifeInsuranceClause) {
        guard clause.fullRecipients.isNotEmpty else {
            fatalError("Aucun bénéficiaire dans la clause bénéficiaire de l'assurance vie")
        }
        // TODO: - traiter le cas des parts non égales chez les donataires désignés dans une clause bénéficiaire
        // répartition des parts entre bénéficiaires en PP
        let nbOfRecipients = clause.fullRecipients.count
        let share          = 100.0 / nbOfRecipients.double()
        
        self.fullOwners     = []
        self.bareOwners     = []
        self.usufructOwners = []
        clause.fullRecipients.forEach { recipient in
            self.fullOwners.append(Owner(name: recipient, fraction: share))
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
            customLogOwnership.log(level: .error, "'transferOwnershipOf' a généré un 'ownership' invalide")
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
            customLogOwnership.log(level: .error, "'transferOwnershipOf' a généré un 'ownership' invalide")
            throw OwnershipError.invalidOwnership
        }
    }
}
