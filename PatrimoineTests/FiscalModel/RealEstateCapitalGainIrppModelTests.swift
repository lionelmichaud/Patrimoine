//
//  RealEstateCapitalGainIrppModelTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 13/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class RealEstateCapitalGainIrppModelTests: XCTestCase {

    static var estateCapitalGainIrpp: RealEstateCapitalGainIrppModel!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = RealEstateCapitalGainIrppModel.Model(for: RealEstateCapitalGainIrppModelTests.self,
                                                         from                 : nil,
                                                         dateDecodingStrategy : .iso8601,
                                                         keyDecodingStrategy  : .useDefaultKeys)
        RealEstateCapitalGainIrppModelTests.estateCapitalGainIrpp = RealEstateCapitalGainIrppModel(model: model)
    }
    
    // MARK: Tests

    func test_calcul_irpp_sans_abbatement_pour_travaux() {
        // given
        let pluValue = 100_000.0
        let detention = 4 // ans
        
        // when
        let irpp = RealEstateCapitalGainIrppModelTests.estateCapitalGainIrpp.irpp(capitalGain: pluValue,
                                                                                  detentionDuration: detention)
        // then
        XCTAssertEqual(19.0 / 100.0 * pluValue, irpp)
    }

    func test_calcul_irpp_avec_abbatement_pour_travaux() {
        // given
        let pluValue = 100_000.0
        let detention = 5 // ans
        
        // when
        let irpp = RealEstateCapitalGainIrppModelTests.estateCapitalGainIrpp.irpp(capitalGain: pluValue,
                                                                                  detentionDuration: detention)
        // then
        XCTAssertEqual(19.0 / 100.0 * (1.0 - 15.0/100.0) * pluValue, irpp)
    }

    func test_calcul_irpp_avec_abbatement_pour_travaux_et_progressif() {
        // given
        var pluValue = 100_000.0
        var detention = 6 // ans
        // when
        var irpp = RealEstateCapitalGainIrppModelTests.estateCapitalGainIrpp.irpp(capitalGain: pluValue,
                                                                                  detentionDuration: detention)
        // then
        var theory = 19.0 / 100.0 * (1.0 - 15.0/100.0)
        theory *= (1.0 - (Double(detention) - 5.0) * 6.0 / 100.0) * pluValue
        XCTAssert(irpp.isApproximatelyEqual(to: theory))
        
        // given
        pluValue = 100_000.0
        detention = 21 // ans
        // when
        irpp = RealEstateCapitalGainIrppModelTests.estateCapitalGainIrpp.irpp(capitalGain: pluValue,
                                                                                  detentionDuration: detention)
        // then
        theory = 19.0 / 100.0 * (1.0 - 15.0/100.0)
        theory *= (1.0 - (Double(detention) - 5.0) * 6.0 / 100.0) * pluValue
        XCTAssert(irpp.isApproximatelyEqual(to: theory))
    }
    
    func test_calcul_irpp_avec_abbatement_total() {
        // given
        var pluValue = 100_000.0
        var detention = 22 // ans
        // when
        var irpp = RealEstateCapitalGainIrppModelTests.estateCapitalGainIrpp.irpp(capitalGain: pluValue,
                                                                                  detentionDuration: detention)
        // then
        XCTAssertEqual(0.0, irpp)
        
        // given
        pluValue = 100_000.0
        detention = 35 // ans
        // when
        irpp = RealEstateCapitalGainIrppModelTests.estateCapitalGainIrpp.irpp(capitalGain: pluValue,
                                                                                  detentionDuration: detention)
        // then
        XCTAssertEqual(0.0, irpp)
    }
}
