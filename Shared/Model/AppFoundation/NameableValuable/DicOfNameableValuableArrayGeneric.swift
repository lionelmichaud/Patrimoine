//
//  DictionaryItemArray.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Dictionnaire de [Category : Table d'Item Valuable and Namable]

struct DictionaryOfNameableValuableArray <ItemCategory, ArrayOfItems>: CustomStringConvertible
where ItemCategory: PickableEnum,
      ItemCategory: Codable,
      ArrayOfItems: NameableValuableArray,
      ArrayOfItems: CustomStringConvertible {

    // properties

    var perCategory = [ItemCategory: ArrayOfItems]()

    var description: String {
        var desc = ""
        perCategory.sorted(by: \.key.displayString).forEach { cat, items in
            desc += "- \(cat.description.uppercased()):\n"
            desc += items.description
            desc += "\n"
        }
        return desc
    }

    // initialization

    /// Lire toutes les dépenses dans des fichiers au format JSON.
    /// Un fichier par catégorie de dépense.
    /// nom du fichier "Category_LifeExpense.json"
    init() {
        for category in ItemCategory.allCases {
            // charger les Items de cette catégorie à partir du fichier JSON associé à cette catégorie
            perCategory[category] = ArrayOfItems(fileNamePrefix: category.pickerString + "_")
        }
    }

    // methods

    /// Enregistrer toutes les dépenses dans des fichiers au format JSON..
    /// Un fichier par catégorie de dépense.
    func storeToFile() {
        for category in perCategory.keys {
            // encode to JSON file
            perCategory[category]?.storeItemsToFile()
        }
    }

    /// Somme de toutes les dépenses, toutes catégories confondues
    /// - Parameter atEndOf: année de calcul
    /// - Returns: dépenses totales
    func value(atEndOf: Int) -> Double {
        var sum = 0.0
        perCategory.forEach { (_, expenseArray) in
            sum += expenseArray.value(atEndOf: atEndOf)
        }
        return sum
    }

    /// Liste complète à plat de toutes les dépenses valorisées, toutes catégories confondues
    /// - Parameter atEndOf: année de calcul
    /// - Returns: liste complète à plat de toutes les dépenses
    func namedValueTable(atEndOf: Int) -> NamedValueArray {
        var table = NamedValueArray()
        perCategory.forEach { (_, expenseArray) in
            table += expenseArray.namedValueTable(atEndOf: atEndOf)
        }
        return table
    }

    /// Dictionnaire des dépenses valorisées  par catégorie
    /// - Parameter atEndOf: année de calcul
    /// - Returns: dictionnaire des dépenses par catégorie
    func namedValueTable(atEndOf: Int) -> [ItemCategory: NamedValueArray] {
        var dico = [ItemCategory: NamedValueArray]()
        for category in ItemCategory.allCases {
            if let exps = perCategory[category] {
                dico[category] = exps.namedValueTable(atEndOf: atEndOf)
            }
        }
        return dico
    }

    /// Liste des dépenses valorisées d'une catégorie donnée
    /// - Parameters:
    ///   - atEndOf: année de calcul
    ///   - inCategory: catégorie de dépenses à prendre
    /// - Returns: liste des dépenses de cette catégorie
    func namedValueTable(atEndOf: Int, inCategory: ItemCategory) -> NamedValueArray {
        if let exps = perCategory[inCategory] {
            return exps.namedValueTable(atEndOf: atEndOf)
        } else {
            return []
        }
    }
}
