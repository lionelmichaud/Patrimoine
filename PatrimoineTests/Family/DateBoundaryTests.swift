//
//  DateBoundaryTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 20/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class DateBoundaryTests: XCTestCase {
    
    func test_fixed_year() throws {
        let boundary = DateBoundary(fixedYear: 2020)
        XCTAssertEqual(2020, boundary.year)
    }
    
    func test_person_event() throws {
        var boundary = DateBoundary(event: LifeEvent.deces,
                                    name: "M. Lionel MICHAUD")
        XCTAssertEqual(1964+82, boundary.year)
        
        boundary = DateBoundary(event: LifeEvent.deces,
                                name: "M. Truc")
        XCTAssertNil(boundary.year)
    }
    
    func test_group_of_person_event() throws {
        var boundary = DateBoundary(event: LifeEvent.deces,
                                    group: GroupOfPersons.allAdults,
                                    order: SoonestLatest.soonest)
        XCTAssertEqual(1964+82, boundary.year)

        boundary = DateBoundary(event: LifeEvent.deces,
                                    group: GroupOfPersons.allAdults,
                                    order: SoonestLatest.latest)
        XCTAssertEqual(1968+89, boundary.year)
    }
}
