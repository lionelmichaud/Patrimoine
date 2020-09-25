//
//  Protocols.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: Protocol d'Item Valuable and Namable

protocol NameableValuable {
    var name: String { get }
    func value(atEndOf year: Int) -> Double
    func print()
}

extension Array where Element: NameableValuable {
    /// Somme de toutes les valeurs d'un Array
    ///
    /// Usage:
    ///
    ///     items.sum(atEndOf: 2020)
    ///
    /// - Returns: Somme de toutes les valeurs d'un Array
    func sum (atEndOf year: Int) -> Double {
        return reduce(.zero, {result, element in result + element.value(atEndOf: year)})
    }
}

// MARK: - Protocol Table d'Item Valuable and Namable

protocol NameableValuableArray: Codable {
    associatedtype Item: Codable, Identifiable, NameableValuable
    
    // MARK: - Properties
    
    var items          : [Item] { get set }
    var fileNamePrefix : String { get set }
    var currentValue   : Double { get }
    subscript(idx: Int) -> Item { get set }
    
    // MARK: - Initializers
    
    init(fileNamePrefix: String)
    
    // MARK: - Methods
    
    func storeItemsToFile(fileNamePrefix: String)
    
    mutating func move(from indexes   : IndexSet,
                       to destination : Int,
                       fileNamePrefix : String)
    
    mutating func delete(at offsets     : IndexSet,
                         fileNamePrefix : String)
    
    mutating func add(_ item         : Item,
                      fileNamePrefix : String)
    
    mutating func update(with item      : Item,
                         at index       : Int,
                         fileNamePrefix : String)
    
    func value(atEndOf: Int) -> Double
    
    func namedValueTable(atEndOf: Int) -> NamedValueArray
    
    func print()
}

// implémntation par défaut
extension NameableValuableArray {
    var currentValue      : Double {
        items.sum(atEndOf : Date.now.year)
    }
    
    subscript(idx: Int) -> Item {
        get {
            precondition((0..<items.count).contains(idx), "NameableValuableArray[] : out of bounds")
            return items[idx]
        }
        set(newValue) {
            precondition((0..<items.count).contains(idx), "NameableValuableArray[] : out of bounds")
            items[idx] = newValue
        }
    }
    
    func storeItemsToFile(fileNamePrefix: String = "") {
        // encode to JSON file
        Bundle.main.encode(self,
                           to                   : fileNamePrefix + self.fileNamePrefix + String(describing: Item.self) + ".json",
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
    
    mutating func add(_ item         : Item,
                      fileNamePrefix : String = "") {
        items.append(item)
        self.storeItemsToFile(fileNamePrefix: fileNamePrefix)
    }
    
    mutating func update(with item      : Item,
                         at index       : Int,
                         fileNamePrefix : String = "") {
        items[index] = item
        self.storeItemsToFile(fileNamePrefix: fileNamePrefix)
    }
    
    func value(atEndOf: Int) -> Double {
        items.sum(atEndOf: atEndOf)
    }
    
    func namedValueTable(atEndOf: Int) -> NamedValueArray {
        var table = NamedValueArray()
        for item in items {
            table.append((name: item.name, value: item.value(atEndOf: atEndOf)))
        }
        return table
    }
    
    func print() {
        for item in items {
            item.print()
        }
    }
    
}

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
        perCategory.reduce(.zero, { result, element in result + element.value.total } )
    }
    
    /// tableau des noms de catégories et valeurs total des actifs:  un élément par catégorie
    var summary: NamedValueTable {
        var table = NamedValueTable(name: name)
        
        // itérer sur l'enum pour préserver l'ordre
        for category in Category.allCases {
            if let element = perCategory[category] {
                table.namedValues.append((name  : element.name,
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
            perCategory[category] = NamedValueTable(name: category.displayString)
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

// MARK: - Protocol PickableEnum pour Picker d'un Enum

protocol PickableEnum: CaseIterable, Hashable {
    var pickerString: String { get }
    var displayString: String { get }
}

// implémntation par défaut
extension PickableEnum {
    // default implementation
    var displayString: String { pickerString }
}

// MARK: - Protocol PickableEnum & Identifiable pour Picker d'un Enum

protocol PickableIdentifiableEnum: PickableEnum, Identifiable { }

// MARK: - Protocol Versionable pour versionner des données

protocol Versionable {
    var version : Version { get set }
}

// MARK: - Protocol Randomizer pour générer un nombre aléatoire

protocol Randomizer {
    mutating func random() -> Double
}
