//
//  OwnershipManager.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 21/04/2021.
//

import Foundation

struct OwnershipManager {
    /// Transférer la propriété d'un bien d'un défunt vers ses héritiers en fonction de l'option
    ///  fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    func transferOwnershipOf(of patrimoine      : Patrimoin,
                             decedentName       : String,
                             chidrenNames       : [String]?,
                             spouseName         : String?,
                             spouseFiscalOption : InheritanceDonation.FiscalOption?) {
        patrimoine.assets.transferOwnershipOf(decedentName       : decedentName,
                                              chidrenNames       : chidrenNames,
                                              spouseName         : spouseName,
                                              spouseFiscalOption : spouseFiscalOption)
        patrimoine.liabilities.transferOwnershipOf(decedentName : decedentName,
                                        chidrenNames            : chidrenNames,
                                        spouseName              : spouseName,
                                        spouseFiscalOption      : spouseFiscalOption)
    }
    
    /// Transférer les biens d'un défunt vers ses héritiers
    /// - Parameter year: décès dans l'année en cours
    func transferOwnershipOf(of patrimoine : Patrimoin,
                             decedent      : Person,
                             atEndOf year  : Int) {
        guard let family = Patrimoin.family else {
            fatalError("La famille n'est pas définie dans Patrimoin.transferOwnershipOf")
        }
        // rechercher un conjont survivant
        var spouseName         : String?
        var spouseFiscalOption : InheritanceDonation.FiscalOption?
        if let decedent = decedent as? Adult, let spouse = family.spouseOf(decedent) {
            if spouse.isAlive(atEndOf: year) {
                spouseName         = spouse.displayName
                spouseFiscalOption = spouse.fiscalOption
            }
        }
        // rechercher des enfants héritiers vivants
        let chidrenNames = family.chidldrenAlive(atEndOf: year)?.map { $0.displayName }
        
        // leur transférer la propriété de tous les biens détenus par le défunt
        transferOwnershipOf(of                 : patrimoine,
                            decedentName       : decedent.displayName,
                            chidrenNames       : chidrenNames,
                            spouseName         : spouseName,
                            spouseFiscalOption : spouseFiscalOption)
    }
}
