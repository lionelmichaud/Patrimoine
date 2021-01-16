//
//  IncomeTaxesTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 09/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class IncomeTaxesModelTests: XCTestCase {
    
    static var incomeTaxes: IncomeTaxesModel!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = IncomeTaxesModel.Model(for: IncomeTaxesModelTests.self,
                                           from                 : "IncomeTaxesModelTest.json",
                                           dateDecodingStrategy : .iso8601,
                                           keyDecodingStrategy  : .useDefaultKeys)
        IncomeTaxesModelTests.incomeTaxes = IncomeTaxesModel(model: model)
        try! IncomeTaxesModelTests.incomeTaxes.initialize()
    }
    
    // MARK: Tests
    
    /// - Note: [reference](https://www.economie.gouv.fr/particuliers/quotient-familial)
    func test_familyQuotient_inside_bounds() {
        var fq: Double
        
        do {
            fq = try IncomeTaxesModelTests.incomeTaxes.familyQuotient(nbAdults: 1, nbChildren: 0)
            XCTAssertEqual(1, fq)
            
            fq = try IncomeTaxesModelTests.incomeTaxes.familyQuotient(nbAdults: 1, nbChildren: 1)
            XCTAssertEqual(1.5, fq)
            
            fq = try IncomeTaxesModelTests.incomeTaxes.familyQuotient(nbAdults: 1, nbChildren: 4)
            XCTAssertEqual(4, fq)
            
            fq = try IncomeTaxesModelTests.incomeTaxes.familyQuotient(nbAdults: 2, nbChildren: 0)
            XCTAssertEqual(2, fq)
            
            fq = try IncomeTaxesModelTests.incomeTaxes.familyQuotient(nbAdults: 2, nbChildren: 1)
            XCTAssertEqual(2.5, fq)
            
            fq = try IncomeTaxesModelTests.incomeTaxes.familyQuotient(nbAdults: 2, nbChildren: 2)
            XCTAssertEqual(3, fq)
            
            fq = try IncomeTaxesModelTests.incomeTaxes.familyQuotient(nbAdults: 2, nbChildren: 4)
            XCTAssertEqual(5, fq)
        } catch {
            fatalError(convertErrorToString(error))
        }
    }
    
    func test_familyQuotient_outside_bounds() {
        XCTAssertThrowsError(try IncomeTaxesModelTests.incomeTaxes.familyQuotient(nbAdults: -1, nbChildren: 4)) { error in
            XCTAssertEqual(error as! IncomeTaxesModel.ModelError, IncomeTaxesModel.ModelError.outOfBounds)
        }
        XCTAssertThrowsError(try IncomeTaxesModelTests.incomeTaxes.familyQuotient(nbAdults: 1, nbChildren: -1)) { error in
            XCTAssertEqual(error as! IncomeTaxesModel.ModelError, IncomeTaxesModel.ModelError.outOfBounds)
        }
    }
    
    func test_taxableIncome_for_salary() {
        // revenu négatif
        var personalIncome: WorkIncomeType = .salary(brutSalary: 0,
                                                     taxableSalary: -400,
                                                     netSalary: 0,
                                                     fromDate: Date.now,
                                                     healthInsurance: 0)
        XCTAssertEqual(0, IncomeTaxesModelTests.incomeTaxes.taxableIncome(from: personalIncome))
        
        // revenu entièrement compensé par l'abattement
        personalIncome = .salary(brutSalary: 0,
                                 taxableSalary: 400,
                                 netSalary: 0,
                                 fromDate: Date.now,
                                 healthInsurance: 0)
        XCTAssertEqual(0, IncomeTaxesModelTests.incomeTaxes.taxableIncome(from: personalIncome))
        
        // revenu permettant un abattement non plafonné
        personalIncome = .salary(brutSalary: 0,
                                 taxableSalary: 10_000,
                                 netSalary: 0,
                                 fromDate: Date.now,
                                 healthInsurance: 0)
        XCTAssertEqual(9_000, IncomeTaxesModelTests.incomeTaxes.taxableIncome(from: personalIncome))
        
        // revenu permettant un abattement plafonné
        personalIncome = .salary(brutSalary: 0,
                                 taxableSalary: 150_000,
                                 netSalary: 0,
                                 fromDate: Date.now,
                                 healthInsurance: 0)
        XCTAssertEqual(150_000.0 - 12627.0, IncomeTaxesModelTests.incomeTaxes.taxableIncome(from: personalIncome))
    }
    
    func test_taxableIncome_for_BNC() {
        // revenu négatif
        var bnc: WorkIncomeType = .turnOver(BNC: -1_000, incomeLossInsurance: 0)
        XCTAssertEqual(0, IncomeTaxesModelTests.incomeTaxes.taxableIncome(from: bnc))
        
        // revenu permettant un abattement minimum
        bnc = .turnOver(BNC: 280, incomeLossInsurance: 0)
        XCTAssertEqual(0, IncomeTaxesModelTests.incomeTaxes.taxableIncome(from: bnc))
        
        // revenu permettant un abattement %
        bnc = .turnOver(BNC: 40_000, incomeLossInsurance: 0)
        XCTAssertEqual(40_000.0 - 40_000.0 * 0.34, IncomeTaxesModelTests.incomeTaxes.taxableIncome(from: bnc))
    }
    
    func test_irpp() throws {
        // impot sans enfant / tranche non imposable
        var irpp = try IncomeTaxesModelTests.incomeTaxes.irpp(taxableIncome: 20_000,
                                                         nbAdults: 2,
                                                         nbChildren: 0)
        XCTAssertEqual(0.0, irpp.amount)
        XCTAssertEqual(0.0, irpp.averageRate)
        
        // impot sans enfant / 2nd tranche
        irpp = try IncomeTaxesModelTests.incomeTaxes.irpp(taxableIncome: 15_000,
                                                     nbAdults: 1,
                                                     nbChildren: 0)
        XCTAssertEqual((15_000.0 - 10_064.0) * 0.11, irpp.amount)
        XCTAssertEqual(0.11, irpp.marginalRate)
        
        // impot sans enfant / 3ième tranche
        irpp = try IncomeTaxesModelTests.incomeTaxes.irpp(taxableIncome: 32_000,
                                                     nbAdults: 1,
                                                     nbChildren: 0)
        XCTAssertEqual((25_659.0 - 10_064.0) * 0.11 + (32_000.0 - 25_659.0) * 0.3, irpp.amount)
        XCTAssertEqual(0.3, irpp.marginalRate)
        
        // impot sans enfant / 4ième tranche
        irpp = try IncomeTaxesModelTests.incomeTaxes.irpp(taxableIncome: 100_000,
                                                     nbAdults: 1,
                                                     nbChildren: 0)
        XCTAssertEqual((25_659.0 - 10_064.0) * 0.11 + (73_369.0 - 25_659.0) * 0.3 + (100_000.0 - 73_369.0) * 0.41, irpp.amount)
        XCTAssertEqual(0.41, irpp.marginalRate)
        
        // impot sans enfant / 5ième tranche
        irpp = try IncomeTaxesModelTests.incomeTaxes.irpp(taxableIncome: 200_000,
                                                     nbAdults: 1,
                                                     nbChildren: 0)
        XCTAssertEqual((25_659.0 - 10_064.0) * 0.11 + (73_369.0 - 25_659.0) * 0.3 + (157_806.0 - 73_369.0) * 0.41 + ( 200_000.0 - 157_806.0) * 0.45,
                       irpp.amount)
        XCTAssertEqual(0.45, irpp.marginalRate)
        
        // impot avec enfants : sans dépasser le plafond du quotient familiale: https://www.economie.gouv.fr/particuliers/tranches-imposition-impot-revenu
        irpp = try IncomeTaxesModelTests.incomeTaxes.irpp(taxableIncome: 55_950,
                                                     nbAdults: 2,
                                                     nbChildren: 2)
        XCTAssertEqual((55_950.0 / 3.0 - 10_064.0) * 0.11 * 3, irpp.amount)
        XCTAssertEqual(0.11, irpp.marginalRate)
        
        // impot avec enfants : en dépassant le plafond du quotient familiale: https://www.economie.gouv.fr/particuliers/tranches-imposition-impot-revenu
        let irpp_sans = try IncomeTaxesModelTests.incomeTaxes.irpp(taxableIncome: 100_000,
                                                              nbAdults: 2,
                                                              nbChildren: 0)
        XCTAssertEqual(0.3, irpp_sans.marginalRate)
        let irpp_sans_theroric = ((25_659.0 - 10_064.0) * 0.11 + (100_000.0 / 2.0 - 25_659.0) * 0.3) * 2.0
        XCTAssertEqual(irpp_sans_theroric, irpp_sans.amount)
        
        // avec 2 enfants (+2 x 1/2 parts)
        var irpp_avec = try IncomeTaxesModelTests.incomeTaxes.irpp(taxableIncome: 100_000,
                                                              nbAdults: 2,
                                                              nbChildren: 2)
        var irpp_avec_theoric = irpp_sans_theroric - 2.0 * 1567.0
        XCTAssertEqual(irpp_avec_theoric, irpp_avec.amount)
        XCTAssertEqual(0.3, irpp_avec.marginalRate)
        
        // avec 3 enfants  (+4 x 1/2 parts)
        irpp_avec = try IncomeTaxesModelTests.incomeTaxes.irpp(taxableIncome: 100_000,
                                                              nbAdults: 2,
                                                              nbChildren: 3)
        irpp_avec_theoric = irpp_sans_theroric - 4.0 * 1567.0
        XCTAssertEqual(irpp_avec_theoric, irpp_avec.amount)
        XCTAssertEqual(0.11, irpp_avec.marginalRate)
    }
    
    func test_irpp_for_negative_taxable_Income() throws {
        // impot sans enfant / tranche non imposable
        let irpp = try IncomeTaxesModelTests.incomeTaxes.irpp(taxableIncome: -20_000,
                                                              nbAdults: 2,
                                                              nbChildren: 0)
        XCTAssertEqual(0.0, irpp.amount)
        XCTAssertEqual(0.0, irpp.averageRate)
        XCTAssertEqual(0.0, irpp.marginalRate)
    }
}
