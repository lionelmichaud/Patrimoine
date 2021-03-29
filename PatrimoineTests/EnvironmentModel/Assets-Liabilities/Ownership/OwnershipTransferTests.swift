//
//  OwnershipTransferTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 06/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class OwnershipTransferTests: XCTestCase {
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
    
    func test_transfert_bien_démembré_avec_conjoint_avec_enfants() throws {
        let ownershipModelIsBuggy = true
        
        var ownership = Ownership(ageOf: OwnershipTests.ageOf)
        
        // (A) le bien est démembré
        ownership.isDismembered = true
        
        // (1) il y a un conjoint survivant
        //      le défunt peut être usufruitier et/ou nue-propriétaire
        // (a) le défunt était usufruitier
        // (2) le défunt était seulement usufruitier
        print("Cas A.1.a.2: ")
        print("Test 1")
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Défunt",   fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Enfant 1", fraction : 60),
                                    Owner(name: "Enfant 2", fraction : 40)]
        print("AVANT : " + ownership.description)
        
        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : ["Enfant 1", "Enfant 2"],
            spouseName         : "Conjoint",
            spouseFiscalOption : .fullUsufruct)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertTrue(ownership.fullOwners == [Owner(name: "Enfant 1", fraction : 60),
                                               Owner(name: "Enfant 2", fraction : 40)])
        print("APRES : " + ownership.description)
        
        print("Test 2")
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Défunt",   fraction : 70),
                                    Owner(name: "Conjoint", fraction : 30)]
        ownership.bareOwners     = [Owner(name: "Enfant 1", fraction : 50),
                                    Owner(name: "Enfant 2", fraction : 20),
                                    Owner(name: "Conjoint", fraction : 30)]
        print("AVANT : " + ownership.description)
        
        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : ["Enfant 1", "Enfant 2"],
            spouseName         : "Conjoint",
            spouseFiscalOption : .fullUsufruct)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertTrue(ownership.fullOwners == [Owner(name: "Conjoint", fraction : 30),
                                               Owner(name: "Enfant 1", fraction : 70.0 * 50.0 / 70.0),
                                               Owner(name: "Enfant 2", fraction : 70.0 * 20.0 / 70.0)])
        print("APRES : " + ownership.description)
        
        if !ownershipModelIsBuggy {
            // (b) le défunt était seulement nue-propriétaire
            print("Cas A.1.b: ")
            
            ownership.isDismembered = true
            ownership.usufructOwners = [Owner(name: "Conjoint", fraction : 100)]
            ownership.bareOwners     = [Owner(name: "Défunt",   fraction : 50),
                                        Owner(name: "Enfant 1", fraction : 30),
                                        Owner(name: "Enfant 2", fraction : 20)]
            print("AVANT : " + ownership.description)
            
            try ownership.transferOwnershipOf(
                decedentName       : "Défunt",
                chidrenNames       : ["Enfant 1", "Enfant 2"],
                spouseName         : "Conjoint",
                spouseFiscalOption : .fullUsufruct)
            
            XCTAssertTrue(ownership.isValid)
            XCTAssertTrue(ownership.isDismembered)
            XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
            XCTAssertTrue(ownership.fullOwners == [Owner(name: "Enfant 1", fraction : 30.0 + 50.0 / 2.0),
                                                   Owner(name: "Enfant 2", fraction : 40.0 + 50.0 / 2.0)])
            print("APRES : " + ownership.description)
        }
        print("Cas A.1.c: ")
        // (c) le défunt ne fait pas partie des usufruitires ni des nue-propriétaires
        // on ne fair rien
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Conjoint", fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Enfant 1", fraction : 60),
                                    Owner(name: "Enfant 2", fraction : 40)]
        let ownershipAvant = ownership
        print("AVANT : " + ownership.description)
        
        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : ["Enfant 1", "Enfant 2"],
            spouseName         : "Conjoint",
            spouseFiscalOption : .fullUsufruct)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertEqual(ownershipAvant, ownership)
        print("APRES : " + ownership.description)
    }
    
    func test_transfert_bien_démembré_sans_conjoint_avec_enfants() throws {
        var ownership = Ownership(ageOf: OwnershipTests.ageOf)
        
        // (A) le bien est démembré
        ownership.isDismembered = true
        
        // (2)  il n'y a pas de conjoint survivant
        //      mais il y a des enfants survivants
        // un seul usufruitier + un seul nupropriétaire + pas de conjoint
        print("Cas A.2: ")
        ownership.usufructOwners = [Owner(name: "Parent",    fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Enfant", fraction : 100)]
        print("AVANT : " + ownership.description)
        
        try ownership.transferOwnershipOf(
            decedentName       : "Parent",
            chidrenNames       : ["Enfant"],
            spouseName         : nil,
            spouseFiscalOption : nil)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [Owner(name: "Enfant", fraction : 100)])
        print("APRES : " + ownership.description)
        
        // un seul usufruitier + plusieurs nupropriétaires + pas de conjoint
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Parent",   fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Enfant 1", fraction : 60),
                                    Owner(name: "Enfant 2", fraction : 40)]
        print("AVANT : " + ownership.description)
        
        try ownership.transferOwnershipOf(
            decedentName       : "Parent",
            chidrenNames       : ["Enfant 1", "Enfant 2"],
            spouseName         : nil,
            spouseFiscalOption : nil)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertTrue(ownership.fullOwners == [Owner(name: "Enfant 1", fraction : 60),
                                               Owner(name: "Enfant 2", fraction : 40)])
        print("APRES : " + ownership.description)
    }
    
    func test_transfert_bien_non_démembré() throws {
        var ownership = Ownership(ageOf: OwnershipTests.ageOf)
        
        // (B) le bien n'est pas démembré
        ownership.isDismembered = false
        // (1) le défunt fait partie des plein-propriétaires
        print("Cas B.1.b: ")
        // (b) il n'y a pas de conjoint survivant
        // un seul usufruitier + plusieurs enfants + pas de conjoint
        ownership.fullOwners = [Owner(name: "Défunt", fraction : 100)]
        print("AVANT : " + ownership.description)
        
        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : ["Enfant 1", "Enfant 2"],
            spouseName         : nil,
            spouseFiscalOption : nil)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertTrue(ownership.fullOwners == [Owner(name: "Enfant 1", fraction : 50),
                                               Owner(name: "Enfant 2", fraction : 50)])
        print("APRES : " + ownership.description)
        
        // (a) il y a un conjoint survivant
        // un seul usufruitier + plusieurs enfants + un conjoint
        print("Cas B.1.a: ")
        print("Test 1a: fullUsufruct")
        ownership.isDismembered = false
        ownership.fullOwners = [Owner(name: "Défunt", fraction : 100)]
        print("AVANT : " + ownership.description)
        
        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : ["Enfant 1", "Enfant 2"],
            spouseName         : "Conjoint",
            spouseFiscalOption : .fullUsufruct)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertTrue(ownership.bareOwners == [Owner(name: "Enfant 1", fraction : 50),
                                               Owner(name: "Enfant 2", fraction : 50)])
        print("APRES : " + ownership.description)
        
        print("Test 1b: quotiteDisponible")
        ownership.isDismembered = false
        ownership.fullOwners = [Owner(name: "Défunt", fraction : 100)]
        print("AVANT : " + ownership.description)
        
        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : ["Enfant 1", "Enfant 2"],
            spouseName         : "Conjoint",
            spouseFiscalOption : .quotiteDisponible)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [])
        XCTAssertEqual(ownership.bareOwners, [])
        XCTAssertTrue(ownership.fullOwners == [Owner(name: "Conjoint", fraction : 100.0/3.0),
                                               Owner(name: "Enfant 1", fraction : 100.0/3.0),
                                               Owner(name: "Enfant 2", fraction : 100.0/3.0)])
        print("APRES : " + ownership.description)
        
        print("Test 1c: usufructPlusBare")
        ownership.isDismembered = false
        ownership.fullOwners = [Owner(name: "Défunt", fraction : 100)]
        print("AVANT : " + ownership.description)
        
        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : ["Enfant 1", "Enfant 2"],
            spouseName         : "Conjoint",
            spouseFiscalOption : .usufructPlusBare)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [])
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertTrue(ownership.bareOwners == [Owner(name: "Conjoint", fraction : 100.0/4.0),
                                               Owner(name: "Enfant 1", fraction : 100.0 * 3.0/8.0),
                                               Owner(name: "Enfant 2", fraction : 100.0 * 3.0/8.0)])
        print("APRES : " + ownership.description)
        
        print("Test 2: fullUsufruct")
        ownership.isDismembered = false
        ownership.fullOwners = [Owner(name: "Défunt", fraction : 70),
                                Owner(name: "Conjoint", fraction : 30)]
        print("AVANT : " + ownership.description)
        
        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : ["Enfant 1", "Enfant 2"],
            spouseName         : "Conjoint",
            spouseFiscalOption : .fullUsufruct)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertTrue(ownership.bareOwners == [Owner(name: "Conjoint", fraction : 30),
                                               Owner(name: "Enfant 1", fraction : 35),
                                               Owner(name: "Enfant 2", fraction : 35)])
        print("APRES : " + ownership.description)
        
        print("Test 3: usufructPlusBare")
        ownership.isDismembered = false
        ownership.fullOwners = [Owner(name: "Défunt", fraction : 70),
                                Owner(name: "Conjoint", fraction : 30)]
        print("AVANT : " + ownership.description)
        
        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : ["Enfant 1", "Enfant 2"],
            spouseName         : "Conjoint",
            spouseFiscalOption : .usufructPlusBare)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [])
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertTrue(ownership.bareOwners == [Owner(name: "Conjoint", fraction : 30.0 + 0.25 * 70.0),
                                               Owner(name: "Enfant 1", fraction : 0.75 * 70.0 / 2.0),
                                               Owner(name: "Enfant 2", fraction : 0.75 * 70.0 / 2.0)])
        print("APRES : " + ownership.description)
        
        print("Test 4: quotiteDisponible")
        ownership.isDismembered = false
        ownership.fullOwners = [Owner(name: "Défunt", fraction : 70),
                                Owner(name: "Conjoint", fraction : 30)]
        print("AVANT : " + ownership.description)
        
        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : ["Enfant 1", "Enfant 2"],
            spouseName         : "Conjoint",
            spouseFiscalOption : .quotiteDisponible)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [])
        XCTAssertEqual(ownership.bareOwners, [])
        XCTAssertTrue(ownership.fullOwners == [Owner(name: "Conjoint", fraction : 30.0 + 70.0 / 3.0),
                                               Owner(name: "Enfant 1", fraction : 70.0 / 3.0),
                                               Owner(name: "Enfant 2", fraction : 70.0 / 3.0)])
        print("APRES : " + ownership.description)
        
        print("Cas B.2: ")
        // (2) le défunt ne fait pas partie des plein-propriétaires
        // un seul usufruitier + plusieurs enfants + pas de conjoint
        ownership.fullOwners = [Owner(name: "Parent", fraction : 100)]
        let ownershipAvant = ownership
        print("AVANT : " + ownership.description)
        
        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : ["Enfant 1", "Enfant 2"],
            spouseName         : nil,
            spouseFiscalOption : nil)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownershipAvant, ownership)
        print("APRES : " + ownership.description)
    }
}
