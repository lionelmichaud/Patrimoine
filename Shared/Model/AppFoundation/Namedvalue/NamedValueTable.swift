//
//  NamedValue.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Table nommée de couples (nom, valeur)

typealias NamedValue = (name: String, value: Double)

typealias NamedValueArray = [NamedValue]

struct NamedValueTable: HasNamedValuedTable {
    
    // MARK: - Properties
    
    var tableName: String
    var namedValues = NamedValueArray()
}

extension NamedValueTable: CustomStringConvertible {
    var description: String {
        """
        Nom de la table: \(tableName)
        Valeurs de la table:
        
        """
            +
            namedValues.description
    }
}

// MARK: - Protocol de Table nommée de couples (nom, valeur)

protocol HasNamedValuedTable {

    // MARK: - Properties
    
    // nom de la table
    var tableName   : String { get set }
    // tableau des valeurs nommées inclues dans la table nommée `tableName`
    var namedValues : NamedValueArray { get set }
    // somme des valeurs du tableau `namedValues`
    var total       : Double { get }
    var namesArray  : [String] { get }
    var valuesArray : [Double] { get }
    var headerCSV   : String { get }
    var valuesCSV   : String { get }
    
    // MARK: - Methods
    
    func filtredNames(with itemSelectionList: ItemSelectionList) -> [String]
    
    func filtredValues(with itemSelectionList: ItemSelectionList) -> [Double]
    
    /// Retourne un tableau à un seul élément si le menu contient le nom de la table
    /// - Parameter itemSelectionList: menu
    /// - Returns: nom de la table si elle figure dans le menu
    func filtredTableName(with itemSelectionList: ItemSelectionList) -> [String]
    
    /// Retourne un tableau à un seul élément si le menu contient le nom de la table
    /// - Parameter itemSelectionList: menu
    /// - Returns: valeur cumulée des éléments de la table si elle figure dans le menu
    func filtredTableValue(with itemSelectionList: ItemSelectionList) -> [Double]
}

extension HasNamedValuedTable {
    var total: Double {
        namedValues.reduce(.zero, {result, element in result + element.value})
    }
    /// tableau des noms
    var namesArray: [String] {
        namedValues.map(\.name)
    }
    /// tableau des valeurs
    var valuesArray: [Double] {
        namedValues.map(\.value)
    }
    /// liste des noms CSV
    var headerCSV: String {
        namesArray
            .joined(separator: "; ") + "; " + tableName.uppercased() + " TOTAL"
    }
    /// liste des valeurs CSV
    var valuesCSV: String {
        namedValues
            .map { (namedValue: NamedValue) -> String in namedValue.value.roundedString }
            .joined(separator: "; ") + "; " + total.roundedString
    }
    
    // MARK: - Methods
    
    func filtredNames(with itemSelectionList: ItemSelectionList) -> [String] {
        namedValues
            .filter({ itemSelectionList.contains($0.name) })
            .map(\.name)
    }
    
    func filtredValues(with itemSelectionList: ItemSelectionList) -> [Double] {
        namedValues
            .filter({ itemSelectionList.contains($0.name) })
            .map(\.value)
    }
    
    func filtredTableName(with itemSelectionList: ItemSelectionList) -> [String] {
        if itemSelectionList.contains(tableName) {
            return [tableName]
        } else {
            return [String]()
        }
    }
    
    func filtredTableValue(with itemSelectionList: ItemSelectionList) -> [Double] {
        if itemSelectionList.contains(tableName) {
            return [total]
        } else {
            return [Double]()
        }
    }
}
