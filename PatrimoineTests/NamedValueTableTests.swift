//
//  Test_NamedValueTable.swift
//  Tests iOS
//
//  Created by Lionel MICHAUD on 17/04/2021.
//

import XCTest
@testable import Patrimoine

class NamedValueTableTests: XCTestCase {
    static let data: NamedValueArray =
        [
            (name: "Item 1", value: 1.0),
            (name: "Item 2", value: 2.0),
            (name: "Item 3", value: 3.0),
            (name: "Item 4", value: 4.0)
        ]
    static var namedValueTable: NamedValueTable = NamedValueTable(tableName: "Titre de la table")
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        NamedValueTableTests.namedValueTable.namedValues = NamedValueTableTests.data
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_description() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        print(NamedValueTableTests.namedValueTable.description)
    }
    
    func test_total() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(10, NamedValueTableTests.namedValueTable.total)
    }
    
    func test_namesArray() {
        XCTAssertEqual([
            "Item 1",
            "Item 2",
            "Item 3",
            "Item 4"
        ], NamedValueTableTests.namedValueTable.namesArray)
    }
    
    func test_valuesArray() {
        XCTAssertEqual([
            1.0,
            2.0,
            3.0,
            4.0
        ], NamedValueTableTests.namedValueTable.valuesArray)
    }

    func test_headerCSV() {
        XCTAssertEqual("Item 1; Item 2; Item 3; Item 4; TITRE DE LA TABLE TOTAL", NamedValueTableTests.namedValueTable.headerCSV)
    }
    
    func test_valuesCSV() {
        XCTAssertEqual("1; 2; 3; 4; 10", NamedValueTableTests.namedValueTable.valuesCSV)
    }
    
    func test_filtredTableName() {
        var itemSelectionList: ItemSelectionList =
            [
                (label: "Item x", selected: true),
                (label: "Item y", selected: false),
                (label: "Titre de la table", selected: true),
                (label: "Item z", selected: true)
            ]
        XCTAssertEqual(["Titre de la table"], NamedValueTableTests.namedValueTable.filtredTableName(with: itemSelectionList))
        itemSelectionList =
            [
                (label: "Item x", selected: true),
                (label: "Item y", selected: false),
                (label: "Truc", selected: true),
                (label: "Item z", selected: true)
            ]
        XCTAssertEqual([], NamedValueTableTests.namedValueTable.filtredTableName(with: itemSelectionList))
    }
    
    func test_filtredNames() {
        var itemSelectionList: ItemSelectionList =
            [
                (label: "Item x", selected: true),
                (label: "Item y", selected: false),
                (label: "Item 3", selected: true),
                (label: "Item z", selected: true)
            ]
        XCTAssertEqual(["Item 3"], NamedValueTableTests.namedValueTable.filtredNames(with: itemSelectionList))
        itemSelectionList =
            [
                (label: "Item x", selected: true),
                (label: "Item y", selected: false),
                (label: "Truc", selected: true),
                (label: "Item z", selected: true)
            ]
        XCTAssertEqual([], NamedValueTableTests.namedValueTable.filtredNames(with: itemSelectionList))
    }
    
    func test_filtredValues() {
        var itemSelectionList: ItemSelectionList =
            [
                (label: "Item x", selected: true),
                (label: "Item y", selected: false),
                (label: "Item 3", selected: true),
                (label: "Item z", selected: true)
            ]
        XCTAssertEqual([3.0], NamedValueTableTests.namedValueTable.filtredValues(with: itemSelectionList))
        itemSelectionList =
            [
                (label: "Item x", selected: true),
                (label: "Item y", selected: false),
                (label: "Truc", selected: true),
                (label: "Item z", selected: true)
            ]
        XCTAssertEqual([], NamedValueTableTests.namedValueTable.filtredValues(with: itemSelectionList))
    }
    
    func test_filtredTableValue() {
        var itemSelectionList: ItemSelectionList =
            [
                (label: "Item x", selected: true),
                (label: "Item y", selected: false),
                (label: "Titre de la table", selected: true),
                (label: "Item z", selected: true)
            ]
        XCTAssertEqual([10.0], NamedValueTableTests.namedValueTable.filtredTableValue(with: itemSelectionList))
        itemSelectionList =
            [
                (label: "Item x", selected: true),
                (label: "Item y", selected: false),
                (label: "Truc", selected: true),
                (label: "Item z", selected: true)
            ]
        XCTAssertEqual([], NamedValueTableTests.namedValueTable.filtredTableValue(with: itemSelectionList))
    }
}
