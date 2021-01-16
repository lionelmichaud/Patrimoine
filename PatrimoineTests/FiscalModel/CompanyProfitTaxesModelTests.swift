//
//  CompanyProfitTaxesModelTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 13/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class CompanyProfitTaxesModelTests: XCTestCase {

    static var companyProfitTaxes: CompanyProfitTaxesModel!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = CompanyProfitTaxesModel.Model(for: CompanyProfitTaxesModelTests.self,
                                                  from                 : "CompanyProfitTaxesModelTest.json",
                                                  dateDecodingStrategy : .iso8601,
                                                  keyDecodingStrategy  : .useDefaultKeys)
        CompanyProfitTaxesModelTests.companyProfitTaxes = CompanyProfitTaxesModel(model: model)
    }
    
    // MARK: Tests
    
    func test_calcul_IS() {
        // given
        var profit = 100.0
        // when
        var IS = CompanyProfitTaxesModelTests.companyProfitTaxes.IS(profit)
        // then
        XCTAssertEqual(20.0, IS)

        // given
        profit = -100.0
        // when
        IS = CompanyProfitTaxesModelTests.companyProfitTaxes.IS(profit)
        // then
        XCTAssertEqual(0.0, IS)
    }

    func test_calcul_net() {
        // given
        var profit = 100.0
        // when
        var net = CompanyProfitTaxesModelTests.companyProfitTaxes.net(profit)
        // then
        XCTAssertEqual(80.0, net)

        // given
        profit = -100.0
        // when
        net = CompanyProfitTaxesModelTests.companyProfitTaxes.net(profit)
        // then
        XCTAssertEqual(0.0, net)
    }
}
