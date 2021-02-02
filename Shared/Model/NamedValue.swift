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

struct NamedValueTable {
    
    // MARK: - Properties
    
    var name: String
    var namedValues = NamedValueArray()
    
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

// MARK: - NamedValueTable avec résumé global
struct NamedValueTableWithSummary {
    
    // MARK: - Properties
    
    let name              : String
    var namedValueTable   : NamedValueTable
    
    var summary           : NamedValueTable { // un seul élément
        var table = NamedValueTable(name: name)
        table.namedValues.append((name  : name,
                                  value : namedValueTable.total))
        return table
    }
    
    // MARK: - Initializers
    
    internal init(name: String) {
        self.name = name
        self.namedValueTable = NamedValueTable(name: name)
    }
    
    // MARK: - Methods
    
    /// liste des noms CSV
    var headerCSV: String {
        namedValueTable.headerCSV
    }
    /// liste des valeurs CSV
    var valuesCSV: String {
        namedValueTable.valuesCSV
    }
    
    func summaryFiltredNames(with itemSelectionList: ItemSelectionList) -> [String] {
        summary.filtredNames(with: itemSelectionList)
    }
    
    func summaryFiltredValues(with itemSelectionList: ItemSelectionList) -> [Double] {
        summary.filtredValues(with: itemSelectionList)
    }
}
