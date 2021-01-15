//
//  PatrimoineTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 08/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class PatrimoineTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

class FinancialMathtests: XCTestCase {
    
    func test_futurValue() {
        var fv = futurValue(payement: 100,
                            interestRate: 0,
                            nbPeriod: 10,
                            initialValue: 0)
        print(fv)
        XCTAssertTrue(fv == 1000.0, "mauvaise valeur future")
        
        fv = futurValue(payement: 100,
                        interestRate: 0.1,
                        nbPeriod: 10,
                        initialValue: 0)
        print(fv)
        XCTAssertTrue(fv.isApproximatelyEqual(to: 1593.7424601, absoluteTolerance: 0.0001), "mauvaise valeur future")
        
        fv = futurValue(payement: 100,
                        interestRate: 0.1,
                        nbPeriod: 10,
                        initialValue: 1000)
        print(fv)
        XCTAssertTrue(fv.isApproximatelyEqual(to: 4187.4849202, absoluteTolerance: 0.0001), "mauvaise valeur future")
    }
    
    func test_loanPayement() {
        var lp = loanPayement(loanedValue: 100,
                              interestRate: 0.1,
                              nbPeriod: 1)
        print(lp)
        XCTAssertTrue(lp.isApproximatelyEqual(to: 110.0, absoluteTolerance: 0.0001), "mauvaise Montant du remboursement")
        
        lp = loanPayement(loanedValue: 100,
                          interestRate: 0.065,
                          nbPeriod: 10)
        print(lp)
        XCTAssertTrue(lp.isApproximatelyEqual(to: 13.91046901, absoluteTolerance: 0.0001), "mauvaise Montant du remboursement")
    }
    
    func test_residualValue() {
        let initialValue = 100.0
        let interestRate = 0.1
        let firstYear    = 2020
        let lastYear     = 2030
        let nbPeriod     = lastYear - firstYear + 1
        
        var fv = futurValue(payement: 0,
                            interestRate: interestRate,
                            nbPeriod: nbPeriod,
                            initialValue: initialValue)
        print(fv)
        var lp = loanPayement(loanedValue: initialValue,
                              interestRate: interestRate,
                              nbPeriod: nbPeriod)
        print("loanPayement =", lp, "loanPayement x nbPeriod = ", nbPeriod.double() * lp)

        var rv = residualValue(loanedValue  : initialValue,
                               interestRate : interestRate,
                               firstYear    : firstYear,
                               lastYear     : lastYear,
                               currentYear  : 2020)
        print("Valeur résiduelle = ", rv)
        XCTAssertTrue(rv.isApproximatelyEqual(to: 100.0, absoluteTolerance: 0.0001), "mauvaise Valeur résiduelle")
    }
}
