//
//  NameableValuableArrayTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 17/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class NameableValuableArrayTests: XCTestCase {
    static let names: [String] =
        [
            "Item 1",
            "Item 2",
            "Item 3",
            "Item 4"
        ]
    static var tableNV = [Item]()
    
    struct Item: NameableValuable, Identifiable, Codable {
        var id   = UUID()
        var name : String
        
        func value(atEndOf year: Int) -> Double {
            Double(year)
        }
    }
    
    struct TableOfItems: NameableValuableArray {
        var items: [Item]
        
        init(fileNamePrefix: String) {
            self.items = NameableValuableArrayTests.names.map { Item(name: fileNamePrefix + $0) }
        }
        init(for aClass: AnyClass, fileNamePrefix: String) {
            self.init(fileNamePrefix: fileNamePrefix)
        }
    }
    
    static var tableOfItems = TableOfItems(fileNamePrefix: "Test_")
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        NameableValuableArrayTests.tableNV = NameableValuableArrayTests.names.map { Item(name: $0) }
        NameableValuableArrayTests.tableOfItems = TableOfItems(fileNamePrefix: "Test_")
    }
    
    func test_description() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        print(NameableValuableArrayTests.tableNV.description)
    }
    
    func test_sumOfValues() {
        let year = 2020
        XCTAssertEqual(Double(year * NameableValuableArrayTests.names.count),
                       NameableValuableArrayTests.tableNV.sumOfValues(atEndOf: year))
    }
    
    func test_value() {
        let year = 2020
        XCTAssertEqual(Double(year * NameableValuableArrayTests.names.count),
                       NameableValuableArrayTests.tableOfItems.value(atEndOf: year))
    }
    
    func test_namedValueTable() {
        let year = 2020
        XCTAssertEqual(Double(year * NameableValuableArrayTests.names.count),
                       NameableValuableArrayTests.tableOfItems.value(atEndOf: year))
        XCTAssertEqual(Double(Date.now.year * NameableValuableArrayTests.names.count),
                       NameableValuableArrayTests.tableOfItems.currentValue)
        XCTAssertEqual("Test_Item 2",
                       NameableValuableArrayTests.tableOfItems[1].name)
        
        XCTAssertEqual(2024,
                       NameableValuableArrayTests.tableOfItems[1].value(atEndOf: 2024))

        let namedValueArray = NameableValuableArrayTests.tableOfItems.namedValueTable(atEndOf: year)
        XCTAssertEqual(Double(year * NameableValuableArrayTests.names.count),
                       namedValueArray.sum(for: \.value))
        
        XCTAssertEqual("Test_Item 2",
                       namedValueArray[1].name)
    }
}
