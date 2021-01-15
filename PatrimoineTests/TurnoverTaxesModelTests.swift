//
//  TurnoverTaxesModelTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 12/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class TurnoverTaxesModelTests: XCTestCase {
    static var turnoverTaxes: TurnoverTaxesModel!
    
    // MARK: Helpers
    
    override class func setUp() { // 1.
        // This is the setUp() class method.
        // It is called before the first test method begins.
        // Set up any overall initial state here.
        super.setUp()
        let testBundle = Bundle(for: TurnoverTaxesModelTests.self)
        let model = testBundle.decode(TurnoverTaxesModel.Model.self,
                                      from                 : "TurnoverTaxesModelTests.json",
                                      dateDecodingStrategy : .iso8601,
                                      keyDecodingStrategy  : .useDefaultKeys)
        TurnoverTaxesModelTests.turnoverTaxes = TurnoverTaxesModel(model: model)
    }
    
    // MARK: Tests
    
    func test_calcul_charges_totales() {
        XCTAssertEqual(20.0,
                       TurnoverTaxesModelTests.turnoverTaxes.model.total)
    }
    
    func test_calcul_net() {
        XCTAssertEqual(100.0 - 20.0,
                       TurnoverTaxesModelTests.turnoverTaxes.net(100.0))
    }
    
    func test_calcul_social_taxes() {
        XCTAssertEqual(20.0,
                       TurnoverTaxesModelTests.turnoverTaxes.socialTaxes(100.0))
    }
}
