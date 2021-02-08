//
//  OwnersTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 01/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

// test de: struct Owner
class OwnerTests: XCTestCase {
    func test_owner_validity() throws {
        let unnamedOwner = Owner()
        // name = ""
        XCTAssertFalse(unnamedOwner.isValid)
        
        let namedOwner = Owner(name: "Michaud")
        // name != ""
        XCTAssertTrue(namedOwner.isValid)
    }
    
    func test_owned_value() throws {
        let owner = Owner(name: "Michaud",
                          fraction: 75.0)
        let assetValue = 1000.0
        
        let ownedValue = owner.ownedValue(from: assetValue)
        XCTAssertEqual(750.0, ownedValue)
    }
}

// test de: typealias Owners = [Owner]
class OwnersTests: XCTestCase {
    static var owner1 : Owner!
    static var owner2 : Owner!
    static var owner3 : Owner!
    static var owner4 : Owner!
    static var owners = Owners()
    
    override func setUpWithError() throws {
        OwnersTests.owner1 = Owner(name     : "Name 1",
                                   fraction : 10)
        OwnersTests.owner2 = Owner(name     : "Name 2",
                                   fraction : 20)
        OwnersTests.owner3 = Owner(name     : "Name 3",
                                   fraction : 30)
        OwnersTests.owner4 = Owner(name     : "Name 4",
                                   fraction : 40)
        OwnersTests.owners = [OwnersTests.owner1,
                              OwnersTests.owner2,
                              OwnersTests.owner3,
                              OwnersTests.owner4]
    }
    
   func test_sumOfOwnedFractions() {
        XCTAssertEqual(100.0, OwnersTests.owners.sumOfOwnedFractions)
    }
    
    func test_percentageOk() {
        XCTAssertTrue(OwnersTests.owners.percentageOk)
    }
    
    func test_percentageNOk() {
        let owners: Owners = OwnersTests.owners + [OwnersTests.owner1]
        XCTAssertFalse(owners.percentageOk)
    }
    
    func test_owners_validity() throws {
        XCTAssertTrue(OwnersTests.owners.isvalid)
        
        let owners: Owners = OwnersTests.owners + [OwnersTests.owner1]
        XCTAssertFalse(owners.isvalid)
        
        let empty = Owners()
        XCTAssertTrue(empty.isvalid)
    }
    
    func test_recuperer_owner() throws {
        let foundOwner = try? XCTUnwrap(OwnersTests.owners.owner(ownerName: "Name 1"))
        XCTAssertEqual(foundOwner, OwnersTests.owner1)
        let foundOwnerIdx = try? XCTUnwrap(OwnersTests.owners.ownerIdx(ownerName: "Name 1"))
        XCTAssertEqual(foundOwnerIdx, 0)
    }
    
    func test_recuperer_owner_inexistant() throws {
        XCTAssertNil(OwnersTests.owners.owner(ownerName: "Inconnu"))
        XCTAssertNil(OwnersTests.owners.ownerIdx(ownerName: "Inconnu"))
    }

    func test_replace_with_no_Owner() {
        XCTAssertThrowsError(try OwnersTests.owners.replace(thisOwner: "Not an owner", with: ["New Owner Name"])) { error in
            XCTAssertEqual(error as! OwnersError, OwnersError.ownerDoesNotExist)
        }
    }
    
    func test_replace_with_no_New_Owners() {
        XCTAssertThrowsError(try OwnersTests.owners.replace(thisOwner: "Name 1", with: [])) { error in
            XCTAssertEqual(error as! OwnersError, OwnersError.noNewOwners)
        }
    }
    
    func test_replace_with_New_Owners() throws {
        var owners = OwnersTests.owners
        let countBefore = owners.count
        
        try owners.replace(thisOwner: "Name 1", with: ["New Owner 1", "New Owner 2"])
        XCTAssertEqual(countBefore + 1, owners.count)
        XCTAssert(!owners.contains(OwnersTests.owner1))
        XCTAssert(owners.contains(OwnersTests.owner2))
        XCTAssert(owners.contains(OwnersTests.owner3))
        XCTAssert(owners.contains(OwnersTests.owner4))

        let newOwner1 = try XCTUnwrap(owners.owner(ownerName: "New Owner 1"))
        let newOwner2 = try XCTUnwrap(owners.owner(ownerName: "New Owner 2"))
        XCTAssertEqual(5.0, newOwner1.fraction)
        XCTAssertEqual(5.0, newOwner2.fraction)
    }
    
    func test_group_shares() {
        var owners = OwnersTests.owners
        let countBefore = owners.count

        owners.append(Owner(name: "Name 2", fraction: 10))
        owners.groupShares()
        var countAfter = owners.count

        XCTAssertEqual(countBefore, countAfter)
        XCTAssertEqual(20 + 10, owners.owner(ownerName: "Name 2")!.fraction)

        owners.append(Owner(name: "Other name", fraction: 10))
        owners.groupShares()
        countAfter = owners.count
        
        XCTAssertEqual(countBefore + 1, countAfter)
    }
}
