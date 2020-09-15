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
        values.reduce(.zero, {result, element in result + element.value})
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

/// retourne true si la liste d'items contient l'item sélectionné
/// - Parameters:
///   - name: nom de l'item recherché
///   - itemSelection: liste d'item
/// - Returns: true si la liste d'items contient l'item sélectionné
func selectionContains(_ name: String, itemSelection: [(label: String, selected: Bool)]) -> Bool {
    itemSelection.contains(where: { (label: String, selected: Bool) in (label == name && selected) })
}

struct Version: Codable {
    let version : String?
    let date    : Date?
    let comment : String?
    var major   : Int? {
        return nil
    }
    var minor    : Int? {
        return nil
    }
    static func toVersion(major: Int,
                          minor: Int) -> String {
        return String(major) + "." + String(minor)
    }
}
