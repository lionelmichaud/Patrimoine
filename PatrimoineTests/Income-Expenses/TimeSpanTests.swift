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
}
