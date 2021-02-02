//
//  OwnersTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 01/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

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

}
