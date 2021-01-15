//
//  DemembrementModelTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 14/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class DemembrementModelTests: XCTestCase {
    
    static var demembrement: DemembrementModel!
    
    // MARK: Helpers
    
    override class func setUp() { // 1.
        // This is the setUp() class method.
        // It is called before the first test method begins.
        // Set up any overall initial state here.
        super.setUp()
        let testBundle = Bundle(for: DemembrementModelTests.self)
        let model = testBundle.decode(DemembrementModel.Model.self,
                                      from                 : "DemembrementModelTest.json",
                                      dateDecodingStrategy : .iso8601,
                                      keyDecodingStrategy  : .useDefaultKeys)
        DemembrementModelTests.demembrement = DemembrementModel(model: model)
    }
    
    // MARK: Tests
    
    func test_demembrement_outOfBound() {
        XCTAssertThrowsError(try DemembrementModelTests.demembrement.demembrement(of: 100.0, usufructuaryAge: -1)) { error in
            XCTAssertEqual(error as! DemembrementModel.ModelError, DemembrementModel.ModelError.outOfBounds)
        }
    }
    
    func test_demembrement() throws {
        var demembrement = try DemembrementModelTests.demembrement.demembrement(of: 100.0, usufructuaryAge: 20)
        XCTAssertEqual(90.0, demembrement.usufructValue)
        XCTAssertEqual(10.0, demembrement.bareValue)

        demembrement = try DemembrementModelTests.demembrement.demembrement(of: 100.0, usufructuaryAge: 30)
        XCTAssertEqual(80.0, demembrement.usufructValue)
        XCTAssertEqual(20.0, demembrement.bareValue)

        demembrement = try DemembrementModelTests.demembrement.demembrement(of: 100.0, usufructuaryAge: 50)
        XCTAssertEqual(60.0, demembrement.usufructValue)
        XCTAssertEqual(40.0, demembrement.bareValue)

        demembrement = try DemembrementModelTests.demembrement.demembrement(of: 100.0, usufructuaryAge: 60)
        XCTAssertEqual(50.0, demembrement.usufructValue)
        XCTAssertEqual(50.0, demembrement.bareValue)

        demembrement = try DemembrementModelTests.demembrement.demembrement(of: 100.0, usufructuaryAge: 80)
        XCTAssertEqual(30.0, demembrement.usufructValue)
        XCTAssertEqual(70.0, demembrement.bareValue)

        demembrement = try DemembrementModelTests.demembrement.demembrement(of: 100.0, usufructuaryAge: 90)
        XCTAssertEqual(20.0, demembrement.usufructValue)
        XCTAssertEqual(80.0, demembrement.bareValue)

        demembrement = try DemembrementModelTests.demembrement.demembrement(of: 100.0, usufructuaryAge: 100)
        XCTAssertEqual(10.0, demembrement.usufructValue)
        XCTAssertEqual(90.0, demembrement.bareValue)
    }
}
