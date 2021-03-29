//
//  PeriodicInvestmentTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 12/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class PeriodicInvestementTests: XCTestCase {

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
    static var fi                : PeriodicInvestement!
    static var inflation         : Double = 0.0
    static var rates = (securedRate: 0.0, stockRate: 0.0)
    static var rates2021 = (securedRate: 0.0, stockRate: 0.0)
    static var averageRateTheory : Double = 0.0
    static var averageRate2021Theory : Double = 0.0

    override class func setUp() {
        super.setUp()
        PeriodicInvestement.setSimulationMode(to: .deterministic)
        PeriodicInvestement.setEconomyModelProvider(economyModelProvider)
        PeriodicInvestement.setFiscalModelProvider(
            Fiscal.Model(for: FiscalModelTests.self,
                         from                 : nil,
                         dateDecodingStrategy : .iso8601,
                         keyDecodingStrategy  : .useDefaultKeys)
                .initialized())
        
        PeriodicInvestementTests.fi = PeriodicInvestement(for: PeriodicInvestementTests.self,
                                                  from                 : nil,
                                                  dateDecodingStrategy : .iso8601,
                                                  keyDecodingStrategy  : .useDefaultKeys)
        print(PeriodicInvestementTests.fi!)
        
        PeriodicInvestementTests.inflation = PeriodicInvestementTests.economyModelProvider.inflation(withMode: .deterministic)
        
        PeriodicInvestementTests.rates     = PeriodicInvestementTests.economyModelProvider.rates(withMode: .deterministic)
        PeriodicInvestementTests.averageRateTheory =
            (0.75 * PeriodicInvestementTests.rates.stockRate + 0.25 * PeriodicInvestementTests.rates.securedRate)
            - PeriodicInvestementTests.inflation
        
        PeriodicInvestementTests.rates2021 = PeriodicInvestementTests.economyModelProvider.rates(in: 2021, withMode: .deterministic)
        PeriodicInvestementTests.averageRate2021Theory =
            (0.75 * PeriodicInvestementTests.rates2021.stockRate + 0.25 * PeriodicInvestementTests.rates2021.securedRate)
            - PeriodicInvestementTests.inflation
    }
    
    func test() {
        
    }
    
}
