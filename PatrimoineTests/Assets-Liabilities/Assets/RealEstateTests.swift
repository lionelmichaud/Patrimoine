//
//  RealEstateTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 11/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class RealEstateTests: XCTestCase {

    static var re: RealEstateAsset!

    override class func setUp() {
        super.setUp()
        RealEstateTests.re = RealEstateAsset(
            for: RealEstateTests.self,
            from                 : nil,
            dateDecodingStrategy : .iso8601,
            keyDecodingStrategy  : .useDefaultKeys)
        RealEstateAsset.setFiscalModelProvider(
            Fiscal.Model(for: FiscalModelTests.self,
                         from                 : nil,
                         dateDecodingStrategy : .iso8601,
                         keyDecodingStrategy  : .useDefaultKeys)
                .initialized())
        print(RealEstateTests.re!)
    }

    func test_sellingPriceAfterTaxes() {
        var re = RealEstateTests.re

        // bien vendu
        var sellingPriceAfterTaxes = re!.sellingPriceAfterTaxes
        XCTAssertNotEqual(0, sellingPriceAfterTaxes)

        // bien vendu
        re?.willBeSold = false
        sellingPriceAfterTaxes = re!.sellingPriceAfterTaxes
        XCTAssertEqual(0, sellingPriceAfterTaxes)
    }

    func test_value() {
        // pas encore acheté
        var currentValue = RealEstateTests.re.value(atEndOf: 2000)
        XCTAssertEqual(0, currentValue)

        // acheté
        currentValue = RealEstateTests.re.value(atEndOf: 2005)
        XCTAssertEqual(100_000, currentValue)

        // acheté
        currentValue = RealEstateTests.re.value(atEndOf: 2030)
        XCTAssertEqual(100_000, currentValue)

        // vendu
        currentValue = RealEstateTests.re.value(atEndOf: 2031)
        XCTAssertEqual(0, currentValue)
    }

    func test_IFI_value() {
        // pas encore acheté
        var currentValue = RealEstateTests.re.ifiValue(atEndOf: 2000)
        XCTAssertEqual(0, currentValue)

        // ni habité, ni loué
        currentValue = RealEstateTests.re.ifiValue(atEndOf: 2006)
        XCTAssertEqual(100_000, currentValue)

        // habité
        currentValue = RealEstateTests.re.ifiValue(atEndOf: 2010)
        XCTAssertEqual(100_000.0 * 0.7, currentValue)

        // loué
        currentValue = RealEstateTests.re.ifiValue(atEndOf: 2016)
        XCTAssertEqual(100_000 * 0.8, currentValue)

        // vendu
        currentValue = RealEstateTests.re.ifiValue(atEndOf: 2031)
        XCTAssertEqual(0, currentValue)
    }

    func test_inheritance_value() {
        // pas encore acheté
        var currentValue = RealEstateTests.re.inheritanceValue(atEndOf: 2000)
        XCTAssertEqual(0, currentValue)

        // ni habité, ni loué
        currentValue = RealEstateTests.re.inheritanceValue(atEndOf: 2006)
        XCTAssertEqual(100_000, currentValue)

        // habité
        currentValue = RealEstateTests.re.inheritanceValue(atEndOf: 2010)
        XCTAssertEqual(100_000.0 * 0.8, currentValue)

        // loué
        currentValue = RealEstateTests.re.inheritanceValue(atEndOf: 2016)
        XCTAssertEqual(100_000, currentValue)

        // vendu
        currentValue = RealEstateTests.re.inheritanceValue(atEndOf: 2031)
        XCTAssertEqual(0, currentValue)
    }

    func test_est_habité() {
        XCTAssertFalse(RealEstateTests.re.isInhabited(during: 2009))
        XCTAssertTrue(RealEstateTests.re.isInhabited(during: 2010))
        XCTAssertTrue(RealEstateTests.re.isInhabited(during: 2015))
        XCTAssertFalse(RealEstateTests.re.isInhabited(during: 2016))
    }
    func test_est_loué() {
        XCTAssertFalse(RealEstateTests.re.isRented(during: 2015))
        XCTAssertTrue(RealEstateTests.re.isRented(during: 2016))
        XCTAssertTrue(RealEstateTests.re.isRented(during: 2019))
        XCTAssertFalse(RealEstateTests.re.isRented(during: 2020))
    }
}
