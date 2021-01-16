//
//  PensionTaxesModel.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 12/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class PensionTaxesModelTests: XCTestCase {
    
    static var pensionTaxes: PensionTaxesModel!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = PensionTaxesModel.Model(for: PensionTaxesModelTests.self,
                                            from                 : "PensionTaxesModelTest.json",
                                            dateDecodingStrategy : .iso8601,
                                            keyDecodingStrategy  : .useDefaultKeys)
        PensionTaxesModelTests.pensionTaxes = PensionTaxesModel(model: model)
    }
    
    // MARK: Tests
    
    func test_calcul_charges_totales_regime_General() {
        XCTAssert(PensionTaxesModelTests.pensionTaxes.model.totalRegimeGeneral.isApproximatelyEqual(to: 9.1,
                                                                                                    absoluteTolerance: 0.0001))
    }

    func test_calcul_charges_totales_regime_Agirc() {
        XCTAssert(PensionTaxesModelTests.pensionTaxes.model.totalRegimeAgirc.isApproximatelyEqual(to: 10.1,
                                                                                                  absoluteTolerance: 0.0001))
    }
    
    func test_calcul_net_pension_regime_General() {
        XCTAssertEqual(100.0 * (1 - 9.1 / 100.0), PensionTaxesModelTests.pensionTaxes.netRegimeGeneral(100.0))
    }

    func test_calcul_net_pension_regime_Agirc() {
        XCTAssertEqual(100.0 * (1 - 10.1 / 100.0), PensionTaxesModelTests.pensionTaxes.netRegimeAgirc(100.0))
    }
    
    func test_calcul_charges_regime_General() {
        XCTAssert(PensionTaxesModelTests.pensionTaxes.socialTaxesRegimeGeneral(100.0).isApproximatelyEqual(to: 100.0 * 9.1 / 100.0,
                                                                                                           absoluteTolerance: 0.0001))
    }
    
    func test_calcul_charges_regime_Agirc() {
        XCTAssert(PensionTaxesModelTests.pensionTaxes.socialTaxesRegimeAgirc(100.0).isApproximatelyEqual(to: 100.0 * 10.1 / 100.0,
                                                                                                         absoluteTolerance: 0.0001))
    }
    
    func test_calcul_CSG_non_deductible() {
        XCTAssert(PensionTaxesModelTests.pensionTaxes.csgNonDeductibleDeIrpp(100.0).isApproximatelyEqual(to: (8.3 - 5.9),
                                                                                                         absoluteTolerance: 0.0001))
    }
    
    func test_calcul_part_taxable_de_la_pension() throws {
        var pensionBrute: Double
        var pensionNette: Double
        var csgNonDeductible: Double
        var baseTaxable: Double
        
        // dégrèvement totale
        pensionBrute = 100.0
        pensionNette = pensionBrute * 0.9
        csgNonDeductible = pensionBrute * ((8.3 - 5.9) / 100.0)
        baseTaxable = pensionNette + csgNonDeductible
        XCTAssertEqual(0.0,
                       try PensionTaxesModelTests.pensionTaxes.taxable(brut: pensionBrute,
                                                                   net: pensionNette))
        // dégrèvement min de 393.0
        pensionBrute = 3_000.0
        pensionNette = pensionBrute * 0.9
        csgNonDeductible = pensionBrute * ((8.3 - 5.9) / 100.0)
        baseTaxable = pensionNette + csgNonDeductible
        XCTAssertEqual(baseTaxable - 393.0,
                       try PensionTaxesModelTests.pensionTaxes.taxable(brut: pensionBrute,
                                                                   net: pensionNette))
        // dégrèvement 10%
        pensionBrute = 10_000.0
        pensionNette = pensionBrute * 0.9
        csgNonDeductible = pensionBrute * ((8.3 - 5.9) / 100.0)
        baseTaxable = pensionNette + csgNonDeductible
        XCTAssertEqual(baseTaxable * (1.0 - 0.1),
                       try PensionTaxesModelTests.pensionTaxes.taxable(brut: pensionBrute,
                                                                   net: pensionNette))
        // dégrèvement plafonné à 3850.0
        pensionBrute = 100_000.0
        pensionNette = pensionBrute * 0.9
        csgNonDeductible = pensionBrute * ((8.3 - 5.9) / 100.0)
        baseTaxable = pensionNette + csgNonDeductible
        XCTAssertEqual(baseTaxable - 3850.0,
                       try PensionTaxesModelTests.pensionTaxes.taxable(brut: pensionBrute,
                                                                   net: pensionNette))
   }
}
