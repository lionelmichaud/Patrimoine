//
//  RegimeAgirc.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 16/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class RegimeAgircTest: XCTestCase { // swiftlint:disable:this type_body_length
    
    static var regimeAgirc  : RegimeAgirc!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = RegimeAgirc.Model(for                  : RegimeAgircTest.self,
                                      from                 : "RetirementRegimeAgircModelConfigTest.json",
                                      dateDecodingStrategy : .iso8601,
                                      keyDecodingStrategy  : .useDefaultKeys)
        RegimeAgircTest.regimeAgirc = RegimeAgirc(model: model)
        
        // inject dependency for tests
        RegimeAgirc.socioEconomyModel =
            SocioEconomy.Model(for: SocioEconomyModelTest.self,
                               from                 : "SocioEconomyModelConfig.json",
                               dateDecodingStrategy : .iso8601,
                               keyDecodingStrategy  : .useDefaultKeys)
            .initialized()
    }
    
    func date(year: Int, month: Int, day: Int) -> Date {
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : year,
                                         month    : month,
                                         day      : day)
        return Date.calendar.date(from: dateRefComp)!
    }
    
    // MARK: Tests
    
    func test_saving_to_test_bundle() throws {
        RegimeAgircTest.regimeAgirc.saveToBundle(for                  : RegimeAgircTest.self,
                                                 to                   : "RetirementRegimeAgircModelConfigTest.json",
                                                 dateEncodingStrategy : .iso8601,
                                                 keyEncodingStrategy  : .useDefaultKeys)
    }
    
    func test_pension_devaluation_rate() {
        XCTAssertEqual(2.0, RegimeAgirc.devaluationRate)
    }
    
    func test_calcul_revaluation_Coef() {
        let dateOfPensionLiquid : Date! = 10.years.ago
        let thisYear = Date.now.year
        
        let coef = RegimeAgirc.revaluationCoef(during: thisYear,
                                               dateOfPensionLiquid: dateOfPensionLiquid)
        XCTAssertEqual(pow((1.0 + -2.0/100.0), 10.0), coef)
    }
    
    func test_date_Age_Minimum_Agirc() {
        var birthDate           : Date
        var date                : Date?
        
        birthDate = self.date(year: 1964, month: 9, day: 22)
        date = RegimeAgircTest.regimeAgirc.dateAgeMinimumAgirc(birthDate: birthDate)
        XCTAssertNotNil(date)
        XCTAssertEqual(1964 + 57, date!.year)
        XCTAssertEqual(9, date!.month)
        XCTAssertEqual(22, date!.day)
    }
    
    func test_recherche_coef_De_Minoration_Avant_Age_Legal() {
        var coef: Double?
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: 2)
        XCTAssertEqual(0.745, coef)
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: 5)
        XCTAssertEqual(0.6925, coef)
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: 10)
        XCTAssertEqual(0.605, coef)
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: 15)
        XCTAssertEqual(0.5175, coef)
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: 20)
        XCTAssertEqual(0.43, coef)
    }
    
    func test_recherche_coef_De_Minoration_Apres_Age_Legal() {
        var coef: Double?
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationApresAgeLegal(
            nbTrimManquantPourTauxPlein : 0,
            nbTrimPostAgeLegalMin       : 18)
        XCTAssertEqual(1.0, coef)
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationApresAgeLegal(
            nbTrimManquantPourTauxPlein : 5,
            nbTrimPostAgeLegalMin       : 15)
        XCTAssertEqual(0.95, coef)
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationApresAgeLegal(
            nbTrimManquantPourTauxPlein : 10,
            nbTrimPostAgeLegalMin       : 14)
        XCTAssertEqual(0.94, coef)
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationApresAgeLegal(
            nbTrimManquantPourTauxPlein : 19,
            nbTrimPostAgeLegalMin       : 8)
        XCTAssertEqual(0.88, coef)
    }
    
    func test_projected_Number_Of_Points_sans_chomage() throws {
        var lastAgircKnownSituation  : RegimeAgircSituation
        var dateOfRetirement         : Date
        var nbPointsFuturs : Int
        var nbPointTheory  : Int
        
        // pas de période de chômage
        lastAgircKnownSituation = RegimeAgircSituation(atEndOf     : 2018,
                                                       nbPoints    : 135,
                                                       pointsParAn : 788)
        dateOfRetirement = date(year: 2022, month: 1, day: 1)
        nbPointsFuturs = try XCTUnwrap(RegimeAgircTest.regimeAgirc.projectedNumberOfPoints(
                                        lastAgircKnownSituation  : lastAgircKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil))
        nbPointTheory = lastAgircKnownSituation.nbPoints +
            (2021 - 2018) * lastAgircKnownSituation.pointsParAn
        XCTAssertEqual(nbPointTheory, nbPointsFuturs)

        // date de cessation d'activité antérieure à la date du dernier relevé de points
        dateOfRetirement = date(year: 2018, month: 1, day: 1)
        nbPointsFuturs = try XCTUnwrap(RegimeAgircTest.regimeAgirc.projectedNumberOfPoints(
                                        lastAgircKnownSituation  : lastAgircKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil))
        nbPointTheory = lastAgircKnownSituation.nbPoints
        XCTAssertEqual(nbPointTheory, nbPointsFuturs)
    }
    
    func test_calcul_projected_Number_Of_Points_avec_chomage() throws {
        var lastAgircKnownSituation  : RegimeAgircSituation
        var dateOfRetirement         : Date
        var dateOfEndOfUnemployAlloc : Date!
        var nbPointsFuturs : Int
        var nbPointTheory  : Int
        
        // avec période de chômage
        lastAgircKnownSituation = RegimeAgircSituation(atEndOf     : 2018,
                                                       nbPoints    : 17907,
                                                       pointsParAn : 788)
        dateOfRetirement         = date(year : 2022, month : 1, day : 1)
        dateOfEndOfUnemployAlloc = 3.years.from(dateOfRetirement)!
        nbPointsFuturs = try XCTUnwrap(RegimeAgircTest.regimeAgirc.projectedNumberOfPoints(
                                        lastAgircKnownSituation  : lastAgircKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc))
        nbPointTheory = lastAgircKnownSituation.nbPoints +
            (2021 - 2018) * lastAgircKnownSituation.pointsParAn +
            (3) * lastAgircKnownSituation.pointsParAn
        XCTAssertEqual(nbPointTheory, nbPointsFuturs)
        
        dateOfRetirement         = date(year : 2018, month : 1, day : 1)
        dateOfEndOfUnemployAlloc = 3.years.from(dateOfRetirement)!
        nbPointsFuturs = try XCTUnwrap(RegimeAgircTest.regimeAgirc.projectedNumberOfPoints(
                                        lastAgircKnownSituation  : lastAgircKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc))
        nbPointTheory = lastAgircKnownSituation.nbPoints +
            (3 - 1) * lastAgircKnownSituation.pointsParAn
        XCTAssertEqual(nbPointTheory, nbPointsFuturs)
        
        // date de fin de chomage antérieure à la date du dernier relevé de points
        dateOfRetirement = date(year: 2014, month: 1, day: 1)
        dateOfEndOfUnemployAlloc = 3.years.from(dateOfRetirement)!
        nbPointsFuturs = try XCTUnwrap(RegimeAgircTest.regimeAgirc.projectedNumberOfPoints(
                                        lastAgircKnownSituation  : lastAgircKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc))
        nbPointTheory = lastAgircKnownSituation.nbPoints
        XCTAssertEqual(nbPointTheory, nbPointsFuturs)
    }
    
    func test_calcul_coef_minoration_majoration_liquidation_annee_taux_plein() throws {
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var dateOfRetirement         : Date
        var dateOfPensionLiquid      : Date
        var coefMinoration           : Double
        var coefTheory               : Double
        
        birthDate = date(year : 1964, month : 9, day : 22)
        
        // (1) Liquidation dans l'année date d'obtention du taux plein au régime général
        //     => pas de coef de réduction permanent
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 139, // taux plein à 62 ans + 9 mois
                                                    sam               : 0)
        dateOfRetirement    = (62.years + 9.months + 10.days).from(birthDate)! // fin d'activité salarié > 62 ans + 9 mois
        dateOfPensionLiquid = (62.years + 9.months + 10.days).from(birthDate)!  // liquidtation > 62 ans + 9 mois
        // (2) les 3 années suivant la date d'obtention du taux plein légal (et avant 67 ans)
        //     => minoration de 10% pendant 3 ans s’applique au montant de votre retraite complémentaire
        for during in (dateOfPensionLiquid.year)...min(birthDate.year + 66, (dateOfPensionLiquid.year + 3)) {
            coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                            birthDate                : birthDate,
                                            lastKnownSituation       : lastKnownSituation,
                                            dateOfRetirement         : dateOfRetirement,
                                            dateOfEndOfUnemployAlloc : nil,
                                            dateOfPensionLiquid      : dateOfPensionLiquid,
                                            during                   : during))
            // pas de réduction de pension au-delà de 67 ans
            coefTheory = 0.9
            XCTAssertEqual(coefTheory, coefMinoration)
        }

        // (2) on a dépassé l'âge d'obtention du taux plein légal (67 ans)
        //     => taux plein
        for during in (birthDate.year + 67)...(birthDate.year + 90) {
            coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                            birthDate                : birthDate,
                                            lastKnownSituation       : lastKnownSituation,
                                            dateOfRetirement         : dateOfRetirement,
                                            dateOfEndOfUnemployAlloc : nil,
                                            dateOfPensionLiquid      : dateOfPensionLiquid,
                                            during                   : during))
            // pas de réduction de pension au-delà de 67 ans
            coefTheory = 1.0
            XCTAssertEqual(coefTheory, coefMinoration)
        }
    }
    
    func test_calcul_coef_minoration_majoration_liquidation_annee_taux_plein_plus_1() throws {
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var dateOfRetirement         : Date
        var dateOfPensionLiquid      : Date
        var coefMinoration           : Double
        var coefTheory               : Double
        
        birthDate = date(year : 1964, month : 9, day : 22)
        
        // (1) Liquidation dans l'année date d'obtention du taux plein au régime général
        //     => pas de coef de réduction permanent
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 139, // taux plein à 62 ans + 9 mois
                                                    sam               : 0)
        dateOfRetirement    = (62.years + 9.months + 10.days + 1.years).from(birthDate)! // fin d'activité salarié > 64 ans + 9 mois
        dateOfPensionLiquid = (62.years + 9.months + 10.days + 1.years).from(birthDate)!  // liquidtation > 64 ans + 9 mois
        
        //  (2)   => taux plein
        for during in (dateOfPensionLiquid.year)...(birthDate.year + 90) {
            coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                            birthDate                : birthDate,
                                            lastKnownSituation       : lastKnownSituation,
                                            dateOfRetirement         : dateOfRetirement,
                                            dateOfEndOfUnemployAlloc : nil,
                                            dateOfPensionLiquid      : dateOfPensionLiquid,
                                            during                   : during))
            coefTheory = 1.0
            XCTAssertEqual(coefTheory, coefMinoration)
        }
    }
    
    func test_calcul_coef_minoration_majoration_liquidation_annee_taux_plein_plus_2() throws {
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var dateOfRetirement         : Date
        var dateOfPensionLiquid      : Date
        var during                   : Int
        var coefMinoration           : Double
        var coefTheory               : Double
        
        birthDate = date(year : 1964, month : 9, day : 22)
        
        // (1) Liquidation dans l'année date d'obtention du taux plein au régime général
        //     => pas de coef de réduction permanent
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 139, // taux plein à 62 ans + 9 mois
                                                    sam               : 0)
        dateOfRetirement    = (62.years + 9.months + 10.days + 2.years).from(birthDate)! // fin d'activité salarié > 64 ans + 9 mois
        dateOfPensionLiquid = (62.years + 9.months + 10.days + 2.years).from(birthDate)!  // liquidtation > 64 ans + 9 mois
        
        // (2) l'année suivant la date d'obtention du taux plein légal (et avant 67 ans)
        //     => taux plein majoré de 10% pendant 1 an
        during = dateOfPensionLiquid.year
        coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))
        //     => taux plein majoré de 10% pendant 1 an
        coefTheory = 1.1
        XCTAssertEqual(coefTheory, coefMinoration)
        during = min(dateOfPensionLiquid.year + 1, birthDate.year + 66)
        coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))
        //     => taux plein majoré de 10% pendant 1 an
        coefTheory = 1.1
        XCTAssertEqual(coefTheory, coefMinoration)
        
        // (2) ensuite
        //     => taux plein
        for during in (dateOfPensionLiquid.year + 2)...(birthDate.year + 90) {
            coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                            birthDate                : birthDate,
                                            lastKnownSituation       : lastKnownSituation,
                                            dateOfRetirement         : dateOfRetirement,
                                            dateOfEndOfUnemployAlloc : nil,
                                            dateOfPensionLiquid      : dateOfPensionLiquid,
                                            during                   : during))
            // pas de réduction de pension au-delà de 67 ans
            coefTheory = 1.0
            XCTAssertEqual(coefTheory, coefMinoration)
        }
    }
    
    func test_calcul_coef_minoration_majoration_liquidation_annee_taux_plein_plus_3() throws {
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var dateOfRetirement         : Date
        var dateOfPensionLiquid      : Date
        var during                   : Int
        var coefMinoration           : Double
        var coefTheory               : Double
        
        birthDate = date(year : 1964, month : 9, day : 22)
        
        // (1) Liquidation dans l'année date d'obtention du taux plein au régime général
        //     => pas de coef de réduction permanent
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 139, // taux plein à 62 ans + 9 mois
                                                    sam               : 0)
        dateOfRetirement    = (62.years + 9.months + 10.days + 3.years).from(birthDate)! // fin d'activité salarié > 64 ans + 9 mois
        dateOfPensionLiquid = (62.years + 9.months + 10.days + 3.years).from(birthDate)!  // liquidtation > 64 ans + 9 mois
        
        // (2) l'année suivant la date d'obtention du taux plein légal (et avant 67 ans)
        //     => taux plein majoré de 10% pendant 1 an
        during = dateOfPensionLiquid.year
        coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))
        //     => taux plein majoré de 20% pendant 1 an
        coefTheory = 1.2
        XCTAssertEqual(coefTheory, coefMinoration)
        during = min(dateOfPensionLiquid.year + 1, birthDate.year + 66)
        coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))
        //     => taux plein majoré de 20% pendant 1 an
        coefTheory = 1.2
        XCTAssertEqual(coefTheory, coefMinoration)
        
        // (2) ensuite
        //     => taux plein
        for during in (min(dateOfPensionLiquid.year + 1, birthDate.year + 66)+1)...(birthDate.year + 90) {
            coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                            birthDate                : birthDate,
                                            lastKnownSituation       : lastKnownSituation,
                                            dateOfRetirement         : dateOfRetirement,
                                            dateOfEndOfUnemployAlloc : nil,
                                            dateOfPensionLiquid      : dateOfPensionLiquid,
                                            during                   : during))
            // pas de réduction de pension au-delà de 67 ans
            coefTheory = 1.0
            XCTAssertEqual(coefTheory, coefMinoration)
        }
    }
    
    func test_calcul_coef_minoration_majoration_liquidation_avant_age_legal() throws {
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var dateOfRetirement         : Date
        var dateOfPensionLiquid      : Date
        var during                   : Int
        var coefMinoration           : Double
        var coefTheory               : Double
        
        birthDate = date(year : 1964, month : 9, day : 22)
        
        // (1) Liquidation avant l'age minimul de liquidation de la pension AGIRC
        //     => pas de résultat
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 135,
                                                    sam               : 0)
        dateOfRetirement    = (55.years + 10.days).from(birthDate)!
        dateOfPensionLiquid = (55.years + 10.days).from(birthDate)!
        during = dateOfPensionLiquid.year

        XCTAssertNil(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))

        // (1) Liquidation à l'age minimul de liquidation de la pension AGIRC
        //     => coef de réduction permanent
        dateOfRetirement    = (57.years + 10.days).from(birthDate)!
        dateOfPensionLiquid = (57.years + 10.days).from(birthDate)!
        during = dateOfPensionLiquid.year

        coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))
        coefTheory = 0.43
        XCTAssertEqual(coefTheory, coefMinoration)

    }

    func test_calcul_coef_minoration_majoration_liquidation_apres_age_legal_avant_taux_plein() throws {
    }
    
    func test_calcul_coef_majoration_pour_enfant() {
        XCTAssertEqual(1.0, RegimeAgircTest.regimeAgirc.coefMajorationPourEnfant(nbEnfantACharge: -1))
        XCTAssertEqual(1.05, RegimeAgircTest.regimeAgirc.coefMajorationPourEnfant(nbEnfantACharge: 1))
        XCTAssertEqual(1.1, RegimeAgircTest.regimeAgirc.coefMajorationPourEnfant(nbEnfantACharge: 2))
    }
    
    func test_calcul_pension() throws {
        var lastAgircKnownSituation  : RegimeAgircSituation
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var dateOfRetirement         : Date
        var dateOfEndOfUnemployAlloc : Date?
        var dateOfPensionLiquid      : Date
        var ageOfPensionLiquidComp   : DateComponents
        var during                   : Int?
        let sam = 36698.0
        var nbPointTheory  : Int
        
        birthDate          = date(year: 1964, month: 9, day: 22)
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 135,
                                                    sam               : sam)
        lastAgircKnownSituation = RegimeAgircSituation(atEndOf     : 2018,
                                                       nbPoints    : 17907,
                                                       pointsParAn : 788)
        dateOfRetirement = date(year : 2022, month : 1, day : 1) // fin d'activité salarié
        dateOfEndOfUnemployAlloc = 3.years.from(dateOfRetirement) // fin d'indemnisation chomage 3 ans plus tard
        dateOfPensionLiquid      = 62.years.from(birthDate)! // liquidation à 62 ans
        ageOfPensionLiquidComp = DateComponents(calendar : Date.calendar,
                                                year     : 62,
                                                month    : 0,
                                                day      : 0,
                                                hour     : 0)
        during = dateOfPensionLiquid.year
        let pension = try XCTUnwrap(RegimeAgircTest.regimeAgirc.pension(
                                        lastAgircKnownSituation  : lastAgircKnownSituation,
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        ageOfPensionLiquidComp   : ageOfPensionLiquidComp,
                                        during                   : during))
        nbPointTheory = lastAgircKnownSituation.nbPoints +
            (2021 - 2018) * lastAgircKnownSituation.pointsParAn +
            (3) * lastAgircKnownSituation.pointsParAn
        XCTAssertEqual(1.0 - 14.5/100.0, pension.coefMinoration)
        XCTAssertEqual(nbPointTheory, pension.projectedNbOfPoints)
        XCTAssertEqual(1, pension.pensionBrute)
        XCTAssertEqual(1, pension.pensionNette)
    }
}
