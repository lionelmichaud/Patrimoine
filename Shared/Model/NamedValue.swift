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

protocol HasNamedValuedTable {

    // MARK: - Properties
    
    var name: String { get set }
    var namedValues: NamedValueArray { get set }
    var total: Double { get }
    var namesArray: [String] { get }
    var valuesArray: [Double] { get }
    var headerCSV: String { get }
    var valuesCSV: String { get }
    
    // MARK: - Methods
    
    func filtredNames(with itemSelectionList: ItemSelectionList) -> [String]
    func filtredValues(with itemSelectionList: ItemSelectionList) -> [Double]
    func print(level: Int)
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
        namesArray.joined(separator: "; ") + "; " + name.uppercased() + " TOTAL"
    }
    /// liste des valeurs CSV
    var valuesCSV: String {
        namedValues.map { (namedValue: NamedValue) -> String in namedValue.value.roundedString }
            .joined(separator: "; ") + "; " + total.roundedString
    }
    
    // MARK: - Methods
    
    func filtredNames(with itemSelectionList: ItemSelectionList) -> [String] {
        namedValues.filter({ itemSelectionList.selectionContains($0.name) }).map(\.name)
    }
    
    func filtredValues(with itemSelectionList: ItemSelectionList) -> [Double] {
        namedValues.filter({ itemSelectionList.selectionContains($0.name) }).map(\.value)
    }
    
    func print(level: Int = 0) {
        let h = String(repeating: StringCst.header, count: level)
        Swift.print(h + name)
        Swift.print(h + StringCst.header + "valeurs: ", namedValues, "total: ", total)
    }
}

struct NamedValueTable: HasNamedValuedTable {
    
    // MARK: - Properties
    
    var name: String
    var namedValues = NamedValueArray()
}

// MARK: - NamedValueTable avec résumé global
struct NamedValueTableWithSummary: HasNamedValuedTable {
    
    // MARK: - Properties
    
    var name: String
    var namedValues = NamedValueArray()
    
    var summary: NamedValue { // un seul élément
        (name  : name,
         value : total)
    }
    
    func summaryFiltredNames(with itemSelectionList: ItemSelectionList) -> [String] {
        if itemSelectionList.selectionContains(name) {
            return [name]
        } else {
            return [String]()
        }
    }
    
    func summaryFiltredValues(with itemSelectionList: ItemSelectionList) -> [Double] {
        if itemSelectionList.selectionContains(name) {
            return [summary.value]
        } else {
            return [Double]()
        }
    }
}
