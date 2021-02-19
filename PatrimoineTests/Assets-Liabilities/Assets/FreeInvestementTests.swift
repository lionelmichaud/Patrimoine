//
//  FreeInvestementTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 12/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class FreeInvestementTests: XCTestCase {
    
    struct EconomyModelProvider: EconomyModelProviderProtocol {
        func rates(in year: Int,
                   withMode mode: SimulationModeEnum) -> (securedRate: Double, stockRate: Double) {
            (securedRate: Double(year) + 5.0, stockRate: Double(year) + 10.0)
        }
        
        func rates(withMode mode: SimulationModeEnum) -> (securedRate: Double, stockRate: Double) {
            (securedRate: 5.0, stockRate: 10.0)
        }
        
        func inflation(withMode simulationMode: SimulationModeEnum) -> Double {
            2.5
        }
    }

    static var economyModelProvider = EconomyModelProvider()
    static var fi                : FreeInvestement!
    static var inflation         : Double = 0.0
    static var rates = (securedRate: 0.0, stockRate: 0.0)
    static var rates2021 = (securedRate: 0.0, stockRate: 0.0)
    static var averageRateTheory : Double = 0.0
    static var averageRate2021Theory : Double = 0.0

    override class func setUp() {
        super.setUp()
        FreeInvestement.setSimulationMode(to: .deterministic)
        FreeInvestement.setEconomyModelProvider(economyModelProvider)
        FreeInvestement.setFiscalModelProvider(
            Fiscal.Model(for: FiscalModelTests.self,
                         from                 : nil,
                         dateDecodingStrategy : .iso8601,
                         keyDecodingStrategy  : .useDefaultKeys)
                .initialized())
        
        FreeInvestementTests.fi = FreeInvestement(for: FreeInvestementTests.self,
                                                  from                 : nil,
                                                  dateDecodingStrategy : .iso8601,
                                                  keyDecodingStrategy  : .useDefaultKeys)
        FreeInvestementTests.fi.resetCurrentState()
        print(FreeInvestementTests.fi!)
        
        FreeInvestementTests.inflation = FreeInvestementTests.economyModelProvider.inflation(withMode: .deterministic)
        
        FreeInvestementTests.rates     = FreeInvestementTests.economyModelProvider.rates(withMode: .deterministic)
        FreeInvestementTests.averageRateTheory =
            (0.75 * FreeInvestementTests.rates.stockRate + 0.25 * FreeInvestementTests.rates.securedRate)
            - FreeInvestementTests.inflation
        
        FreeInvestementTests.rates2021 = FreeInvestementTests.economyModelProvider.rates(in: 2021, withMode: .deterministic)
        FreeInvestementTests.averageRate2021Theory =
            (0.75 * FreeInvestementTests.rates2021.stockRate + 0.25 * FreeInvestementTests.rates2021.securedRate)
            - FreeInvestementTests.inflation
    }
    
    func test_averageInterestRate() {
        var fi = FreeInvestement(for: FreeInvestementTests.self,
                                 from                 : nil,
                                 dateDecodingStrategy : .iso8601,
                                 keyDecodingStrategy  : .useDefaultKeys)
        fi.resetCurrentState()
        
        XCTAssertEqual(FreeInvestementTests.averageRateTheory, fi.averageInterestRate)
        
        fi.interestRateType = .contractualRate(fixedRate: 2.5)
        XCTAssertEqual(2.5 - FreeInvestementTests.inflation, fi.averageInterestRate)
    }
    
    func test_averageInterestRateNet() {
        var fi = FreeInvestement(for: FreeInvestementTests.self,
                                 from                 : nil,
                                 dateDecodingStrategy : .iso8601,
                                 keyDecodingStrategy  : .useDefaultKeys)
        fi.resetCurrentState()
        
        fi.type = .lifeInsurance(periodicSocialTaxes: true, clause: LifeInsuranceClause())
        XCTAssertGreaterThan(FreeInvestementTests.averageRateTheory, fi.averageInterestRateNet)
        
        fi.type = .lifeInsurance(periodicSocialTaxes: false, clause: LifeInsuranceClause())
        XCTAssertEqual(fi.averageInterestRate, fi.averageInterestRateNet)
        
        fi.type = .pea
        XCTAssertEqual(fi.averageInterestRate, fi.averageInterestRateNet)
        
        fi.type = .other
        XCTAssertEqual(fi.averageInterestRate, fi.averageInterestRateNet)
    }
    
    func test_capitalize() throws {
        var fi = FreeInvestement(for: FreeInvestementTests.self,
                                 from                 : nil,
                                 dateDecodingStrategy : .iso8601,
                                 keyDecodingStrategy  : .useDefaultKeys)
        fi.resetCurrentState()
        let interest = fi.initialState.investment * FreeInvestementTests.averageRate2021Theory / 100.0

        XCTAssertThrowsError(try fi.capitalize(atEndOf: 2020)) { error in
            XCTAssertEqual(error as! FreeInvestementError, FreeInvestementError.IlegalOperation)
        }
        XCTAssertThrowsError(try fi.capitalize(atEndOf: 2022)) { error in
            XCTAssertEqual(error as! FreeInvestementError, FreeInvestementError.IlegalOperation)
        }
        
        try fi.capitalize(atEndOf: 2021)
        
        XCTAssertEqual(fi.initialState.investment + interest, fi.value(atEndOf: 2021))
    }
    
    func test_ownedValue() {
        var fi = FreeInvestement(for: FreeInvestementTests.self,
                                 from                 : nil,
                                 dateDecodingStrategy : .iso8601,
                                 keyDecodingStrategy  : .useDefaultKeys)
        fi.resetCurrentState()
        
        // lifeInsurance + legalSuccession
        var ownedValue = fi.ownedValue(by               : "M. Lionel MICHAUD",
                                       atEndOf          : 2020,
                                       evaluationMethod : .legalSuccession)
        XCTAssertEqual(0, ownedValue)
        
        // lifeInsurance + patrimoine
        ownedValue = fi.ownedValue(by               : "M. Lionel MICHAUD",
                                   atEndOf          : 2020,
                                   evaluationMethod : .patrimoine)
        XCTAssertEqual(fi.value(atEndOf: 2020), ownedValue)

        // lifeInsurance + lifeInsuranceSuccession
        ownedValue = fi.ownedValue(by               : "M. Lionel MICHAUD",
                                   atEndOf          : 2020,
                                   evaluationMethod : .lifeInsuranceSuccession)
        XCTAssertEqual(fi.value(atEndOf: 2020), ownedValue)

        // pea + legalSuccession
        fi.type = .pea
        ownedValue = fi.ownedValue(by               : "M. Lionel MICHAUD",
                                   atEndOf          : 2020,
                                   evaluationMethod : .legalSuccession)
        XCTAssertEqual(fi.value(atEndOf: 2020), ownedValue)

        // pea + patrimoine
        fi.type = .pea
        ownedValue = fi.ownedValue(by               : "M. Lionel MICHAUD",
                                   atEndOf          : 2020,
                                   evaluationMethod : .patrimoine)
        XCTAssertEqual(fi.value(atEndOf: 2020), ownedValue)

        // pea + lifeInsuranceSuccession
        fi.type = .pea
        ownedValue = fi.ownedValue(by               : "M. Lionel MICHAUD",
                                   atEndOf          : 2020,
                                   evaluationMethod : .lifeInsuranceSuccession)
        XCTAssertEqual(0, ownedValue)
    }
}
