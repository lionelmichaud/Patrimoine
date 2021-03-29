//
//  Ownership.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 01/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class OwnershipTests: XCTestCase {
    static var fullOwner1     : Owner!
    static var fullOwner2     : Owner!
    static var bareOwner1     : Owner!
    static var bareOwner2     : Owner!
    static var usufructOwner1 : Owner!
    static var usufructOwner2 : Owner!
    
    static var fullOwners     = Owners()
    static var bareOwners     = Owners()
    static var usufructOwners = Owners()
    
    static var ownership = Ownership()
    
    // MARK: - Helpers
    
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
    
    override class func setUp() {
        super.setUp()
        Ownership.setFiscalModelProvider(
            Fiscal.Model(for: FiscalModelTests.self,
                         from                 : nil,
                         dateDecodingStrategy : .iso8601,
                         keyDecodingStrategy  : .useDefaultKeys)
                .initialized())
    }
    
    override func setUpWithError() throws {
        OwnershipTests.fullOwner1 = Owner(name     : "Owner1 de 65 ans en 2020",
                                          fraction : 20)
        OwnershipTests.fullOwner2 = Owner(name     : "Owner2 de 55 ans en 2020",
                                          fraction : 80)
        OwnershipTests.fullOwners = [OwnershipTests.fullOwner1,
                                     OwnershipTests.fullOwner2]
        
        OwnershipTests.bareOwner1 = Owner(name     : "bareOwner1",
                                          fraction : 10)
        OwnershipTests.bareOwner2 = Owner(name     : "bareOwner2",
                                          fraction : 90)
        OwnershipTests.bareOwners = [OwnershipTests.bareOwner1,
                                     OwnershipTests.bareOwner2]
        
        OwnershipTests.usufructOwner1 = Owner(name     : "usufructOwner1",
                                              fraction : 30)
        OwnershipTests.usufructOwner2 = Owner(name     : "usufructOwner2",
                                              fraction : 70)
        OwnershipTests.usufructOwners = [OwnershipTests.usufructOwner1,
                                         OwnershipTests.usufructOwner2]
        
        OwnershipTests.ownership.fullOwners = OwnershipTests.fullOwners
        OwnershipTests.ownership.bareOwners = OwnershipTests.bareOwners
        OwnershipTests.ownership.usufructOwners = OwnershipTests.usufructOwners
        OwnershipTests.ownership.isDismembered = false
        OwnershipTests.ownership.setDelegateForAgeOf(delegate: OwnershipTests.ageOf)
    }
    
    // MARK: - Tests

    func test_isValid() {
        XCTAssertTrue(OwnershipTests.ownership.isValid)
        
        OwnershipTests.ownership.isDismembered  = true
        OwnershipTests.ownership.bareOwners     = OwnershipTests.bareOwners
        OwnershipTests.ownership.usufructOwners = OwnershipTests.usufructOwners
        XCTAssertTrue(OwnershipTests.ownership.isValid)
        
        OwnershipTests.ownership.usufructOwners[0].fraction = 40
        XCTAssertFalse(OwnershipTests.ownership.isValid)
    }
    
    func test_isAFullOwner() {
        OwnershipTests.ownership.isDismembered = false
        XCTAssertTrue(OwnershipTests.ownership.isAFullOwner(ownerName: OwnershipTests.fullOwner1.name))
        XCTAssertFalse(OwnershipTests.ownership.isAFullOwner(ownerName: "Truc"))
        
        OwnershipTests.ownership.isDismembered = true
        XCTAssertFalse(OwnershipTests.ownership.isAFullOwner(ownerName: OwnershipTests.fullOwner1.name))
    }
    
    func test_isAnUsufructOwner() {
        OwnershipTests.ownership.isDismembered = false
        XCTAssertFalse(OwnershipTests.ownership.isAnUsufructOwner(ownerName: OwnershipTests.usufructOwner1.name))
        XCTAssertFalse(OwnershipTests.ownership.isAnUsufructOwner(ownerName: "Truc"))
        OwnershipTests.ownership.isDismembered = true
        XCTAssertTrue(OwnershipTests.ownership.isAnUsufructOwner(ownerName: OwnershipTests.fullOwner1.name))
    }
    
    func test_isABareOwner() {
        OwnershipTests.ownership.isDismembered = true
        XCTAssertTrue(OwnershipTests.ownership.isABareOwner(ownerName: OwnershipTests.fullOwner2.name))
    }
    
    func test_receivesRevenues() {
        OwnershipTests.ownership.isDismembered = false
        XCTAssertTrue(OwnershipTests.ownership.receivesRevenues(ownerName: OwnershipTests.fullOwner1.name))
        
        OwnershipTests.ownership.isDismembered = true
        XCTAssertTrue(OwnershipTests.ownership.receivesRevenues(ownerName: OwnershipTests.fullOwner2.name))
    }
    
    func test_demembrementPercentage() throws {
        XCTAssertThrowsError(try OwnershipTests.ownership.demembrementPercentage(atEndOf: 2020)) { error in
            XCTAssertEqual(error as! OwnershipError, OwnershipError.tryingToDismemberUnUndismemberedAsset)
        }
        
        OwnershipTests.ownership.isDismembered = true
        var demembrementPct = try OwnershipTests.ownership.demembrementPercentage(atEndOf: 2020)
        var bareValuePctTheory = 20.0 * 0.6 + 80.0 * 0.5
        var usufructPctTheory  = 20.0 * 0.4 + 80.0 * 0.5
        XCTAssertEqual(bareValuePctTheory, demembrementPct.bareValuePercent)
        XCTAssertEqual(usufructPctTheory, demembrementPct.usufructPercent)
        
        demembrementPct = try OwnershipTests.ownership.demembrementPercentage(atEndOf: 2030)
        bareValuePctTheory = 20.0 * 0.7 + 80.0 * 0.6
        usufructPctTheory  = 20.0 * 0.3 + 80.0 * 0.4
        XCTAssertEqual(bareValuePctTheory, demembrementPct.bareValuePercent)
        XCTAssertEqual(usufructPctTheory, demembrementPct.usufructPercent)
    }
    
    func test_ownedValue_bien_non_demembre() {
        let value = OwnershipTests.ownership.ownedValue(by: OwnershipTests.fullOwner2.name,
                                                        ofValue: 1000.0,
                                                        atEndOf: 2020,
                                                        evaluationMethod: .legalSuccession)
        let theory = 1000.0 * OwnershipTests.fullOwner2.fraction / 100.0
        XCTAssertEqual(theory, value)
    }
    
    func test_ownedValue_bien_demembre_ifi_isf() {
        OwnershipTests.ownership.isDismembered = true
        OwnershipTests.ownership.bareOwners     = OwnershipTests.bareOwners
        OwnershipTests.ownership.usufructOwners = OwnershipTests.usufructOwners
        
        var value = OwnershipTests.ownership.ownedValue(by: OwnershipTests.usufructOwner2.name,
                                                        ofValue: 1000.0,
                                                        atEndOf: 2020,
                                                        evaluationMethod: .ifi)
        var theory = 1000.0 * OwnershipTests.usufructOwner2.fraction / 100.0
        XCTAssertEqual(theory, value)
        
        value = OwnershipTests.ownership.ownedValue(by: OwnershipTests.fullOwner2.name,
                                                    ofValue: 1000.0,
                                                    atEndOf: 2020,
                                                    evaluationMethod: .ifi)
        theory = 0.0
        XCTAssertEqual(theory, value)
    }
    
    func test_ownedValue_bien_demembre_legalSuccession_lifeInsuranceSuccession_patrimoine() {
        var ownership = Ownership(ageOf: OwnershipTests.ageOf)
        ownership.isDismembered = true
        
        // un seul usufruitier + un seul nupropriétaire
        ownership.usufructOwners = [Owner(name: "Usufruitier",    fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Nupropriétaire", fraction : 100)]
        var value = ownership.ownedValue(by: "Usufruitier",
                                         ofValue: 1000.0,
                                         atEndOf: 2020,
                                         evaluationMethod: .legalSuccession)
        var theory = 1000.0 * 0.2
        XCTAssertEqual(theory, value)
        
        value = ownership.ownedValue(by: "Nupropriétaire",
                                     ofValue: 1000.0,
                                     atEndOf: 2020,
                                     evaluationMethod: .legalSuccession)
        theory = 1000.0 * 0.8
        XCTAssertEqual(theory, value)
        
        // plusieurs usufruitiers + un seul nupropriétaire
        ownership.usufructOwners = [Owner(name: "Usufruitier1",   fraction :  40),
                                    Owner(name: "Usufruitier2",   fraction :  60)]
        ownership.bareOwners     = [Owner(name: "Nupropriétaire1", fraction : 100)]
        
        value = ownership.ownedValue(by: "Usufruitier1",
                                     ofValue: 1000.0,
                                     atEndOf: 2020,
                                     evaluationMethod: .legalSuccession)
        var theoryUS1 = (0.4 * 1000.0) * 0.2
        XCTAssertEqual(theoryUS1, value)
        value = ownership.ownedValue(by: "Usufruitier2",
                                     ofValue: 1000.0,
                                     atEndOf: 2020,
                                     evaluationMethod: .legalSuccession)
        var theoryUS2 = (0.6 * 1000.0) * 0.2
        XCTAssertEqual(theoryUS2, value)
        value = ownership.ownedValue(by: "Nupropriétaire1",
                                     ofValue: 1000.0,
                                     atEndOf: 2020,
                                     evaluationMethod: .legalSuccession)
        var theoryNP1 = (1.0 * 1000.0) * 0.8
        XCTAssertEqual(theoryNP1, value)
        
        // un seul usufruitier + plusieur nupropriétaires
        ownership.usufructOwners = [Owner(name: "Usufruitier1",    fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Nupropriétaire1", fraction :  60),
                                    Owner(name: "Nupropriétaire2", fraction :  40)]
        
        value = ownership.ownedValue(by: "Usufruitier1",
                                     ofValue: 1000.0,
                                     atEndOf: 2020,
                                     evaluationMethod: .legalSuccession)
        theoryUS1 = (1.0 * 1000.0) * 0.2
        XCTAssertEqual(theoryUS1, value)
        value = ownership.ownedValue(by: "Nupropriétaire1",
                                     ofValue: 1000.0,
                                     atEndOf: 2020,
                                     evaluationMethod: .legalSuccession)
        theoryNP1 = (0.8 * 1000.0) * 0.6
        XCTAssertEqual(theoryNP1, value)
        value = ownership.ownedValue(by: "Nupropriétaire2",
                                     ofValue: 1000.0,
                                     atEndOf: 2020,
                                     evaluationMethod: .legalSuccession)
        theoryNP1 = (0.8 * 1000.0) * 0.4
        XCTAssertEqual(theoryNP1, value)
        
        // plusieur usufruitiers + plusieur nupropriétaires
        ownership.usufructOwners = [Owner(name: "Usufruitier1",    fraction : 70),
                                    Owner(name: "Usufruitier2",    fraction : 30)]
        ownership.bareOwners     = [Owner(name: "Nupropriétaire1", fraction : 60),
                                    Owner(name: "Nupropriétaire2", fraction : 40)]
        
        value = ownership.ownedValue(by: "Usufruitier1",
                                     ofValue: 1000.0,
                                     atEndOf: 2020,
                                     evaluationMethod: .legalSuccession)
        theoryUS1 = (0.7 * 1000.0) * 0.2
        XCTAssertEqual(theoryUS1, value)
        value = ownership.ownedValue(by: "Usufruitier2",
                                     ofValue: 1000.0,
                                     atEndOf: 2020,
                                     evaluationMethod: .legalSuccession)
        theoryUS2 = (0.3 * 1000.0) * 0.2
        XCTAssertEqual(theoryUS2, value)
        value = ownership.ownedValue(by: "Nupropriétaire1",
                                     ofValue: 1000.0,
                                     atEndOf: 2020,
                                     evaluationMethod: .legalSuccession)
        theoryNP1 = (0.8 * 1000.0) * 0.6
        XCTAssertEqual(theoryNP1, value)
        value = ownership.ownedValue(by: "Nupropriétaire2",
                                     ofValue: 1000.0,
                                     atEndOf: 2020,
                                     evaluationMethod: .legalSuccession)
        theoryNP1 = (0.8 * 1000.0) * 0.4
        XCTAssertEqual(theoryNP1, value)
        
        // plusieur usufruitiers + plusieur nupropriétaires
        ownership.usufructOwners = [Owner(name: "Owner1 de 65 ans en 2020", fraction : 70),
                                    Owner(name: "Owner2 de 55 ans en 2020", fraction : 30)]
        ownership.bareOwners     = [Owner(name: "Nupropriétaire1", fraction : 60),
                                    Owner(name: "Nupropriétaire2", fraction : 40)]
        
        value = ownership.ownedValue(by: "Owner1 de 65 ans en 2020",
                                     ofValue: 1000.0,
                                     atEndOf: 2030,
                                     evaluationMethod: .legalSuccession)
        theoryUS1 = (0.7 * 1000.0) * 0.3
        XCTAssertEqual(theoryUS1, value)
        value = ownership.ownedValue(by: "Owner2 de 55 ans en 2020",
                                     ofValue: 1000.0,
                                     atEndOf: 2030,
                                     evaluationMethod: .legalSuccession)
        theoryUS2 = (0.3 * 1000.0) * 0.4
        XCTAssertEqual(theoryUS2, value)
        value = ownership.ownedValue(by: "Nupropriétaire1",
                                     ofValue: 1000.0,
                                     atEndOf: 2030,
                                     evaluationMethod: .legalSuccession)
        theoryNP1 = ((0.7 * 1000.0) * 0.7 + (0.3 * 1000.0) * 0.6) * 0.6
        XCTAssertEqual(theoryNP1, value)
        value = ownership.ownedValue(by: "Nupropriétaire2",
                                     ofValue: 1000.0,
                                     atEndOf: 2030,
                                     evaluationMethod: .legalSuccession)
        theoryNP1 = ((0.7 * 1000.0) * 0.7 + (0.3 * 1000.0) * 0.6) * 0.4
        XCTAssertEqual(theoryNP1, value)
    }
}
