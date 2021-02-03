//
//  InheritanceDonationTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 14/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class InheritanceDonationTests: XCTestCase {
    
    static var inheritanceDonation: InheritanceDonation!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = InheritanceDonation.Model(
            for                  : InheritanceDonationTests.self,
            from                 : nil,
            dateDecodingStrategy : .iso8601,
            keyDecodingStrategy  : .useDefaultKeys)
        InheritanceDonationTests.inheritanceDonation = InheritanceDonation(model: model)
        try! InheritanceDonationTests.inheritanceDonation.initialize()
    }
    
    // MARK: Tests

    func test_calcul_heritage_enfant() throws {
        var partSuccession: Double
        var theory: Double
        let abatLigneDirecte = 100_000.0
        
        partSuccession = 100_000.0
        var heritage = try InheritanceDonationTests.inheritanceDonation.heritageOfChild(
            partSuccession: partSuccession)
        theory = 0.0
        XCTAssertEqual(partSuccession, heritage.netAmount)
        
        partSuccession = 108_071.0
        heritage = try InheritanceDonationTests.inheritanceDonation.heritageOfChild(
            partSuccession: partSuccession)
        theory =
            partSuccession
            - 0.05 * (partSuccession - abatLigneDirecte)
        XCTAssertEqual(theory, heritage.netAmount)

        partSuccession = 110_000.0
        heritage = try InheritanceDonationTests.inheritanceDonation.heritageOfChild(
            partSuccession: partSuccession)
        theory =
            partSuccession
            - 0.05 * 8072.0
            - 0.1 * (partSuccession - abatLigneDirecte - 8072.0)
        XCTAssert(theory.isApproximatelyEqual(to: heritage.netAmount))
        
        partSuccession = 170_000.0
        heritage = try InheritanceDonationTests.inheritanceDonation.heritageOfChild(
            partSuccession: partSuccession)
        theory =
            partSuccession
            - 0.05 * 8072.0
            - 0.10 * (12109.0 - 8072.0)
            - 0.15 * (15932.0 - 12109.0)
            - 0.20 * (partSuccession - abatLigneDirecte - 15932.0)
        XCTAssert(theory.isApproximatelyEqual(to: heritage.netAmount))
    }
    
    func test_calcul_donation_conjoint() throws {
        var donation: Double
        var theory: Double
        let abatConjoint = 80_724.0
        
        donation = 80_000.0
        var heritage = try InheritanceDonationTests.inheritanceDonation.donationToSpouse(
            donation: donation)
        theory = 0.0
        XCTAssertEqual(donation, heritage.netAmount)
        
        donation = 88_071.0
        heritage = try InheritanceDonationTests.inheritanceDonation.donationToSpouse(
            donation: donation)
        theory =
            donation
            - 0.05 * (donation - abatConjoint)
        XCTAssertEqual(theory, heritage.netAmount)
        
        donation = 92_000.0
        heritage = try InheritanceDonationTests.inheritanceDonation.donationToSpouse(
            donation: donation)
        theory =
            donation
            - 0.05 * 8072.0
            - 0.1 * (donation - abatConjoint - 8072.0)
        XCTAssert(theory.isApproximatelyEqual(to: heritage.netAmount))
        
        donation = 95_000.0
        heritage = try InheritanceDonationTests.inheritanceDonation.donationToSpouse(
            donation: donation)
        theory =
            donation
            - 0.05 * 8072.0
            - 0.1 * (12109.0 - 8072.0)
            - 0.15 * (donation - abatConjoint - 12109.0)
        XCTAssert(theory.isApproximatelyEqual(to: heritage.netAmount))
        
        donation = 270_000.0
        heritage = try InheritanceDonationTests.inheritanceDonation.donationToSpouse(
            donation: donation)
        theory =
            donation
            - 0.05 * 8072.0
            - 0.10 * (12109.0 - 8072.0)
            - 0.15 * (15932.0 - 12109.0)
            - 0.20 * (donation - abatConjoint - 15932.0)
        XCTAssert(theory.isApproximatelyEqual(to: heritage.netAmount))
    }
}

class FiscalOptionTests: XCTestCase {
    
    func test_shared_value() {
        var nbChildren   : Int
        var spouseAge    : Int
        var fiscalOption : InheritanceDonation.FiscalOption
        
        // test de fullUsufruct
        nbChildren = 0
        spouseAge  = 75
        fiscalOption = .fullUsufruct
        
        var result = fiscalOption.sharedValues(
            nbChildren : nbChildren,
            spouseAge  : spouseAge)
        XCTAssertEqual(1.0, result.forSpouse)
        XCTAssertEqual(0.0, result.forChild)

        nbChildren = 2
        spouseAge  = 65
        
        result = fiscalOption.sharedValues(
            nbChildren : nbChildren,
            spouseAge  : spouseAge)
        XCTAssertEqual(0.4, result.forSpouse)
        XCTAssertEqual(0.6 / Double(nbChildren), result.forChild)

        // test de quotiteDisponible
        nbChildren = 0
        spouseAge  = 75
        fiscalOption = .quotiteDisponible
        
        result = fiscalOption.sharedValues(
            nbChildren : nbChildren,
            spouseAge  : spouseAge)
        XCTAssertEqual(1.0, result.forSpouse)
        XCTAssertEqual(0.0, result.forChild)
        
        nbChildren = 2
        spouseAge  = 75
        
        result = fiscalOption.sharedValues(
            nbChildren : nbChildren,
            spouseAge  : spouseAge)
        XCTAssertEqual(1.0/3.0, result.forSpouse)
        XCTAssertEqual((1.0 - 1.0/3.0) / Double(nbChildren), result.forChild)

        // test de usufructPlusBare
        nbChildren = 0
        spouseAge  = 75
        fiscalOption = .usufructPlusBare
        
        result = fiscalOption.sharedValues(
            nbChildren : nbChildren,
            spouseAge  : spouseAge)
        XCTAssertEqual(1.0, result.forSpouse)
        XCTAssertEqual(0.0, result.forChild)
        
        nbChildren = 2
        spouseAge  = 75
        
        result = fiscalOption.sharedValues(
            nbChildren : nbChildren,
            spouseAge  : spouseAge)
        XCTAssertEqual(0.25 + 0.3 * 0.75, result.forSpouse)
        XCTAssertEqual((1.0 - (0.25 + 0.3 * 0.75)) / Double(nbChildren), result.forChild)
    }
}

class LifeInsuranceInheritanceTests: XCTestCase {
    
    static var lifeInsuranceInheritance: LifeInsuranceInheritance!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = LifeInsuranceInheritance.Model(
            for                  : LifeInsuranceInheritanceTests.self,
            from                 : nil,
            dateDecodingStrategy : .iso8601,
            keyDecodingStrategy  : .useDefaultKeys)
        LifeInsuranceInheritanceTests.lifeInsuranceInheritance = LifeInsuranceInheritance(model: model)
        try! LifeInsuranceInheritanceTests.lifeInsuranceInheritance.initialize()
    }
    
    func date(year: Int, month: Int, day: Int) -> Date {
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : year,
                                         month    : month,
                                         day      : day)
        return Date.calendar.date(from: dateRefComp)!
    }
    
    // MARK: Tests

    func test_calcul_heritage_assurance_vie_par_enfant() throws {
        var partSuccession : Double
        var taxTheory      : Double
        
        partSuccession = 100_000.0
        var resultat = try LifeInsuranceInheritanceTests.lifeInsuranceInheritance.heritageOfChild(
            partSuccession: partSuccession)
        taxTheory = 0.0
        XCTAssertEqual(taxTheory, resultat.taxe)
        XCTAssertEqual(partSuccession - taxTheory, resultat.netAmount)

        partSuccession = 160_000.0
        resultat = try LifeInsuranceInheritanceTests.lifeInsuranceInheritance.heritageOfChild(
            partSuccession: partSuccession)
        taxTheory = (partSuccession - 152_500.0) * 0.2
        XCTAssertEqual(taxTheory, resultat.taxe)
        XCTAssertEqual(partSuccession - taxTheory, resultat.netAmount)
        
        partSuccession = 1_000_000.0
        resultat = try LifeInsuranceInheritanceTests.lifeInsuranceInheritance.heritageOfChild(
            partSuccession: partSuccession)
        taxTheory = (852_500.0 - 152_500.0) * 0.2 + (partSuccession - 852_500.0) * 0.3125
        XCTAssertEqual(taxTheory, resultat.taxe)
        XCTAssertEqual(partSuccession - taxTheory, resultat.netAmount)
    }
    
    func test_calcul_heritage_assurance_vie_par_conjoint() {
        var partSuccession: Double
        
        partSuccession = 1_000_000.0
        let resultat = LifeInsuranceInheritanceTests.lifeInsuranceInheritance.heritageToConjoint(
            partSuccession: partSuccession)
        XCTAssertEqual(0.0, resultat.taxe)
        XCTAssertEqual(partSuccession, resultat.netAmount)
    }
}
