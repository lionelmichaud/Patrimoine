//
//  RealEstateCapitalGainTaxesModelTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 14/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class RealEstateCapitalGainTaxesModelTests: XCTestCase {
    
    static var estateCapitalGainTaxes: RealEstateCapitalGainTaxesModel!
    
    // MARK: Helpers
    
    override class func setUp() { // 1.
        // This is the setUp() class method.
        // It is called before the first test method begins.
        // Set up any overall initial state here.
        super.setUp()
        let testBundle = Bundle(for: RealEstateCapitalGainTaxesModelTests.self)
        let model = testBundle.decode(RealEstateCapitalGainTaxesModel.Model.self,
                                      from                 : "RealEstateCapitalGainTaxesModelTest.json",
                                      dateDecodingStrategy : .iso8601,
                                      keyDecodingStrategy  : .useDefaultKeys)
        RealEstateCapitalGainTaxesModelTests.estateCapitalGainTaxes = RealEstateCapitalGainTaxesModel(model: model)
    }
    
    // MARK: Tests
    
    func test_calcul_taxes_totales() {
        XCTAssertEqual(17.2, RealEstateCapitalGainTaxesModelTests.estateCapitalGainTaxes.model.total)
    }
    
    func test_calcul_taxes_sans_abbatement_pour_travaux() {
        // given
        let pluValue = 100_000.0
        let detention = 4 // ans
        
        // when
        let taxes = RealEstateCapitalGainTaxesModelTests.estateCapitalGainTaxes.socialTaxes(capitalGain: pluValue,
                                                                                            detentionDuration: detention)
        // then
        XCTAssertEqual(17.2 / 100.0 * pluValue, taxes)
    }
    
    // https://www.leblogpatrimoine.com/impot/simulateur-plus-value-immobiliere-un-impot-degressif-selon-la-duree-de-detention.html
    func test_calcul_taxes_avec_abbatement_pour_travaux_et_progressif() {
        // given
        var pluValue = 100_000.0
        var detention = 6 // ans
        // when
        var taxes = RealEstateCapitalGainTaxesModelTests.estateCapitalGainTaxes.socialTaxes(capitalGain: pluValue,
                                                                                            detentionDuration: detention)
        // then
        var theory = 17.2 / 100.0 * (1.0 - 15.0/100.0)
        theory *= (1.0 - (Double(detention) - 5.0) * 1.65 / 100.0) * pluValue
        XCTAssertEqual(theory, taxes)
        XCTAssert(taxes.isApproximatelyEqual(to: theory))
        
        // given
        pluValue = 100_000.0
        detention = 21 // ans
        // when
        taxes = RealEstateCapitalGainTaxesModelTests.estateCapitalGainTaxes.socialTaxes(capitalGain: pluValue,
                                                                                        detentionDuration: detention)
        // then
        theory = 17.2 / 100.0 * (1.0 - 15.0/100.0)
        var discount = (Double(detention) - 5.0) * 1.65
        theory *= (1.0 - discount / 100.0) * pluValue
        XCTAssertEqual(theory, taxes)
        XCTAssert(taxes.isApproximatelyEqual(to: theory))
        
        // given
        pluValue = 100_000.0
        detention = 22 // ans
        // when
        taxes = RealEstateCapitalGainTaxesModelTests.estateCapitalGainTaxes.socialTaxes(capitalGain: pluValue,
                                                                                        detentionDuration: detention)
        // then
        theory = 17.2 / 100.0 * (1.0 - 15.0/100.0)
        discount = (21 - 5) * 1.65 + 1.6
        theory *= (1.0 - discount / 100.0) * pluValue
        XCTAssertEqual(theory, taxes)
        XCTAssert(taxes.isApproximatelyEqual(to: theory))
        
        // given
        pluValue = 100_000.0
        detention = 23 // ans
        // when
        taxes = RealEstateCapitalGainTaxesModelTests.estateCapitalGainTaxes.socialTaxes(capitalGain: pluValue,
                                                                                        detentionDuration: detention)
        // then
        theory = 17.2 / 100.0 * (1.0 - 15.0/100.0)
        discount = (21 - 5) * 1.65 + 1.6
        discount += Double(detention - 22) * 9.0
        theory *= (1.0 - discount / 100.0) * pluValue
        XCTAssertEqual(theory, taxes)
        XCTAssert(taxes.isApproximatelyEqual(to: theory))
        
        // given
        pluValue = 100_000.0
        detention = 30 // ans
        // when
        taxes = RealEstateCapitalGainTaxesModelTests.estateCapitalGainTaxes.socialTaxes(capitalGain: pluValue,
                                                                                        detentionDuration: detention)
        // then
        theory = 17.2 / 100.0 * (1.0 - 15.0/100.0)
        discount = (21 - 5) * 1.65 + 1.6
        discount += Double(detention - 22) * 9.0
        theory *= (1.0 - discount / 100.0) * pluValue
        XCTAssertEqual(theory, taxes)
        XCTAssert(taxes.isApproximatelyEqual(to: theory))
    }
    
    func test_calcul_taxes_avec_abbatement_total() {
        // given
        var pluValue = 100_000.0
        var detention = 31 // ans
        // when
        var taxes = RealEstateCapitalGainTaxesModelTests.estateCapitalGainTaxes.socialTaxes(capitalGain: pluValue,
                                                                                            detentionDuration: detention)
        // then
        XCTAssertEqual(0.0, taxes)
        
        // given
        pluValue = 100_000.0
        detention = 40 // ans
        // when
        taxes = RealEstateCapitalGainTaxesModelTests.estateCapitalGainTaxes.socialTaxes(capitalGain: pluValue,
                                                                                        detentionDuration: detention)
        // then
        XCTAssertEqual(0.0, taxes)
    }
}
