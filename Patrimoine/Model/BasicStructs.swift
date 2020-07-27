//
//  BasicStructs.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Table nommée de couples (nom, valeur)

struct NamedValueTable {
    
    // properties
    
    var name: String
    var values = [(name: String, value: Double)]()
    var total: Double {
        return values.reduce(.zero, {result, element in result + element.value})
    }
    // tableau des noms
    var headersArray: [String] {
        values.map(\.name)
    }
    // tableau des valeurs
    var valuesArray: [Double] {
        values.map(\.value)
    }
    // liste des noms CSV
    var headerCSV: String {
        headersArray.joined(separator: "; ") + "; " + name
    }
    // liste des valeurs CSV
    var valuesCSV: String {
        values.map { (value: (name: String, value: Double)) -> String in value.value.roundedString }
            .joined(separator: "; ") + "; " + total.roundedString
    }
    
    // methods
    
    func filtredHeaders(itemSelection: [(label: String, selected: Bool)]) -> [String] {
        values.filter({ selectionContains($0.name, itemSelection: itemSelection) }).map(\.name)
    }
    
    func filtredValues(itemSelection: [(label: String, selected: Bool)]) -> [Double] {
        values.filter({ selectionContains($0.name, itemSelection: itemSelection) }).map(\.value)
    }
    
    func print(level: Int = 0) {
        let h = String(repeating: StringCst.header, count: level)
        Swift.print(h + name)
        Swift.print(h + StringCst.header + "valeurs: ", values, "total: ", total)
    }
}

/// <#Description#>
struct AlertData: Identifiable {
    var id = UUID() // Conform to Identifiable
    let title: String
    let message: String
}

/// <#Description#>
/// - Parameters:
///   - name: <#name description#>
///   - itemSelection: <#itemSelection description#>
/// - Returns: <#description#>
func selectionContains(_ name: String, itemSelection: [(label: String, selected: Bool)]) -> Bool {
    itemSelection.contains(where: { (label: String, selected: Bool) in (label == name && selected) })
}
