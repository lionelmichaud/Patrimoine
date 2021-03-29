//
//  OwnableTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 08/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class OwnableTests: XCTestCase {
    
    // MARK: - Helpers
    
    struct Asset: Ownable {
        var ownership: Ownership = Ownership()
        
        var name: String
        
        func value(atEndOf year: Int) -> Double {
            Double(year)
        }
        
        func print() {
            Swift.print("Printed")
        }
    }
    
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
    
    // MARK: - Tests
    
    func test_owned_value() throws {
        var ownership = Ownership(ageOf: OwnershipTests.ageOf)
        ownership.isDismembered = true
        
        // un seul usufruitier + un seul nupropriétaire
        ownership.usufructOwners = [Owner(name: "Usufruitier",    fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Nupropriétaire", fraction : 100)]
        
        let asset = Asset(ownership: ownership,
                          name: "Actif")
        
        // cas .legalSuccession d'un Nu-propriétaire
        var value = ownership.ownedValue(by               : "Nupropriétaire",
                                         ofValue          : asset.value(atEndOf          : 2020),
                                         atEndOf          : 2020,
                                         evaluationMethod : EvaluationMethod.legalSuccession)
        var ownedValue = asset.ownedValue(by               : "Nupropriétaire",
                                          atEndOf          : 2020,
                                          evaluationMethod : EvaluationMethod.legalSuccession)
        
        XCTAssertEqual(value, ownedValue)
        
        // cas .legalSuccession d'un Usufruitier
        ownedValue = asset.ownedValue(by               : "Usufruitier",
                                      atEndOf          : 2020,
                                      evaluationMethod : EvaluationMethod.legalSuccession)
        
        XCTAssertEqual(0, ownedValue)
        
        // cas .lifeInsuranceSuccession d'un Usufruitier
        ownedValue = asset.ownedValue(by               : "Usufruitier",
                                      atEndOf          : 2020,
                                      evaluationMethod : EvaluationMethod.lifeInsuranceSuccession)
        
        XCTAssertEqual(0, ownedValue)
        
        // cas .patrimoine, .ifi, .isf d'un Usufruitier
        value = ownership.ownedValue(by               : "Usufruitier",
                                     ofValue          : asset.value(atEndOf          : 2020),
                                     atEndOf          : 2020,
                                     evaluationMethod : EvaluationMethod.patrimoine)
        ownedValue = asset.ownedValue(by               : "Usufruitier",
                                      atEndOf          : 2020,
                                      evaluationMethod : EvaluationMethod.patrimoine)
        
        XCTAssertEqual(value, ownedValue)
        
        value = ownership.ownedValue(by               : "Usufruitier",
                                     ofValue          : asset.value(atEndOf          : 2020),
                                     atEndOf          : 2020,
                                     evaluationMethod : EvaluationMethod.ifi)
        ownedValue = asset.ownedValue(by               : "Usufruitier",
                                      atEndOf          : 2020,
                                      evaluationMethod : EvaluationMethod.ifi)
        
        XCTAssertEqual(value, ownedValue)
        
        value = ownership.ownedValue(by               : "Usufruitier",
                                     ofValue          : asset.value(atEndOf          : 2020),
                                     atEndOf          : 2020,
                                     evaluationMethod : EvaluationMethod.isf)
        ownedValue = asset.ownedValue(by               : "Usufruitier",
                                      atEndOf          : 2020,
                                      evaluationMethod : EvaluationMethod.isf)
        
        XCTAssertEqual(value, ownedValue)
    }
    
    func test_owned_values() throws {
        var ownership = Ownership(ageOf: OwnershipTests.ageOf)
        ownership.isDismembered = true
        
        // un seul usufruitier + un seul nupropriétaire
        ownership.usufructOwners = [Owner(name: "Usufruitier",    fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Nupropriétaire", fraction : 100)]
        
        let asset = Asset(ownership: ownership,
                          name: "Actif")
        
        let ownedValues = asset.ownedValues(atEndOf          : 2020,
                                            evaluationMethod : EvaluationMethod.legalSuccession)
        print(ownedValues)

        XCTAssertNotNil(ownedValues["Usufruitier"])
        XCTAssertNotNil(ownedValues["Nupropriétaire"])
    }
}
