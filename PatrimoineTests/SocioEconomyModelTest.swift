//
//  SocioEconomyModelTest.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 16/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class SocioEconomyModelTest: XCTestCase {

    func test_loading_from_main_bundle() throws {
        XCTAssertNoThrow(SocioEconomy.Model().initialized(), "Failed to read model from Main Bundle ")
    }
    
    func test_saving_to_test_bundle() throws {
        let model = SocioEconomy.Model().initialized()
        model.saveToBundle(for: SocioEconomyModelTest.self,
                           to: "SocioEconomyModelConfig.json",
                           dateEncodingStrategy: .iso8601,
                           keyEncodingStrategy: .useDefaultKeys)
    }
    
    func test_next() {
        var model = SocioEconomy.Model().initialized()
        let dico = model.next()
        
        XCTAssertNotNil(dico[.expensesUnderEvaluationrate])
        XCTAssertNotNil(dico[.nbTrimTauxPlein])
        XCTAssertNotNil(dico[.pensionDevaluationRate])
    }
}
