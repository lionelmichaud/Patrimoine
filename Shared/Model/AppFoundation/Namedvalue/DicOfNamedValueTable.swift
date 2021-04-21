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
    
    /// Valeur totale de tous les items
    var total: Double { get }
    
    /// Tableau des noms de catégorie et valeurs total des items de cette catégorie. Un élément par catégorie:
    /// [Nom de la catégorie, Valeur cumulée]
    var summary: NamedValueTable { get }
    
    /// Tableau détaillé des noms des actifs: concaténation à plat des catégories
    var namesFlatArray: [String] { get }
    
    /// Tableau détaillé des valeurs des actifs: concaténation à plat des catégories
    var valuesFlatArray: [Double] { get }
    
    // MARK: - Initializers
    
    init()
    
    /// Initialiser toutes les catéogires (avec des tables vides de revenu)
    init(name: String)
    
    // MARK: - Methods
    
    /// Tableau  des noms des actifs: pour une seule catégorie
    /// - Parameter inCategory: la catégorie sélectionnée
    func namesArray(_ inCategory: Category) -> [String]?
    
    /// Tableau  des valeurs des actifs: pour une seule catégorie
    /// - Parameter inCategory: la catégorie sélectionnée
    func valuesArray(_ inCategory: Category) -> [Double]?
    
    func headersCSV(_ inCategory: Category) -> String?
    
    func valuesCSV(_ inCategory: Category) -> String?
        
    /// Noms des catégories sélectionnées dans le menu
    /// - Parameter itemSelectionList: menu
    func summaryFiltredNames(with itemSelectionList: ItemSelectionList) -> [String]
    
    /// Valeurs cumulées de chacune des catégories sélectionnées dans le menu
    /// - Parameter itemSelectionList: menu
    func summaryFiltredValues(with itemSelectionList: ItemSelectionList) -> [Double]
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
    
    /// Valeur totale de tous les items
    var total: Double {
        perCategory.reduce(.zero, { result, element in result + element.value.total })
    }
    
    /// Tableau des noms de catégorie et valeurs total des items de cette catégorie. Un élément par catégorie:
    /// [Nom de la catégorie, Valeur cumulée]
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
}
