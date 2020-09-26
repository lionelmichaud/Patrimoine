//
//  BasicStructs.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import os
import Foundation

fileprivate let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "BasicStructs")

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


// MARK: - Liste des items affichés sur un Graph et sélectionnables individuellement

typealias ItemSelection = (label: String, selected: Bool)
typealias ItemSelectionList = [ItemSelection]

extension ItemSelectionList {
    /// retourne true si la liste d'items contient l'item sélectionné
    /// - Parameters:
    ///   - name: nom de l'item recherché
    ///   - itemSelection: liste d'item
    /// - Returns: true si la liste d'items contient l'item sélectionné
    func selectionContains(_ name: String) -> Bool {
        self.contains(where: { item in
            (item.label == name && item.selected)
        })
    }
    
    /// Vérifie si une ou plusieurs catégories ont étées secltionnées dans la liste du menu
    /// - Returns: retourne TRUE si une seule catégorie sélectionnée
    func onlyOneCategorySelected () -> Bool {
        let count = self.reduce(.zero, { result, element in result + (element.selected ? 1 : 0) } )
        return count == 1
    }
    
    /// Retourne vrai si toutes les catégories de ls liste sont sélectionnées
    func allCategoriesSelected() -> Bool {
        let count = self.reduce(.zero, { result, element in result + (element.selected ? 1 : 0) } )
        return count == self.count
    }
    
    /// Retourne vrai si aucune des catégories de ls liste n'est sélectionnées
    func NoneCategorySelected() -> Bool {
        let count = self.reduce(.zero, { result, element in result + (element.selected ? 1 : 0) } )
        return count == 0
    }
    
    /// Retourne le nom de la première catégorie sélectionnée dans la liste du menu
    /// - Returns: nom de la première catégorie sélectionnée dans la liste du menu
    func firstCategorySelected () -> String? {
        if let foundSelection = self.first(where: { $0.selected }) {
            print("catégorie= \(foundSelection.label)")
            return foundSelection.label
        } else {
            customLog.log(level: .error, "firstCategorySelected/foundSelection = false : catégorie non trouvée dans le menu")
            return nil
        }
    }
    
    
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
