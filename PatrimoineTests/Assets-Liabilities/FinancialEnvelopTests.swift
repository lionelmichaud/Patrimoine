//
//  FinancialEnvelopTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 07/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class FinancialEnvelopTests: XCTestCase {

    struct Envelop: FinancialEnvelop {
        var type      : InvestementType = InvestementType.other
        var ownership : Ownership       = Ownership()
        var name      : String          = "Test"
        
        func value(atEndOf year: Int) -> Double {
            0.0
        }
        
        func print() {
            Swift.print("printed")
        }
        
    }
    
    func test_isLifeInsurance() throws {
        var env = Envelop()
        
        env.type = .lifeInsurance()
        XCTAssertTrue(env.isLifeInsurance)
        
        env.type = .pea
        XCTAssertFalse(env.isLifeInsurance)
        
        env.type = .other
        XCTAssertFalse(env.isLifeInsurance)
    }

    func test_get_clause() throws {
        var env = Envelop()
        
        env.type = .lifeInsurance()
        XCTAssertNotNil(env.clause)
        
        env.type = .pea
        XCTAssertNil(env.clause)
        
        env.type = .other
        XCTAssertNil(env.clause)
    }
}
