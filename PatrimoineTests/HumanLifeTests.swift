//
//  HumanLifeTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class HumanLifeTests: XCTestCase {
    
    func test_loading_from_main_bundle() {
        XCTAssertNoThrow(HumanLife.Model().initialized(), "Failed to read model from Main Bundle ")
    }
    
    func test_saving_to_test_bundle() throws {
        let model = HumanLife.Model().initialized()
        model.saveToBundle(for: HumanLifeTests.self,
                             to: nil,
                             dateEncodingStrategy: .iso8601,
                             keyEncodingStrategy: .useDefaultKeys)
    }

}
