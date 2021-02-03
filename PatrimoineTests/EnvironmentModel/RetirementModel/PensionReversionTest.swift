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
        let model = PensionReversion.Model(for                  : PensionReversionTest.self,
                                           from                 : nil,
                                           dateDecodingStrategy : .iso8601,
                                           keyDecodingStrategy  : .useDefaultKeys)
        PensionReversionTest.reversion = PensionReversion(model: model)
    }
    
    // MARK: Tests
    
    func test_saving_to_test_bundle() throws {
        PensionReversionTest.reversion.saveToBundle(for                  : RegimeGeneralTest.self,
                                                    to                   : nil,
                                                    dateEncodingStrategy : .iso8601,
                                                    keyEncodingStrategy  : .useDefaultKeys)
    }
    
    func test_pension_reversion() {
        let pensionDecedent = 2000.0
        let pensionSpouse   = 1000.0
        
        let reversion = PensionReversionTest.reversion.pensionReversion(pensionDecedent: pensionDecedent,
                                                                        pensionSpouse  : pensionSpouse)
        
        XCTAssertEqual((pensionDecedent + pensionSpouse) * 0.7, reversion)
    }
}
