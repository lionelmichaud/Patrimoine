//
//  EconomyModelTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class EconomyModelTests: XCTestCase {
    
    func test_loading_from_main_bundle() throws {
        XCTAssertNoThrow(Economy.Model(), "Failed to read model from Main Bundle ")
    }
    
    func test_saving_to_test_bundle() throws {
        let model = Economy.RandomizersModel()
        model.saveToBundle(for: EconomyModelTests.self,
                           to: "EconomyModelConfig.json",
                           dateEncodingStrategy: .iso8601,
                           keyEncodingStrategy: .useDefaultKeys)
    }

//    func Générer_les_nombres_aléatoires() {
//        var model = Economy.Model()
//        var sample1 = model.randomizers.next
//    }
}
