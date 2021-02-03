//
//  GridSliceTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 13/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class GridSliceTests: XCTestCase {
    
    func test_nominal_case() throws {
        // given
        let slice = RateSlice(floor: 1.0, rate: 0.2, disc: 3.0)
        let taxableValue = 100.0
        
        // when
        let tax = try slice.tax(for: taxableValue)
        
        // then
        XCTAssertEqual(taxableValue * 0.2 - 3.0, tax)
    }
    
    func test_exception_case() throws {
        // given
        let slice = RateSlice(floor: 100.0, rate: 0.2, disc: 3.0)
        let taxableValue = 50.0
        
        // then
        XCTAssertThrowsError(try slice.tax(for: taxableValue)) { error in
            XCTAssertEqual(error as! RateGridError, RateGridError.notInRightSlice)
        }
    }
}
