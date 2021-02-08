//
//  InvestementTypeTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 07/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class InvestementTypeTests: XCTestCase {

    func test_description() throws {
        var inv: InvestementType
        
        inv = .pea
        print(inv)

        inv = .other
        print(inv)

        inv = .lifeInsurance(periodicSocialTaxes: true,
                             clause: LifeInsuranceClause())
        print(inv)
    }
}
