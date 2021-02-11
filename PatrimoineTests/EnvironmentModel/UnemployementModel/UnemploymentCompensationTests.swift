//
//  UnemploymentCompensationTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 29/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class UnemploymentCompensationTests: XCTestCase {
    
    static var unemploymentCompensation: UnemploymentCompensation!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = UnemploymentCompensation.Model(
            for                  : UnemploymentCompensationTests.self,
            from                 : nil,
            dateDecodingStrategy : .iso8601,
            keyDecodingStrategy  : .useDefaultKeys)
        UnemploymentCompensationTests.unemploymentCompensation = UnemploymentCompensation(model: model)
        UnemploymentCompensation.setFiscalModel(
            Fiscal.Model(for: FiscalModelTests.self,
                         from                 : nil,
                         dateDecodingStrategy : .iso8601,
                         keyDecodingStrategy  : .useDefaultKeys)
                .initialized())
    }
    
    func date(year: Int, month: Int, day: Int) -> Date {
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : year,
                                         month    : month,
                                         day      : day)
        return Date.calendar.date(from: dateRefComp)!
    }
    
    // MARK: Tests
    
    func test_recherche_duree_indemnisation() throws {
        var age  : Int
        var duree: Int
        
        age = 50
        duree = try XCTUnwrap(UnemploymentCompensationTests.unemploymentCompensation.durationInMonth(age: age))
        XCTAssertEqual(24, duree)
        
        age = 53
        duree = try XCTUnwrap(UnemploymentCompensationTests.unemploymentCompensation.durationInMonth(age: age))
        XCTAssertEqual(30, duree)
        
        age = 55
        duree = try XCTUnwrap(UnemploymentCompensationTests.unemploymentCompensation.durationInMonth(age: age))
        XCTAssertEqual(36, duree)
        
        age = 57
        duree = try XCTUnwrap(UnemploymentCompensationTests.unemploymentCompensation.durationInMonth(age: age))
        XCTAssertEqual(36, duree)
        print("***** Durée d'indemnisation pour un age de \(age) ans = \(duree)")
    }
    
    func test_calcul_differe_specifique() {
        var compensationSupralegal : Double
        var causeOfUnemployement   : Unemployment.Cause
        var theory                 : Double
        var differe                : Int
        
        compensationSupralegal =  91676.0 - 45100.0
        
        causeOfUnemployement   = .planSauvegardeEmploi
        
        theory = min(75, (compensationSupralegal / 95.8).rounded(.down))
        differe = UnemploymentCompensationTests.unemploymentCompensation.differeSpecifique(
            compensationSupralegal : compensationSupralegal,
            causeOfUnemployement   : causeOfUnemployement)
        XCTAssertEqual(Int(theory), differe)
        print("***** Durée de différé spécifique pour une indemnité supra-légale de \(compensationSupralegal)€ en cas de \(causeOfUnemployement.displayString) = \(differe) jpurs")
        
        causeOfUnemployement   = .licenciement
        
        theory = min(150, (compensationSupralegal / 95.8).rounded(.down))
        differe = UnemploymentCompensationTests.unemploymentCompensation.differeSpecifique(
            compensationSupralegal : compensationSupralegal,
            causeOfUnemployement   : causeOfUnemployement)
        XCTAssertEqual(Int(theory), differe)
        
        compensationSupralegal =  9600.0
        
        theory = min(150, (compensationSupralegal / 95.8).rounded(.down))
        differe = UnemploymentCompensationTests.unemploymentCompensation.differeSpecifique(
            compensationSupralegal : compensationSupralegal,
            causeOfUnemployement   : causeOfUnemployement)
        XCTAssertEqual(Int(theory), differe)
    }
    
    func test_calcul_durée_période_avant_réduction_allocation_journalière() throws {
        let yearlyWorkIncomeNet : Double = 77_000.0
        var age                 : Int
        var SJR                 : Double
        var reduc               : Int
        var theory              : Int
        
        age = 55
        SJR = yearlyWorkIncomeNet / 365.0
        
        reduc = try XCTUnwrap(UnemploymentCompensationTests.unemploymentCompensation.reductionAfter(
                                age: age,
                                SJR: SJR))
        theory = 6
        XCTAssertEqual(theory, reduc)

        age = 57
        SJR = yearlyWorkIncomeNet / 365.0
        
        XCTAssertNil(UnemploymentCompensationTests.unemploymentCompensation.reductionAfter(
                                age: age,
                                SJR: SJR))
    }
    
    func test_calcul_duree_et_coef_de_reduction_allocation() {
        var age                 : Int
        let daylyAlloc          : Double = 122.0
        var coefTheory          : Double
        var dureeTheory         : Int
        
        age = 55
        
        var reduc = UnemploymentCompensationTests.unemploymentCompensation.reduction(
            age        : age,
            daylyAlloc : daylyAlloc)
        coefTheory  = 30.0
        dureeTheory = 6
        XCTAssertEqual(dureeTheory, reduc.afterMonth)
        XCTAssertEqual(coefTheory, reduc.percentReduc)

        age = 57
        reduc = UnemploymentCompensationTests.unemploymentCompensation.reduction(
            age        : age,
            daylyAlloc : daylyAlloc)
        coefTheory  = 0.0
        dureeTheory = 6
        XCTAssertNil(reduc.afterMonth)
        XCTAssertEqual(coefTheory, reduc.percentReduc)
    }
    
    func test_calcul_allocation_avant_reduction() {
        let yearlyWorkIncomeNet : Double = 77_000.0
        var SJR                 : Double
        var areTheory           : Double

        // https://www.unedic.org/indemnisation/vos-questions-sur-indemnisation-assurance-chomage/comment-est-calculee-mon-allocation-chomage
        SJR = 50.0
        var ARE = UnemploymentCompensationTests.unemploymentCompensation.daylyAllocBeforeReduction(
            SJR: SJR)
        areTheory = 32.25
        XCTAssertEqual(areTheory, ARE.brut)

        // cas Lionel
        SJR = yearlyWorkIncomeNet / 365.0
        ARE = UnemploymentCompensationTests.unemploymentCompensation.daylyAllocBeforeReduction(
            SJR: SJR)
        areTheory = max(12.05 + SJR * 0.404, SJR * 0.57)
        XCTAssertEqual(areTheory, ARE.brut)
        print("***** ARE pour un dernier salre anneul de \(yearlyWorkIncomeNet)€ et donc un SJR de \(SJR)€ = \(ARE)€")
    }
}
