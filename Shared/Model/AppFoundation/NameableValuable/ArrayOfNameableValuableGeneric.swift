//
//  ItemArrayGeneric.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 22/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Table d'Item Generic Valuable and Nameable

struct ArrayOfNameableValuable<E>: Codable, Versionable where
    E: Codable,
    E: Identifiable,
    E: CustomStringConvertible,
    E: NameableValuable {

    // MARK: - Properties
    
    var items          = [E]()
    var fileNamePrefix : String?
    var version        : Version
    var currentValue   : Double {
        items.sumOfValues(atEndOf: Date.now.year)
    } // computed
    
    // MARK: - Subscript
    
    subscript(idx: Int) -> E {
        get {
            return  items[idx]
        }
        set(newValue) {
            items[idx] = newValue
        }
    }
    
    // MARK: - Initializers
    
    init(fileNamePrefix: String = "") {
        self = Bundle.main.decode(ArrayOfNameableValuable.self,
                                  from                 : fileNamePrefix + String(describing: E.self) + ".json",
                                  dateDecodingStrategy : .iso8601,
                                  keyDecodingStrategy  : .useDefaultKeys)
        self.fileNamePrefix = fileNamePrefix
    }

    init(for aClass     : AnyClass,
         fileNamePrefix : String = "") {
        let testBundle = Bundle(for: aClass)
        self = testBundle.decode(ArrayOfNameableValuable.self,
                                 from                 : fileNamePrefix + String(describing: E.self) + ".json",
                                 dateDecodingStrategy : .iso8601,
                                 keyDecodingStrategy  : .useDefaultKeys)
        self.fileNamePrefix = fileNamePrefix
    }

    // MARK: - Methods
    
    func storeItemsToFile(fileNamePrefix: String = "") {
        // encode to JSON file
        Bundle.main.encode(self,
                           to                   : fileNamePrefix + self.fileNamePrefix! + String(describing: E.self) + ".json",
                           dateEncodingStrategy : .iso8601,
                           keyEncodingStrategy  : .useDefaultKeys)
    }

    func storeItemsToFile(for aClass     : AnyClass,
                          fileNamePrefix : String = "") {
        let testBundle = Bundle(for: aClass)
        // encode to JSON file
        testBundle.encode(self,
                           to                   : fileNamePrefix + self.fileNamePrefix! + String(describing: E.self) + ".json",
                           dateEncodingStrategy : .iso8601,
                           keyEncodingStrategy  : .useDefaultKeys)
    }

    mutating func move(from indexes   : IndexSet,
                       to destination : Int,
                       fileNamePrefix : String = "") {
        items.move(fromOffsets: indexes, toOffset: destination)
        self.storeItemsToFile(fileNamePrefix: fileNamePrefix)
    }
    
    mutating func delete(at offsets     : IndexSet,
                         fileNamePrefix : String = "") {
        items.remove(atOffsets: offsets)
        self.storeItemsToFile(fileNamePrefix: fileNamePrefix)
    }
    
    mutating func add(_ item         : E,
                      fileNamePrefix : String = "") {
        items.append(item)
        self.storeItemsToFile(fileNamePrefix: fileNamePrefix)
    }
    
    mutating func update(with item      : E,
                         at index       : Int,
                         fileNamePrefix : String = "") {
        items[index] = item
        self.storeItemsToFile(fileNamePrefix: fileNamePrefix)
    }
    
    func value(atEndOf: Int) -> Double {
        items.sumOfValues(atEndOf: atEndOf)
    }
    
    func namedValueTable(atEndOf: Int) -> NamedValueArray {
        var table = NamedValueArray()
        for item in items {
            table.append((name: item.name, value: item.value(atEndOf: atEndOf)))
        }
        return table
    }
}

extension ArrayOfNameableValuable where E: Ownable {
    // MARK: - Initializers
    
    init(fileNamePrefix         : String = "",
         with personAgeProvider : PersonAgeProvider?) {
        self.init(fileNamePrefix: fileNamePrefix)
        // injecter le délégué pour la méthode family.ageOf qui par défaut est nil à la création de l'objet
        for idx in 0..<items.count {
            if let personAgeProvider = personAgeProvider {
                items[idx].ownership.setDelegateForAgeOf(delegate: personAgeProvider.ageOf)
            }
        }
    }

    init(for aClass        : AnyClass,
         fileNamePrefix    : String = "",
         with personAgeProvider : PersonAgeProvider?) {
        self.init(for            : aClass,
                  fileNamePrefix : fileNamePrefix)
        // injecter le délégué pour la méthode family.ageOf qui par défaut est nil à la création de l'objet
        for idx in 0..<items.count {
            if let personAgeProvider = personAgeProvider {
                items[idx].ownership.setDelegateForAgeOf(delegate: personAgeProvider.ageOf)
            }
        }
    }

    /// Calcule la valeur d'un bien possédée par un personne donnée à une date donnée
    /// selon la régle générale ou selon la règle de l'IFI, de l'ISF, de la succession...
    ///  - Note:
    ///  Pour l'IFI:
    ///
    ///  Foyer taxable:
    ///  - adultes + enfants non indépendants
    ///
    ///  Patrimoine taxable à l'IFI =
    ///  - tous les actifs immobiliers dont un propriétaire ou usufruitier
    ///  est un membre du foyer taxable
    ///
    ///  Valeur retenue:
    ///  - actif détenu en pleine-propriété: valeur de la part détenue en PP
    ///  - actif détenu en usufuit : valeur de la part détenue en PP
    ///  - la résidence principale faire l’objet d’une décote de 30 %
    ///  - les immeubles que vous donnez en location peuvent faire l’objet d’une décote de 10 % à 30 % environ
    ///  - en indivision : dans ce cas, ils sont imposables à hauteur de votre quote-part minorée d’une décote de l’ordre de 30 % pour tenir compte des contraintes liées à l’indivision)
    ///
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - year: date d'évaluation
    ///   - evaluationMethod: méthode d'évaluation de la valeure des bien
    /// - Returns: valeur du bien possédée (part d'usufruit + part de nue-prop)
    func ownedValue(by ownerName     : String,
                    atEndOf year     : Int,
                    evaluationMethod : EvaluationMethod) -> Double {
        items.sumOfOwnedValues(by               : ownerName,
                               atEndOf          : year,
                               evaluationMethod : evaluationMethod)
    }
}

extension ArrayOfNameableValuable: CustomStringConvertible {
    var description: String {
        items.reduce("") { r, item in
            r + item.description + "\n\n"
        }
    }
}
