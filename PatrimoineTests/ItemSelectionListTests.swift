//
//  ItemSelectionListTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 17/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class ItemSelectionListTests: XCTestCase {
    static let data: ItemSelectionList =
        [
            (label: "Item 1", selected: true),
            (label: "Item 2", selected: false),
            (label: "Item 3", selected: true),
            (label: "Item 4", selected: true)
        ]
    static var itemSelectionList = ItemSelectionList()
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        ItemSelectionListTests.itemSelectionList = ItemSelectionListTests.data
    }
    
    func test_description() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        print(ItemSelectionListTests.itemSelectionList.description)
    }
    
    func test_contains() {
        XCTAssertTrue(ItemSelectionListTests.itemSelectionList.contains("Item 1"))
        XCTAssertTrue(ItemSelectionListTests.itemSelectionList.contains("Item 4"))
        XCTAssertFalse(ItemSelectionListTests.itemSelectionList.contains("Item X"))
    }
    
    func test_onlyOneCategorySelected() {
        XCTAssertFalse(ItemSelectionListTests.itemSelectionList.onlyOneCategorySelected())
        ItemSelectionListTests.itemSelectionList[2].selected = false
        ItemSelectionListTests.itemSelectionList[3].selected = false
        XCTAssertTrue(ItemSelectionListTests.itemSelectionList.onlyOneCategorySelected())
    }
    
    func test_allCategoriesSelected() {
        XCTAssertFalse(ItemSelectionListTests.itemSelectionList.allCategoriesSelected())
        ItemSelectionListTests.itemSelectionList[1].selected = true
        XCTAssertTrue(ItemSelectionListTests.itemSelectionList.allCategoriesSelected())
    }
    
    func test_noneCategorySelected() {
        XCTAssertFalse(ItemSelectionListTests.itemSelectionList.noneCategorySelected())
        ItemSelectionListTests.itemSelectionList[0].selected = false
        ItemSelectionListTests.itemSelectionList[2].selected = false
        ItemSelectionListTests.itemSelectionList[3].selected = false
        XCTAssertTrue(ItemSelectionListTests.itemSelectionList.noneCategorySelected())
    }

    func test_firstCategorySelected() {
        XCTAssertEqual("Item 1", ItemSelectionListTests.itemSelectionList.firstCategorySelected())
        ItemSelectionListTests.itemSelectionList[0].selected = false
        ItemSelectionListTests.itemSelectionList[1].selected = false
        ItemSelectionListTests.itemSelectionList[2].selected = false
        ItemSelectionListTests.itemSelectionList[3].selected = false
        XCTAssertEqual(nil, ItemSelectionListTests.itemSelectionList.firstCategorySelected())
    }
    
}
