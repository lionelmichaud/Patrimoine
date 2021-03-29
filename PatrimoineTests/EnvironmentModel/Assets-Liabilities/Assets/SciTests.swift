//
//  SciTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 19/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class SciTests: XCTestCase {
    
    static func ageOf(_ name: String, _ year: Int) -> Int {
        switch name {
            case "Owner1 de 65 ans en 2020":
                return 65 + (year - 2020)
            case "Owner2 de 55 ans en 2020":
                return 55 + (year - 2020)
            default:
                return 85 + (year - 2020)
        }
    }
    
    static var sci: SCI!

    override class func setUp() {
        super.setUp()
        SciTests.sci = SCI(name : "LVLA",
                           note : "Crée en 2019",
                           with : nil)
        print(SciTests.sci!)
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

}
