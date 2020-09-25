//
//  ItemArrayGeneric.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 22/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Table d'Item Generic Valuable and Namable

struct ItemArray<E>: Codable where E: Codable, E: Identifiable, E: NameableValuable  {
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
        self = Bundle.main.decode(ItemArray.self,
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

