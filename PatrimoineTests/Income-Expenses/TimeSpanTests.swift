//
//  TimeSpanTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 20/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class TimeSpanTests: XCTestCase {
    
    static var db2020 = DateBoundary(fixedYear: 2020)
    static var db2024 = DateBoundary(fixedYear: 2024)

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_CuctomString() throws {
        var ts = TimeSpan.permanent
        print(ts)

        ts = TimeSpan.periodic(from   : TimeSpanTests.db2020,
                               period : 2,
                               to     : TimeSpanTests.db2024)
        print(ts)

        ts = TimeSpan.starting(from: TimeSpanTests.db2020)
        print(ts)

        ts = TimeSpan.ending(to: TimeSpanTests.db2020)
        print(ts)
        
        ts = TimeSpan.spanning(from   : TimeSpanTests.db2020,
                               to     : TimeSpanTests.db2024)
        print(ts)
        ts = TimeSpan.exceptional(inYear: 2022)
        print(ts)
    }
    
    func test_starting() {
        let ts = TimeSpan.starting(from: DateBoundary(fixedYear: 2020))
        XCTAssertTrue(ts.isValid)
        XCTAssertEqual(2020, ts.firstYear)
        XCTAssertEqual(Date.now.year + 100, ts.lastYear)
    }

    func test_ending() {
        let datePassee = Date.now.year - 1
        var ts = TimeSpan.ending(to: DateBoundary(fixedYear: datePassee))
        XCTAssertTrue(ts.isValid)
        XCTAssertEqual(datePassee - 1, ts.firstYear)
        XCTAssertEqual(datePassee - 1, ts.lastYear)
        
        let dateFutur = Date.now.year + 2
        ts = TimeSpan.ending(to: DateBoundary(fixedYear: dateFutur))
        XCTAssertTrue(ts.isValid)
        XCTAssertEqual(Date.now.year, ts.firstYear)
        XCTAssertEqual(dateFutur - 1, ts.lastYear)
    }
    
    func test_spanning() {
        let datePassee = Date.now.year - 1
        let dateFutur  = Date.now.year + 2
        var ts = TimeSpan.spanning(from : DateBoundary(fixedYear: datePassee),
                                   to   : DateBoundary(fixedYear: dateFutur))
        XCTAssertTrue(ts.isValid)
        XCTAssertTrue(ts.contains(datePassee))
        XCTAssertTrue(ts.contains(dateFutur-1))
        XCTAssertFalse(ts.contains(dateFutur))
        XCTAssertEqual(datePassee, ts.firstYear)
        XCTAssertEqual(dateFutur - 1, ts.lastYear)

        ts = TimeSpan.spanning(from : DateBoundary(fixedYear: datePassee),
                               to   : DateBoundary(fixedYear: datePassee))
        XCTAssertFalse(ts.isValid)
        XCTAssertNil(ts.firstYear)
        XCTAssertNil(ts.lastYear)
    }

    func test_exceptional() {
        let ts = TimeSpan.exceptional(inYear: 2020)
        XCTAssertTrue(ts.isValid)
        XCTAssertEqual(2020, ts.firstYear)
        XCTAssertEqual(2020, ts.lastYear)
    }
}
