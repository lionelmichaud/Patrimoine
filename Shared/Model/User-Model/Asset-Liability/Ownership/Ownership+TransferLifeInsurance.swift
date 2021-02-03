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
    ///
    /// - Parameters:
    ///   - clause: la clause bénéficiare de l'assurance vie
    ///
    mutating func transfertLifeInsuranceUsufruct(clause: LifeInsuranceClause) {
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
}
