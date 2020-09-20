//
//  ItemArrayGeneric.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 22/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Protocol Dictionnaire [Catégorie : Table d'Item Valuable and Namable]

protocol NamableValuableItemArray: Codable {
    associatedtype Item: Codable, Identifiable, NamableValuable
    
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
extension NamableValuableItemArray {
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

struct ArrayOfNamedValuedItem<E>: Codable where E: Codable, E: Identifiable, E: NamableValuable  {
    var items = [E]()
    var fileNamePrefix : String
    var currentValue   : Double {
        items.sum(atEndOf: Date.now.year)
    }
    subscript(idx: Int) -> E {
        get {
            return  items[idx]
        }
        set(newValue) {
            items[idx] = newValue
        }
    }
    
    init(fileNamePrefix: String = "") {
        self = Bundle.main.decode(ArrayOfNamedValuedItem.self,
                                  from                 : fileNamePrefix + String(describing: E.self) + ".json",
                                  dateDecodingStrategy : .iso8601,
                                  keyDecodingStrategy  : .useDefaultKeys)
    }
    
    func storeItemsToFile(fileNamePrefix: String = "") {
        // encode to JSON file
        Bundle.main.encode(self,
                           to                   : fileNamePrefix + self.fileNamePrefix + String(describing: E.self) + ".json",
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
    
    mutating func add(_ item         : E,
                      fileNamePrefix : String = "") {
        items.append(item)
        self.storeItemsToFile(fileNamePrefix: fileNamePrefix)
    }
    
    mutating func update(with item      : E,
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

