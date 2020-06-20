//
//  ItemArrayGeneric.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 22/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct ItemArray<E: Codable>: Codable where E: NameableAndValueable, E: Identifiable  {
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
    
    func storeItemsToFile() {
        // encode to JSON file
        Bundle.main.encode(self,
                           to                   : fileNamePrefix + String(describing: E.self) + ".json",
                           dateEncodingStrategy : .iso8601,
                           keyEncodingStrategy  : .useDefaultKeys)
    }
    
    mutating func move(from indexes: IndexSet, to destination: Int) {
        items.move(fromOffsets: indexes, toOffset: destination)
        self.storeItemsToFile()
    }
    
    mutating func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        self.storeItemsToFile()
    }
    
    mutating func add(_ item: E) {
        items.append(item)
        self.storeItemsToFile()
    }
    
    mutating func update(with item: E, at index: Int) {
        items[index] = item
        self.storeItemsToFile()
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
}

