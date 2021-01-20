//
//  PensionReversionTest.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 16/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class PensionReversionTest: XCTestCase {
    
    static var reversion    : PensionReversion!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = PensionReversion.Model(for: PensionReversionTest.self,
                                           from                 : "RetirementReversionModelConfigTest.json",
                                           dateDecodingStrategy : .iso8601,
                                           keyDecodingStrategy  : .useDefaultKeys)
        PensionReversionTest.reversion = PensionReversion(model: model)
    }
    
    // MARK: Tests
    
    func test_saving_to_test_bundle() throws {
        PensionReversionTest.reversion.model.saveToBundle(for: RegimeGeneralTest.self,
                                                          to: "RetirementReversionModelConfigTest.json",
                                                          dateEncodingStrategy: .iso8601,
                                                          keyEncodingStrategy: .useDefaultKeys)
    }
    
    func test_tauxReversion() {
        XCTAssertEqual(PensionReversionTest.reversion.model.tauxReversion, 70.0)
    }
}
