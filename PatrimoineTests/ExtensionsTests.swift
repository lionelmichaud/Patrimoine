//
//  ExtensionsTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 18/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class ExtensionsStringTests: XCTestCase {

    func test_splittedLines() throws {
        let string = """
        Ceci est un test
        d'une nouvelle fonction
        très utile.
        """

        let splittedLines = string.splittedLines
        print(splittedLines)

        XCTAssertEqual(3, splittedLines.count)
        XCTAssertEqual("Ceci est un test", splittedLines.first)
        XCTAssertEqual("très utile.", splittedLines.last)
    }

    func test_withPrefixedSplittedLines() {
        let string = """
        Ceci est un test
        d'une nouvelle fonction
        très utile.
        """

        let prefixed: String = string.withPrefixedSplittedLines("123")
        print(prefixed)

        XCTAssertEqual(3, prefixed.splittedLines.count)
        XCTAssertEqual("123Ceci est un test", prefixed.splittedLines.first)
        XCTAssertEqual("123très utile.", prefixed.splittedLines.last)
    }

}
