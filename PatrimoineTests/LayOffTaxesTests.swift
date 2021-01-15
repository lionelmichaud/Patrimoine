//
//  LayOffTaxesTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 14/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class LayOffTaxesTests: XCTestCase {

    static var layOffTaxes: LayOffTaxes!
    
    // MARK: Helpers
    
    override class func setUp() { // 1.
        // This is the setUp() class method.
        // It is called before the first test method begins.
        // Set up any overall initial state here.
        super.setUp()
        let testBundle = Bundle(for: LayOffTaxesTests.self)
        let model = testBundle.decode(LayOffTaxes.Model.self,
                                      from                 : "LayOffTaxesModelTest.json",
                                      dateDecodingStrategy : .iso8601,
                                      keyDecodingStrategy  : .useDefaultKeys)
        LayOffTaxesTests.layOffTaxes = LayOffTaxes(model: model)
    }
    
    // MARK: Tests
    
    func test_calcul_maxRebate() {
        XCTAssertEqual(2.0 * Fiscal.model.PASS, LayOffTaxesTests.layOffTaxes.model.socialTaxes.maxRebate)
    }

    func test_calcul_CsgCrds_total() {
        XCTAssertEqual(6.8 + 2.9, LayOffTaxesTests.layOffTaxes.model.csgCrds.total)
    }

    func test_calcul_net_indemnite_legal() {
        // given
        let indemniteRelle           = 70_000.0
        let indemniteConventionnelle = 70_000.0
        let indemniteNonImposbale    = 200_000.0
        var compensationTaxable      = indemniteRelle
        
        // when
        let net = LayOffTaxesTests.layOffTaxes.net(compensationConventional: indemniteConventionnelle,
                                                   compensationBrut: indemniteRelle,
                                                   compensationTaxable: &compensationTaxable,
                                                   irppDiscount: indemniteNonImposbale)
        
        // then
        let discountCotisationSociale = indemniteConventionnelle
        let baseCotisationSociale = indemniteRelle - discountCotisationSociale
        let cotisationSociale = baseCotisationSociale * 13.0 / 100.0
        
        let discountCsgCrds = min(2.0 * Fiscal.model.PASS, indemniteConventionnelle)
        let baseCsgCrds = indemniteRelle - discountCsgCrds
        let CsgCrds = baseCsgCrds * (6.8 + 2.9) / 100.0
        
        let theoric = indemniteRelle - (cotisationSociale + CsgCrds)
        XCTAssertEqual(theoric, net)
    }
    
    func test_calcul_net_indemnite_supra_legal() {
        // given
        let indemniteRelle           = 85_000.0
        let indemniteConventionnelle = 70_000.0
        let indemniteNonImposbale    = 200_000.0
        var compensationTaxable      = indemniteRelle

        // when
        let net = LayOffTaxesTests.layOffTaxes.net(compensationConventional: indemniteConventionnelle,
                                                   compensationBrut: indemniteRelle,
                                                   compensationTaxable: &compensationTaxable,
                                                   irppDiscount: indemniteNonImposbale)
        
        // then
        let discountCotisationSociale = 2.0 * Fiscal.model.PASS
        let baseCotisationSociale = indemniteRelle - discountCotisationSociale
        let cotisationSociale = baseCotisationSociale * 13.0 / 100.0
        
        let discountCsgCrds = min(2.0 * Fiscal.model.PASS, indemniteConventionnelle)
        let baseCsgCrds = indemniteRelle - discountCsgCrds
        let CsgCrds = baseCsgCrds * (6.8 + 2.9) / 100.0
        
        let theoric = indemniteRelle - (cotisationSociale + CsgCrds)
        XCTAssertEqual(theoric, net)
    }
}
