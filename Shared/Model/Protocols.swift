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
    
    var items          : [Item] { get set }
    var fileNamePrefix : String { get set }
    var currentValue   : Double { get }
    subscript(idx: Int) -> Item { get set }
    
    init(fileNamePrefix: String)
    
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
    
    func namedValueTable(atEndOf: Int) -> [(name: String, value: Double)]
    
    func print()
}

// implémntation par défaut
extension NameableValuableArray {
    var currentValue      : Double {
        items.sum(atEndOf : Date.now.year)
    }
    
    subscript(idx: Int) -> Item {
        get {
            return  items[idx]
        }
        set(newValue) {
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
    
    func namedValueTable(atEndOf: Int) -> [(name: String, value: Double)] {
        var table = [(name: String, value: Double)]()
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
