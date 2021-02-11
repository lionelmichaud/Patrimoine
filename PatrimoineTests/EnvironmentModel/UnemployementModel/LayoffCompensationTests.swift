//
//  LayoffCompensationTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 27/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class LayoffCompensationTests: XCTestCase {

    static var layoffCompensation: LayoffCompensation!

    // MARK: Helpers

    override class func setUp() {
        super.setUp()
        let model = LayoffCompensation.Model(
            for                  : LayoffCompensationTests.self,
            from                 : nil,
            dateDecodingStrategy : .iso8601,
            keyDecodingStrategy  : .useDefaultKeys)
        LayoffCompensationTests.layoffCompensation = LayoffCompensation(model: model)
        LayoffCompensation.setFiscalModel(
            Fiscal.Model(for: FiscalModelTests.self,
                         from                 : "FiscalModelConfig.json",
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

    func test_calcul_nb_de_mois_salaire_indemnite_legale() {
        var Anciennete : Int // en années
        var nbMois     : Double

        Anciennete = 7 // ans
        nbMois = LayoffCompensationTests.layoffCompensation.layoffCompensationLegalInMonth(
            nbYearsSeniority: Anciennete)
        XCTAssertEqual(Double(Anciennete) * 1.0/4.0, nbMois)

        Anciennete = 10 // ans
        nbMois = LayoffCompensationTests.layoffCompensation.layoffCompensationLegalInMonth(
            nbYearsSeniority: Anciennete)
        XCTAssertEqual(Double(Anciennete) * 1.0/4.0, nbMois)

        Anciennete = 19 // ans
        nbMois = LayoffCompensationTests.layoffCompensation.layoffCompensationLegalInMonth(
            nbYearsSeniority: Anciennete)
        let theory = 10.0 / 4.0 + Double(Anciennete - 10) * 1.0/3.0
        XCTAssert(theory.isApproximatelyEqual(to: nbMois, relativeTolerance: 0.001))
        //print("layoffCompensationLegalInMonth = \(theory)")

        Anciennete = 30 // ans
        nbMois = LayoffCompensationTests.layoffCompensation.layoffCompensationLegalInMonth(
            nbYearsSeniority: Anciennete)
        XCTAssert((10.0 / 4.0 + Double(Anciennete - 10) * 1.0/3.0).isApproximatelyEqual(to: nbMois,
                                                                                        relativeTolerance: 0.001))
    }

    func test_calcul_indemnite_legale() {
        let yearlyWorkIncomeBrut = 98_400.0
        let nbYearsSeniority     = 19

        let indemnite = LayoffCompensationTests.layoffCompensation.layoffCompensationLegal(
            yearlyWorkIncomeBrut : yearlyWorkIncomeBrut,
            nbYearsSeniority     : nbYearsSeniority)
        let nbMonth = 5.5
        let theory  = nbMonth * yearlyWorkIncomeBrut / 12.0
        XCTAssert(theory.isApproximatelyEqual(to: indemnite))
        print("***** Indemnité légale de licenciement pour un dernier salaire de \(yearlyWorkIncomeBrut)€ et une ancienneté de \(nbYearsSeniority) ans = \(theory)")
    }

    func test_calcul_nb_de_mois_salaire_indemnite_metalurgie() throws {
        var Anciennete : Int // en années
        var age        : Int // en années
        var nbMois     : Double
        var theory     : Double

        age        = 40 // ans
        Anciennete = 7 // ans
        nbMois = try XCTUnwrap(LayoffCompensationTests.layoffCompensation.layoffCompensationConventionInMonth(
            age              : age,
            nbYearsSeniority : Anciennete))
        theory = max(Double(Anciennete) * 1.0/5.0, Double(Anciennete) * 1.0/4.0)
        XCTAssertEqual(theory, nbMois)

        age        = 40 // ans
        Anciennete = 19 // ans
        nbMois = try XCTUnwrap(LayoffCompensationTests.layoffCompensation.layoffCompensationConventionInMonth(
            age              : age,
            nbYearsSeniority : Anciennete))
        theory = 7 * 1.0/5.0 + Double(Anciennete - 7) * 3.0/5.0
        XCTAssertEqual(theory, nbMois)

        age        = 54 // ans
        Anciennete = 4 // ans -> pas de majoration
        nbMois = try XCTUnwrap(LayoffCompensationTests.layoffCompensation.layoffCompensationConventionInMonth(
            age              : age,
            nbYearsSeniority : Anciennete))
        theory = max(Double(Anciennete) * 1.0/5.0, Double(Anciennete) * 1.0/4.0)
        XCTAssertEqual(theory, nbMois)

        age        = 54 // ans
        Anciennete = 8 // ans -> majoration avec minimum de 3 mois
        nbMois = try XCTUnwrap(LayoffCompensationTests.layoffCompensation.layoffCompensationConventionInMonth(
            age              : age,
            nbYearsSeniority : Anciennete))
        theory = 3.0
        XCTAssertEqual(theory, nbMois)

        age        = 50 // ans
        Anciennete = 19 // ans -> majoration de 20%
        nbMois = try XCTUnwrap(LayoffCompensationTests.layoffCompensation.layoffCompensationConventionInMonth(
            age              : age,
            nbYearsSeniority : Anciennete))
        theory = 1.2 * (7 * 1.0/5.0 + Double(Anciennete - 7) * 3.0/5.0)
        XCTAssertEqual(theory, nbMois)

        age        = 57 // ans
        Anciennete = 19 // ans -> majoration de 30%
        nbMois = try XCTUnwrap(LayoffCompensationTests.layoffCompensation.layoffCompensationConventionInMonth(
            age              : age,
            nbYearsSeniority : Anciennete))
        theory = 1.3 * (7 * 1.0/5.0 + Double(Anciennete - 7) * 3.0/5.0)
        XCTAssertEqual(theory, nbMois)
        print("***** layoffCompensationConventionInMonth = \(theory)")

        age        = 57 // ans
        Anciennete = 8 // ans -> majoration avec minimum de 6 mois
        nbMois = try XCTUnwrap(LayoffCompensationTests.layoffCompensation.layoffCompensationConventionInMonth(
            age              : age,
            nbYearsSeniority : Anciennete))
        theory = 6.0
        XCTAssertEqual(theory, nbMois)
    }

    func test_calcul_indemnite_de_licenciement_metalurgie() {
        let causeOfRetirement    : Unemployment.Cause = .planSauvegardeEmploi
        let yearlyWorkIncomeBrut : Double = 98_400.0
        let age                  : Int = 57
        let nbYearsSeniority     : Int = 19

        let indemnite = LayoffCompensationTests.layoffCompensation.layoffCompensation(
            actualCompensationBrut : nil,
            causeOfRetirement      : causeOfRetirement     ,
            yearlyWorkIncomeBrut   : yearlyWorkIncomeBrut  ,
            age                    : age                   ,
            nbYearsSeniority       : nbYearsSeniority)
        XCTAssertEqual(11.18, indemnite.nbMonth)
        let theory = 11.18 * yearlyWorkIncomeBrut / 12.0
        XCTAssertEqual(theory, indemnite.brut)
        print("***** Indemnité de licenciement pour un dernier salaire de \(yearlyWorkIncomeBrut)€ et une ancienneté de \(nbYearsSeniority) ans = \(theory)")
    }
}
