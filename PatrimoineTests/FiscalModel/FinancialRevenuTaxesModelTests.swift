//
//  FinancialRevenuTaxesModelTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 12/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class FinancialRevenuTaxesModelTests: XCTestCase {
    
    static var financialRevenuTaxes: FinancialRevenuTaxesModel!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = FinancialRevenuTaxesModel.Model(for: FinancialRevenuTaxesModelTests.self,
                                                    from                 : nil,
                                                    dateDecodingStrategy : .iso8601,
                                                    keyDecodingStrategy  : .useDefaultKeys)
        FinancialRevenuTaxesModelTests.financialRevenuTaxes = FinancialRevenuTaxesModel(model: model)
    }
    
    // MARK: Tests
    
    func test_calcul_charges_totales() {
        XCTAssertEqual(0.5 + 9.5 + 7.5,
                       FinancialRevenuTaxesModelTests.financialRevenuTaxes.model.total)
        XCTAssert(FinancialRevenuTaxesModelTests.financialRevenuTaxes.model.total.isApproximatelyEqual(to: 0.5 + 9.5 + 7.5,
                                                                                                    absoluteTolerance: 0.0001))
    }
    
    func test_calcul_net() {
        XCTAssertEqual(100.0 - (0.5 + 9.5 + 7.5),
                       FinancialRevenuTaxesModelTests.financialRevenuTaxes.net(100.0))
    }
    
    func test_calcul_brut() {
        XCTAssertEqual(100.0,
                       FinancialRevenuTaxesModelTests.financialRevenuTaxes.brut(100.0 - (0.5 + 9.5 + 7.5)))
    }
    
    func test_calcul_social_taxes() {
        XCTAssertEqual((0.5 + 9.5 + 7.5),
                       FinancialRevenuTaxesModelTests.financialRevenuTaxes.socialTaxes(100.0))
    }
}
