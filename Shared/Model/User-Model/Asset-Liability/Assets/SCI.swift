//
//  SCI.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Société Civile Immobilière (SCI)
struct SCI {
    
    // MARK: - Properties

    var name        : String
    var note        : String
    var scpis       : ScpiArray
    var bankAccount : Double
    
    // MARK: - Initializers
    
    internal init(name              : String,
                  note              : String,
                  personAgeProvider : PersonAgeProvider?) {
        self.name  = name
        self.note  = note
        self.scpis = ScpiArray(fileNamePrefix    : "SCI_",
                               personAgeProvider : personAgeProvider)
        self.bankAccount = 0
    }
    
    // MARK: - Methods
    
    /// Calls the given closure on each element in the sequence in the same order as a for-in loop
    func forEachOwnable(_ body: (Ownable) throws -> Void) rethrows {
        try scpis.items.forEach(body)
    }
    
    /// Transférer la propriété d'un bien d'un défunt vers ses héritiers en fonction de l'option
    ///  fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    mutating func transferOwnershipOf(decedentName       : String,
                                      chidrenNames       : [String]?,
                                      spouseName         : String?,
                                      spouseFiscalOption : InheritanceDonation.FiscalOption?) {
        for idx in 0..<scpis.items.count {
            try! scpis.items[idx].ownership.transferOwnershipOf(
                decedentName       : decedentName,
                chidrenNames       : chidrenNames,
                spouseName         : spouseName,
                spouseFiscalOption : spouseFiscalOption)
        }
    }
}

extension SCI: CustomStringConvertible {
    var description: String {
        """
        SCI: \(name)
        - Note:
        \(note.withPrefixedSplittedLines("    "))
        \(scpis.description.withPrefixedSplittedLines("  "))
        """
    }
}
