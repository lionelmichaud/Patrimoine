//
//  EconomyModelTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class EconomyModelTests: XCTestCase {
    
    func test_loading_from_main_bundle() throws {
        XCTAssertNoThrow(Economy.Model(), "Failed to read model from Main Bundle ")
    }
    
    func test_saving_to_test_bundle() throws {
        let model = Economy.RandomizersModel()
        model.saveToBundle(for: EconomyModelTests.self,
                           to: nil,
                           dateEncodingStrategy: .iso8601,
                           keyEncodingStrategy: .useDefaultKeys)
    }
    func test_generation_aleatoire_outOfBounds() {
        let model = Economy.Model()
        
        XCTAssertThrowsError(try model.nextRun(withMode: .random,
                                               firstYear: 2030,
                                               lastYear: 2029)) { error in
            XCTAssertEqual(error as! Economy.ModelError, Economy.ModelError.outOfBounds)
        }
        XCTAssertThrowsError(try model.nextRun(withMode: .deterministic,
                                               firstYear: 2030,
                                               lastYear: 2029)) { error in
            XCTAssertEqual(error as! Economy.ModelError, Economy.ModelError.outOfBounds)
        }
        
        var dico = Economy.DictionaryOfRandomVariable()
        dico[.inflation] = 0.0
        dico[.securedRate] = 0.0
        dico[.stockRate]  = 0.0
        XCTAssertThrowsError(try model.setRandomValue(to: dico,
                                                      withMode: .random,
                                                      firstYear: 2030,
                                                      lastYear: 2029)) { error in
            XCTAssertEqual(error as! Economy.ModelError, Economy.ModelError.outOfBounds)
        }
        XCTAssertThrowsError(try model.setRandomValue(to: dico,
                                                      withMode: .deterministic,
                                                      firstYear: 2030,
                                                      lastYear: 2029)) { error in
            XCTAssertEqual(error as! Economy.ModelError, Economy.ModelError.outOfBounds)
        }
    }
    
    func test_generation_aleatoire() throws {
        let model = Economy.Model()
        let firstYear = 2020
        let lastYear = 2030
        
        XCTAssertNoThrow(try model.nextRun(withMode: .random, firstYear: firstYear, lastYear: lastYear))
        XCTAssertNoThrow(try model.nextRun(withMode: .deterministic, firstYear: firstYear, lastYear: lastYear))
        
        // deterministe
        var dico = try model.nextRun(withMode: .deterministic, firstYear: firstYear, lastYear: lastYear)
        XCTAssertNotNil(dico[.inflation])
        XCTAssertNotNil(dico[.securedRate])
        XCTAssertNotNil(dico[.stockRate])
        
        XCTAssertEqual(model.firstYearSampled, firstYear)
        XCTAssertEqual(model.securedRateSamples.count, 0)
        XCTAssertEqual(model.stockRateSamples.count, 0)
        
        // random
        UserSettings.shared.simulateVolatility = true
        dico = try model.nextRun(withMode: .random, firstYear: firstYear, lastYear: lastYear)
        XCTAssertNotNil(dico[.inflation])
        XCTAssertNotNil(dico[.securedRate])
        XCTAssertNotNil(dico[.stockRate])
        
        XCTAssertEqual(model.firstYearSampled, firstYear)
        XCTAssertEqual(model.securedRateSamples.count, lastYear - firstYear + 1)
        XCTAssertEqual(model.stockRateSamples.count, lastYear - firstYear + 1)
        
        UserSettings.shared.simulateVolatility = false
        dico = try model.nextRun(withMode: .random, firstYear: firstYear, lastYear: lastYear)
        XCTAssertNotNil(dico[.inflation])
        XCTAssertNotNil(dico[.securedRate])
        XCTAssertNotNil(dico[.stockRate])
        
        XCTAssertEqual(model.firstYearSampled, firstYear)
        XCTAssertEqual(model.securedRateSamples.count, 0)
        XCTAssertEqual(model.stockRateSamples.count, 0)
    }
    
    func test_reinit_rejeu() throws {
        let model = Economy.Model()
        let firstYear = 2020
        let lastYear = 2030
        var dico = Economy.DictionaryOfRandomVariable()
        dico[.inflation] = 0.0
        dico[.securedRate] = 0.0
        dico[.stockRate]  = 0.0

        // deterministe
        UserSettings.shared.simulateVolatility = true
        try model.setRandomValue(to: dico, withMode: .deterministic, firstYear: firstYear, lastYear: lastYear)
        XCTAssertEqual(model.firstYearSampled, firstYear)
        XCTAssertEqual(model.securedRateSamples.count, 0)
        XCTAssertEqual(model.stockRateSamples.count, 0)
        
        // random
        UserSettings.shared.simulateVolatility = true
        try model.setRandomValue(to: dico, withMode: .random, firstYear: firstYear, lastYear: lastYear)
        XCTAssertEqual(model.firstYearSampled, firstYear)
        XCTAssertEqual(model.securedRateSamples.count, lastYear - firstYear + 1)
        XCTAssertEqual(model.stockRateSamples.count, lastYear - firstYear + 1)
        
        UserSettings.shared.simulateVolatility = false
        try model.setRandomValue(to: dico, withMode: .random, firstYear: firstYear, lastYear: lastYear)
        XCTAssertEqual(model.firstYearSampled, firstYear)
        XCTAssertEqual(model.securedRateSamples.count, 0)
        XCTAssertEqual(model.stockRateSamples.count, 0)
   }
}
