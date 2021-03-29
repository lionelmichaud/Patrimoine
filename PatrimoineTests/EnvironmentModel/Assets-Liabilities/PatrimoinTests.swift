//
//  PatrimoinTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 19/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class PatrimoinTests: XCTestCase {

    static var patrimoine: Patrimoin!
    
    override class func setUp() {
        super.setUp()
        PatrimoinTests.patrimoine = Patrimoin()
        print(PatrimoinTests.patrimoine!)
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
