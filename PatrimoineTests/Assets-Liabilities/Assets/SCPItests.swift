//
//  SCPItests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 10/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class SCPItests: XCTestCase {

    struct InflationProvider: InflationProviderProtocol {
        func inflation(withMode simulationMode: SimulationModeEnum) -> Double {
            10.0
        }
    }

    static var scpi: SCPI!
    static var inflationProvider = InflationProvider()

    // MARK: Helpers

    override class func setUp() {
        super.setUp()
        SCPItests.scpi = SCPI(for: SCPItests.self,
                              from                 : nil,
                              dateDecodingStrategy : .iso8601,
                              keyDecodingStrategy  : .useDefaultKeys)
        SCPI.setSimulationMode(to: .deterministic)
        SCPI.setInflationProvider(SCPItests.inflationProvider)
        SCPI.setFiscalModelProvider(
            Fiscal.Model(for: FiscalModelTests.self,
                         from                 : nil,
                         dateDecodingStrategy : .iso8601,
                         keyDecodingStrategy  : .useDefaultKeys)
                .initialized())
        print(SCPItests.scpi!)
    }

    // MARK: Tests

    func test_value() {
        var currentValue = SCPItests.scpi.value(atEndOf: 2020)
        XCTAssertEqual(1000 * 0.9, currentValue)

        currentValue = SCPItests.scpi.value(atEndOf: 2022)
        XCTAssertEqual(1000 * 0.9, currentValue)

        currentValue = SCPItests.scpi.value(atEndOf: 2023)
        XCTAssertEqual(0, currentValue)
    }

    func test_revenue() {
        var revenue = SCPItests.scpi.yearlyRevenue(during: 2020)
        XCTAssertEqual(1000.0 * (3.56 - 10.0) / 100.0, revenue.revenue)

        revenue = SCPItests.scpi.yearlyRevenue(during: 2022)
        XCTAssertEqual(1000.0 * (3.56 - 10.0) / 100.0, revenue.revenue)

        revenue = SCPItests.scpi.yearlyRevenue(during: 2023)
        XCTAssertEqual(0.0, revenue.revenue)
    }

    func test_is_owned() {
        XCTAssertFalse(SCPItests.scpi.isOwned(during: 2018))
        XCTAssertTrue(SCPItests.scpi.isOwned(during: 2019))
        XCTAssertFalse(SCPItests.scpi.isOwned(during: 2023))
    }

    func test_liquidatedValue() {
        var vente = SCPItests.scpi.liquidatedValue(2021)
        XCTAssertEqual(0, vente.revenue)

        vente = SCPItests.scpi.liquidatedValue(2022)
        XCTAssertEqual(1000 * 0.9, vente.revenue)
        XCTAssertEqual(-1000 * 0.1, vente.capitalGain)
        XCTAssertEqual(0, vente.socialTaxes)
        XCTAssertEqual(0, vente.irpp)
        XCTAssertEqual(vente.revenue, vente.netRevenue)

        vente = SCPItests.scpi.liquidatedValue(2023)
        XCTAssertEqual(0, vente.revenue)
    }
}
