//
//  LifeEventTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 20/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class LifeEventTests: XCTestCase {

    func test_dult_event() throws {
        XCTAssertTrue(LifeEvent.cessationActivite.isAdultEvent)
        XCTAssertFalse(LifeEvent.cessationActivite.isChildEvent)
        
        XCTAssertTrue(LifeEvent.liquidationPension.isAdultEvent)
        XCTAssertFalse(LifeEvent.liquidationPension.isChildEvent)
        
        XCTAssertTrue(LifeEvent.dependence.isAdultEvent)
        XCTAssertFalse(LifeEvent.dependence.isChildEvent)
        
        XCTAssertFalse(LifeEvent.deces.isAdultEvent)
    }
    
    func test_child_event() throws {
        XCTAssertTrue(LifeEvent.debutEtude.isChildEvent)
        XCTAssertTrue(LifeEvent.independance.isChildEvent)
        
        XCTAssertFalse(LifeEvent.debutEtude.isAdultEvent)
        XCTAssertFalse(LifeEvent.independance.isAdultEvent)
        
        XCTAssertFalse(LifeEvent.deces.isChildEvent)
    }
}
