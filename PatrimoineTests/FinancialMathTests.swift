//
//  PatrimoineTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 08/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class FinancialMathTests: XCTestCase {
    
    func test_futurValue() {
        var fv = try! futurValue(payement: 100,
                            interestRate: 0,
                            nbPeriod: 10,
                            initialValue: 0)
        print(fv)
        XCTAssertTrue(fv == 1000.0, "mauvaise valeur future")
        
        fv = try! futurValue(payement: 100,
                             interestRate: 0.1,
                             nbPeriod: 10,
                             initialValue: 0)
        print(fv)
        XCTAssertTrue(fv.isApproximatelyEqual(to: 1593.7424601, absoluteTolerance: 0.0001), "mauvaise valeur future")
        
        fv = try! futurValue(payement     : 100,
                             interestRate : 0.1,
                             nbPeriod     : 10,
                             initialValue : 1000)
        print(fv)
        XCTAssertTrue(fv.isApproximatelyEqual(to: 4187.4849202, absoluteTolerance: 0.0001), "mauvaise valeur future")
        
        XCTAssertThrowsError(try futurValue(payement     : 100,
                                            interestRate : 0.1,
                                            nbPeriod     : -1,
                                            initialValue : 1000)) { error in
            XCTAssertEqual(error as! FinancialMathError, FinancialMathError.negativeNbPeriod)
        }
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
        
        XCTAssertNoThrow(try residualValue(loanedValue   : initialValue,
                                           interestRate  : interestRate,
                                           firstPeriod   : firstYear,
                                           lastPeriod    : lastYear,
                                           currentPeriod : lastYear))
        XCTAssertNoThrow(try residualValue(loanedValue   : initialValue,
                                           interestRate  : interestRate,
                                           firstPeriod   : firstYear,
                                           lastPeriod    : lastYear,
                                           currentPeriod : firstYear + 2))
        XCTAssertNoThrow(try residualValue(loanedValue   : initialValue,
                                           interestRate  : interestRate,
                                           firstPeriod   : firstYear,
                                           lastPeriod    : lastYear,
                                           currentPeriod : firstYear-1))
        
        var rv = try! residualValue(loanedValue   : initialValue,
                                    interestRate  : interestRate,
                                    firstPeriod   : firstYear,
                                    lastPeriod    : lastYear,
                                    currentPeriod : lastYear)
        
        print("Valeur résiduelle = ", rv)
        XCTAssertTrue(rv.isApproximatelyEqual(to: 0.0, absoluteTolerance: 0.0001), "mauvaise Valeur résiduelle")
        
        rv = try! residualValue(loanedValue   : initialValue,
                                interestRate  : interestRate,
                                firstPeriod   : firstYear,
                                lastPeriod    : lastYear,
                                currentPeriod : firstYear-1)
        print("Valeur résiduelle = ", rv)
        XCTAssertTrue(rv.isApproximatelyEqual(to: 100.0, absoluteTolerance: 0.0001), "mauvaise Valeur résiduelle")
        
        XCTAssertThrowsError(try residualValue(loanedValue   : initialValue,
                                               interestRate  : interestRate,
                                               firstPeriod   : firstYear,
                                               lastPeriod    : lastYear,
                                               currentPeriod : firstYear-2)) { error in
            XCTAssertEqual(error as! FinancialMathError, FinancialMathError.periodOutOfBound)
        }
    }
}
