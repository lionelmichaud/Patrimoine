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
    
    override class func setUp() {
        super.setUp()
        let model = TurnoverTaxesModel.Model(for: TurnoverTaxesModelTests.self,
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
