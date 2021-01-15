//
//  AllocationChomageTaxesModelTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 12/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class AllocationChomageTaxesModelTests: XCTestCase {
    static var allocationChomageTaxes: AllocationChomageTaxesModel!
    
    // MARK: Helpers
        
    override class func setUp() { // 1.
        // This is the setUp() class method.
        // It is called before the first test method begins.
        // Set up any overall initial state here.
        super.setUp()
        let testBundle = Bundle(for: AllocationChomageTaxesModelTests.self)
        let model = testBundle.decode(AllocationChomageTaxesModel.Model.self,
                                      from                 : "AllocationChomageTaxesModelTest.json",
                                      dateDecodingStrategy : .iso8601,
                                      keyDecodingStrategy  : .useDefaultKeys)
        AllocationChomageTaxesModelTests.allocationChomageTaxes = AllocationChomageTaxesModel(model: model)
    }
    
    // MARK: Tests
    
    func test_calcul_net() throws {
        var allocJournaliere: Double
        var SJR: Double
        var net: Double
        
        // given
        allocJournaliere = 100.0
        SJR = 120.0
        
        // when
        net = try AllocationChomageTaxesModelTests.allocationChomageTaxes.net(brut: allocJournaliere, SJR: SJR)
        
        // then
        XCTAssertEqual(allocJournaliere - (allocJournaliere * 0.90 * (6.5 + 0.5) / 100.0 + (SJR * 4.0 / 100.0)),
                       net)
    }
    
    func test_calcul_social_taxes() throws {
        var allocJournaliere: Double
        var SJR: Double
        var tax: Double

        // allocation < au seuil de taxation Cotisation Retraite Complémentaire
        // allocation < au seuil de taxation CSG + CRDS
        // given
        allocJournaliere = 20.0
        SJR = 30.0
        // when
        tax = try AllocationChomageTaxesModelTests.allocationChomageTaxes.socialTaxes(brut: allocJournaliere, SJR: SJR)
        // then
        XCTAssertEqual(0.0, tax)
        
        // Exemple 2 de [exemples de calcul](https://www.unedic.org/indemnisation/fiches-thematiques/retenues-sociales-sur-les-allocations)
        // allocation > au seuil de taxation Cotisation Retraite Complémentaire
        // allocation < au seuil de taxation CSG + CRDS
        // given
        allocJournaliere = 39.9
        SJR = 70.0
        // when
        tax = try AllocationChomageTaxesModelTests.allocationChomageTaxes.socialTaxes(brut: allocJournaliere, SJR: SJR)
        // then
        XCTAssertEqual(SJR * 4.0 / 100.0, tax)
        
        // Exemple 1 de [exemples de calcul](https://www.unedic.org/indemnisation/fiches-thematiques/retenues-sociales-sur-les-allocations)
        // allocation > au seuil de taxation CSG + CRDS
        // brut > seuil pour assiette réduite
        // given
        allocJournaliere = 58.14
        SJR = 102.0
        // when
        tax = try AllocationChomageTaxesModelTests.allocationChomageTaxes.socialTaxes(brut: allocJournaliere, SJR: SJR)
        // then
        XCTAssertEqual(allocJournaliere * 0.9 * (6.5 + 0.5) / 100.0 + (SJR * 4.0 / 100.0), tax)
    }
    
    func test_calcul_social_taxes_with_negative_brut() throws {
        var allocJournaliere: Double
        var SJR: Double
        var tax: Double

        // given
        allocJournaliere = -1.0
        SJR = 1000.0
        
        // when
        tax = try AllocationChomageTaxesModelTests.allocationChomageTaxes.socialTaxes(brut: allocJournaliere, SJR: SJR)
        
        // then
        XCTAssertEqual(0.0, tax)
    }
    
    func test_calcul_social_taxes_with_outOfBound_SJR() {
        var allocJournaliere: Double
        var SJR: Double
        
        // given
        allocJournaliere = 100.0
        SJR = -1.0
        
        // then
        XCTAssertThrowsError(try AllocationChomageTaxesModelTests.allocationChomageTaxes.socialTaxes(brut: allocJournaliere, SJR: SJR)) { error in
            XCTAssertEqual(error as! AllocationChomageTaxesModel.ModelError, AllocationChomageTaxesModel.ModelError.outOfBounds)
        }

    }

}
