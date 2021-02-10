//
//  OwnershipTransferLifeInsuranceTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 06/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class OwnershipTransferLifeInsuranceTests: XCTestCase {
    
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
    
    func test_transfer_Life_Insurance_non_demembrée () throws {
        var ownership = Ownership(ageOf: OwnershipTests.ageOf)
        var clause = LifeInsuranceClause()
        
        // (B) le capital de l'assurance vie n'est pas démembré
        // (1) le défunt est un des PP propriétaires du capital de l'assurance vie
        // (a) il n'y a qu'un seul PP de l'assurance vie
        // (1) la clause bénéficiaire de l'assurane vie est démembrée
        print("Cas B.1.a.1: ")
        print("Test 1a")
        ownership.isDismembered  = false
        ownership.fullOwners     = [Owner(name : "Défunt", fraction  : 100)]
        ownership.usufructOwners = []
        ownership.bareOwners     = []
        
        clause.isDismembered     = true
        clause.usufructRecipient = "Conjoint"
        clause.bareRecipients    = ["Enfant 1", "Enfant 2"]
        
        print("AVANT : " + ownership.description)
        print(clause)
        
        try ownership.transferLifeInsuranceOfDecedent(
            of          : "Défunt",
            accordingTo : clause)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertTrue(ownership.bareOwners == [Owner(name: "Enfant 1", fraction : 50),
                                               Owner(name: "Enfant 2", fraction : 50)])
        print("APRES : " + ownership.description)
        
        print("Test 1b")
        ownership.isDismembered  = false
        ownership.fullOwners     = [Owner(name : "Défunt", fraction  : 100)]
        ownership.usufructOwners = []
        ownership.bareOwners     = []
        
        clause.isDismembered     = true
        clause.usufructRecipient = "Conjoint"
        clause.bareRecipients    = ["Enfant 1"]
        
        print("AVANT : " + ownership.description)
        print(clause)
        
        try ownership.transferLifeInsuranceOfDecedent(
            of          : "Défunt",
            accordingTo : clause)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertTrue(ownership.bareOwners == [Owner(name: "Enfant 1", fraction : 100)])
        print("APRES : " + ownership.description)

        // (B) le capital de l'assurance vie n'est pas démembré
        // (1) le défunt est un des PP propriétaires du capital de l'assurance vie
        // (a) il n'y a qu'un seul PP de l'assurance vie
        // (2) la clause bénéficiaire de l'assurane vie n'est pas démembrée
        print("Cas B.1.a.2: ")
        ownership.isDismembered  = false
        ownership.fullOwners     = [Owner(name : "Défunt", fraction  : 100)]
        ownership.usufructOwners = []
        ownership.bareOwners     = []
        
        clause.isDismembered     = false
        clause.fullRecipients    = ["Conjoint"]
        clause.usufructRecipient = ""
        clause.bareRecipients    = []
        
        print("AVANT : " + ownership.description)
        print(clause)
        
        try ownership.transferLifeInsuranceOfDecedent(
            of               : "Défunt",
            accordingTo      : clause)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertEqual(ownership.bareOwners, [])
        XCTAssertEqual(ownership.usufructOwners, [])
        print("APRES : " + ownership.description)
        
        // (B) le capital de l'assurance vie n'est pas démembré
        // (2) le défunt n'est pas un des PP propriétaires du capital de l'assurance vie
        print("Cas B.2: ")
        ownership.isDismembered  = false
        ownership.fullOwners     = [Owner(name : "Lionel", fraction  : 100)]
        ownership.usufructOwners = []
        ownership.bareOwners     = []
        
        clause.isDismembered     = false
        clause.fullRecipients    = ["Conjoint"]
        clause.usufructRecipient = ""
        clause.bareRecipients    = []
        
        print("AVANT : " + ownership.description)
        print(clause)
        
        try ownership.transferLifeInsuranceOfDecedent(
            of               : "Défunt",
            accordingTo      : clause)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [Owner(name: "Lionel", fraction : 100)])
        XCTAssertEqual(ownership.bareOwners, [])
        XCTAssertEqual(ownership.usufructOwners, [])
        print("APRES : " + ownership.description)
    }
    
    func test_transfer_Life_Insurance_demembrée () throws {
        var ownership = Ownership(ageOf: OwnershipTests.ageOf)
        let clause = LifeInsuranceClause()
        
        // (A) le capital de l'assurane vie est démembré
        // (1) le défunt est usufruitier
        print("Cas A.1:")
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Défunt", fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Conjoint",   fraction : 50),
                                    Owner(name: "Enfant 1", fraction : 30),
                                    Owner(name: "Enfant 2", fraction : 20)]

        print("AVANT : " + ownership.description)
        print(clause)
        
        try ownership.transferLifeInsuranceOfDecedent(
            of          : "Défunt",
            accordingTo : clause)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssert(ownership.fullOwners == [Owner(name: "Conjoint", fraction : 50),
                                           Owner(name: "Enfant 1", fraction : 30),
                                           Owner(name: "Enfant 2", fraction : 20)])
        XCTAssertEqual(ownership.bareOwners, [])
        XCTAssertEqual(ownership.usufructOwners, [])
        print("APRES : " + ownership.description)

        // (A) le capital de l'assurane vie est démembré
        // (3) le défunt n'est ni usufruitier ni nue-propriétaire => on ne fait rien
        print("Cas A.3:")
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Lionel", fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Conjoint",   fraction : 50),
                                    Owner(name: "Enfant 1", fraction : 30),
                                    Owner(name: "Enfant 2", fraction : 20)]
        
        print("AVANT : " + ownership.description)
        print(clause)
        
        try ownership.transferLifeInsuranceOfDecedent(
            of          : "Défunt",
            accordingTo : clause)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [])
        XCTAssert(ownership.bareOwners == [Owner(name: "Conjoint",   fraction : 50),
                                           Owner(name: "Enfant 1", fraction : 30),
                                           Owner(name: "Enfant 2", fraction : 20)])
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Lionel", fraction : 100)])
        print("APRES : " + ownership.description)
   }
}
