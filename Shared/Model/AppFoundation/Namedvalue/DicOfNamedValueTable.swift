//
//  DicOfNamedValueTable.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Protocol Dictionnaire de NamedValueTable

protocol DictionaryOfNamedValueTable {
    associatedtype Category: PickableEnum
    
    // MARK: - Properties
    
    var name       : String { get set }
    var perCategory: [Category: NamedValueTable] { get set }
    subscript(category: Category) -> NamedValueTable? { get set }
    
    /// total de tous les actifs
    var total: Double { get }
    
    /// tableau des noms de catégories et valeurs total des actifs:  un élément par catégorie
    var summary: NamedValueTable { get }
    
    /// tableau détaillé des noms des actifs: concaténation à plat des catégories
    var namesFlatArray: [String] { get }
    
    /// tableau détaillé des valeurs des actifs: concaténation à plat des catégories
    var valuesFlatArray: [Double] { get }
    
    // MARK: - Initializers
    
    init()
    
    /// Initializer toutes les catéogires (avec des tables vides de revenu)
    init(name: String)
    
    // MARK: - Methods
    
    /// tableau  des noms des actifs: pour une seule catégorie
    func namesArray(_ inCategory: Category) -> [String]?
    
    /// tableau  des valeurs des actifs: pour une seule catégorie
    func valuesArray(_ inCategory: Category) -> [Double]?
    
    func summaryFiltredNames(with itemSelectionList: ItemSelectionList) -> [String]
    
    func summaryFiltredValues(with itemSelectionList: ItemSelectionList) -> [Double]
    
    func print(level: Int)
}

// implémntation par défaut
extension DictionaryOfNamedValueTable {
    subscript(category: Category) -> NamedValueTable? {
        get {
            return perCategory[category]
        }
        set(newValue) {
            perCategory[category] = newValue
        }
    }
    
    /// total de tous les actifs
    var total: Double {
        perCategory.reduce(.zero, { result, element in result + element.value.total })
    }
    
    /// tableau des noms de catégories et valeurs total des actifs:  un élément par catégorie
    var summary: NamedValueTable {
        var table = NamedValueTable(tableName: name)
        
        // itérer sur l'enum pour préserver l'ordre
        for category in Category.allCases {
            if let element = perCategory[category] {
                table.namedValues.append((name  : element.tableName,
                                          value : element.total))
            }
        }
        return table
    }
    
    /// tableau détaillé des noms des actifs: concaténation à plat des catégories
    var namesFlatArray: [String] {
        var headers: [String] = [ ]
        perCategory.forEach { element in
            headers += element.value.namesArray
        }
        return headers
    }
    /// tableau détaillé des valeurs des actifs: concaténation à plat des catégories
    var valuesFlatArray: [Double] {
        var values: [Double] = [ ]
        perCategory.forEach { element in
            values += element.value.valuesArray
        }
        return values
    }
    
    // MARK: - Initializers
    
    /// Initializer toutes les catéogires (avec des tables vides de revenu)
    init(name: String) {
        self.init()
        self.name = name
        for category in Category.allCases {
            perCategory[category] = NamedValueTable(tableName: category.displayString)
        }
    }
    
    // MARK: - Methods
    
    func headersCSV(_ inCategory: Category) -> String? {
        perCategory[inCategory]?.headerCSV
    }
    
    func valuesCSV(_ inCategory: Category) -> String? {
        perCategory[inCategory]?.valuesCSV
    }
    
    func namesArray(_ inCategory: Category) -> [String]? {
        perCategory[inCategory]?.namesArray
    }
    
    func valuesArray(_ inCategory: Category) -> [Double]? {
        perCategory[inCategory]?.valuesArray
    }
    
    func summaryFiltredNames(with itemSelectionList: ItemSelectionList) -> [String] {
        summary.filtredNames(with : itemSelectionList)
    }
    
    func summaryFiltredValues(with itemSelectionList: ItemSelectionList) -> [Double] {
        summary.filtredValues(with : itemSelectionList)
    }
    
    func print(level: Int = 0) {
        let h = String(repeating: StringCst.header, count: level)
        Swift.print(h + name + ":    ")
        
        for category in Category.allCases {
            perCategory[category]?.print(level: level)
        }
        
        // total des revenus
        Swift.print(h + StringCst.header + "TOTAL:", total)
    }
}
