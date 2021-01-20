//
//  RegimeAgirc.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 16/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class RegimeAgircTest: XCTestCase {
    
    static var regimeAgirc  : RegimeAgirc!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = RegimeAgirc.Model(for: RegimeAgircTest.self,
                                      from                 : "RetirementRegimeAgircModelConfigTest.json",
                                      dateDecodingStrategy : .iso8601,
                                      keyDecodingStrategy  : .useDefaultKeys)
        RegimeAgircTest.regimeAgirc = RegimeAgirc(model: model)
    }
    
    // MARK: Tests
    
    func test_saving_to_test_bundle() throws {
        RegimeAgircTest.regimeAgirc.model.saveToBundle(for: RegimeGeneralTest.self,
                                                       to: "RetirementRegimeAgircModelConfigTest.json",
                                                       dateEncodingStrategy: .iso8601,
                                                       keyEncodingStrategy: .useDefaultKeys)
    }
}
