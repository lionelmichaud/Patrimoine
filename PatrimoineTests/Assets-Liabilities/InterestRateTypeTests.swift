//
//  InterestRateTypeTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 07/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class InterestRateTypeTests: XCTestCase {

    func test_description() throws {
        var inv: InterestRateKind
        
        inv = .contractualRate(fixedRate: 5.0)
        print(inv)
        
        inv = .marketRate(stockRatio: 10.0)
        print(inv)
    }
}
