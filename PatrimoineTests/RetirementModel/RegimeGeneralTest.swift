//
//  RegimeGeneralTest.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 16/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class RegimeGeneralTest: XCTestCase {
    
    static var regimeGeneral: RegimeGeneral!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = RegimeGeneral.Model(for: RegimeGeneralTest.self,
                                        from                 : "RetirementRegimeGeneralModelConfigTest.json",
                                        dateDecodingStrategy : .iso8601,
                                        keyDecodingStrategy  : .useDefaultKeys)
        RegimeGeneralTest.regimeGeneral = RegimeGeneral(model: model)
        
        // inject dependency for tests
        RegimeGeneral.socioEconomyModel =
            SocioEconomy.Model(for: SocioEconomyModelTest.self,
                               from                 : "SocioEconomyModelConfig.json",
                               dateDecodingStrategy : .iso8601,
                               keyDecodingStrategy  : .useDefaultKeys)
            .initialized()
    }
    
    // MARK: Tests
    
    func test_pension_devaluation_rate() {
        XCTAssertEqual(2.0, RegimeGeneral.devaluationRate)
    }
    
    func test_nb_Trim_Additional() {
        XCTAssertEqual(4, RegimeGeneral.nbTrimAdditional)
    }
    
    func test_calcul_revaluation_Coef() {
        let dateOfPensionLiquid : Date! = 10.years.ago
        let thisYear = Date.now.year
        
        let coef = RegimeGeneral.revaluationCoef(during: thisYear,
                                                 dateOfPensionLiquid: dateOfPensionLiquid)
        XCTAssertEqual(pow((1.0 + -2.0/100.0), 10.0), coef)
    }
    
    func test_saving_to_test_bundle() throws {
        RegimeGeneralTest.regimeGeneral.model.saveToBundle(for: RegimeGeneralTest.self,
                                                           to: "RetirementRegimeGeneralModelConfigTest.json",
                                                           dateEncodingStrategy: .iso8601,
                                                           keyEncodingStrategy: .useDefaultKeys)
    }
    
    func test_recherche_nb_Trim_Acquis_Apres_Period_Chomage_Non_Indemnise() {
        var nbTrimDejaCotises: Int
        var nb: Int?
        
        nbTrimDejaCotises = 1
        nb = RegimeGeneralTest.regimeGeneral.nbTrimAcquisApresPeriodNonIndemnise(nbTrimestreAcquis: nbTrimDejaCotises)
        XCTAssertEqual(4, nb)
        
        nbTrimDejaCotises = 90
        nb = RegimeGeneralTest.regimeGeneral.nbTrimAcquisApresPeriodNonIndemnise(nbTrimestreAcquis: nbTrimDejaCotises)
        XCTAssertEqual(20, nb)
    }
    
    func test_recherche_age_Taux_Plein_Legal() {
        var age: Int?
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1963)
        XCTAssertEqual(67, age)
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1964)
        XCTAssertEqual(68, age)
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1980)
        XCTAssertEqual(71, age)
    }
    
    func test_recherche_duree_De_Reference() {
        var duree: Int?
        duree = RegimeGeneralTest.regimeGeneral.dureeDeReference(birthYear: 1963)
        XCTAssertEqual(168, duree)
        duree = RegimeGeneralTest.regimeGeneral.dureeDeReference(birthYear: 1964)
        XCTAssertEqual(169, duree)
        duree = RegimeGeneralTest.regimeGeneral.dureeDeReference(birthYear: 1980)
        XCTAssertEqual(172, duree)
    }
    
    func test_calcul_duree_assurance() {
        var lastKnownSituation       : RegimeGeneralSituation
        var dateOfRetirement         : Date
        var dateOfEndOfUnemployAlloc : Date?
        var extrapolationDuration    : Int
        var duree                    : Int
        
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 135,
                                                    sam               : 0.0)
        extrapolationDuration = 6 // ans
        dateOfRetirement = extrapolationDuration.years.from(lastDayOf(year: 2019))!
        dateOfEndOfUnemployAlloc = nil
        duree = RegimeGeneralTest.regimeGeneral.dureeAssurance(
            lastKnownSituation       : lastKnownSituation,
            dateOfRetirement         : dateOfRetirement,
            dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc
        )
        XCTAssertEqual(135 + extrapolationDuration * 4, duree)
        
        dateOfRetirement = 3.quarters.from(dateOfRetirement)!
        duree = RegimeGeneralTest.regimeGeneral.dureeAssurance(
            lastKnownSituation       : lastKnownSituation,
            dateOfRetirement         : dateOfRetirement,
            dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc
        )
        XCTAssertEqual(135 + extrapolationDuration * 4 + 3, duree)
        
        dateOfRetirement = extrapolationDuration.years.before(lastDayOf(year: 2019))!
        duree = RegimeGeneralTest.regimeGeneral.dureeAssurance(
            lastKnownSituation       : lastKnownSituation,
            dateOfRetirement         : dateOfRetirement,
            dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc
        )
        XCTAssertEqual(135, duree)
        
        extrapolationDuration = 6 // ans
        dateOfRetirement = 6.years.from(lastDayOf(year: 2019))!
        dateOfEndOfUnemployAlloc = 2.years.from(lastDayOf(year: 2019))!
        duree = RegimeGeneralTest.regimeGeneral.dureeAssurance(
            lastKnownSituation       : lastKnownSituation,
            dateOfRetirement         : dateOfRetirement,
            dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc
        )
        XCTAssertEqual(135 + 6 * 4, duree)
        
        dateOfRetirement = 10.years.from(lastDayOf(year: 2019))!
        dateOfEndOfUnemployAlloc = 2.years.from(lastDayOf(year: 2019))!
        duree = RegimeGeneralTest.regimeGeneral.dureeAssurance(
            lastKnownSituation       : lastKnownSituation,
            dateOfRetirement         : dateOfRetirement,
            dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc
        )
        XCTAssertEqual(135 + (2 + 5) * 4, duree)
        
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 79,
                                                    sam               : 0.0)
        dateOfRetirement = 10.years.from(lastDayOf(year: 2019))!
        dateOfEndOfUnemployAlloc = 2.years.from(lastDayOf(year: 2019))!
        duree = RegimeGeneralTest.regimeGeneral.dureeAssurance(
            lastKnownSituation       : lastKnownSituation,
            dateOfRetirement         : dateOfRetirement,
            dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc
        )
        XCTAssertEqual(79 + (2 + 1) * 4, duree)
    }
    
    func test_calcul_nb_trimestre_de_surcote() {
        var dureeAssurance   : Int
        var dureeDeReference : Int
        var result: Result<Int, RegimeGeneral.ModelError>
        
        // pas de surcote
        dureeAssurance   = 135
        dureeDeReference = 140
        result = RegimeGeneralTest.regimeGeneral.nbTrimestreSurcote(dureeAssurance   : dureeAssurance,
                                                                    dureeDeReference : dureeDeReference)
        switch result {
        case .success:
            XCTFail("fail")
            
        case .failure(let error):
            XCTAssertEqual(RegimeGeneral.ModelError.outOfBounds, error)
        }
        
        // surcote
        dureeAssurance   = 145
        dureeDeReference = 140
        result = RegimeGeneralTest.regimeGeneral.nbTrimestreSurcote(dureeAssurance   : dureeAssurance,
                                                                    dureeDeReference : dureeDeReference)
        switch result {
        case .success(let nbTrimestreSurcote):
            XCTAssertEqual(dureeAssurance - dureeDeReference, nbTrimestreSurcote)
            
        case .failure:
            XCTFail("fail")
        }
    }
    
    func test_calcul_nb_Trimestre_de_Decote() {
        let now = Date.now
        var dureeAssurance      : Int
        var dureeDeReference    : Int
        var birthDate           : Date
        var dateOfPensionLiquid : Date
        var result: Result<Int, RegimeGeneral.ModelError>
        
        // pas de decote
        birthDate           = now
        dateOfPensionLiquid = now
        dureeAssurance      = 145
        dureeDeReference    = 140
        result = RegimeGeneralTest.regimeGeneral.nbTrimestreDecote(birthDate           : birthDate,
                                                                   dureeAssurance      : dureeAssurance,
                                                                   dureeDeReference    : dureeDeReference,
                                                                   dateOfPensionLiquid : dateOfPensionLiquid)
        switch result {
        case .success:
            XCTFail("fail")
            
        case .failure(let error):
            XCTAssertEqual(RegimeGeneral.ModelError.outOfBounds, error)
        }
        
        // decote
        birthDate           = (-65).years.from(now)! // 2 ans = 8 trimestres manquant pour atteindre age du taux plein
        dateOfPensionLiquid = Date.now
        dureeAssurance      = 140
        dureeDeReference    = 145 // 5 trimestre manquant pour avoir tous les trimestres
        result = RegimeGeneralTest.regimeGeneral.nbTrimestreDecote(birthDate           : birthDate,
                                                                   dureeAssurance      : dureeAssurance,
                                                                   dureeDeReference    : dureeDeReference,
                                                                   dateOfPensionLiquid : dateOfPensionLiquid)
        switch result {
        case .success(let nbTrimestreSurcote):
            XCTAssertEqual(dureeDeReference - dureeAssurance, nbTrimestreSurcote)
            
        case .failure:
            XCTFail("fail")
        }
        
        birthDate           = (-65).years.from(now)! // 2 ans = 8 trimestres manquant pour atteindre age du taux plein
        dateOfPensionLiquid = Date.now
        dureeAssurance      = 140
        dureeDeReference    = 150 // 5 trimestre manquant pour avoir tous les trimestres
        result = RegimeGeneralTest.regimeGeneral.nbTrimestreDecote(birthDate           : birthDate,
                                                                   dureeAssurance      : dureeAssurance,
                                                                   dureeDeReference    : dureeDeReference,
                                                                   dateOfPensionLiquid : dateOfPensionLiquid)
        switch result {
        case .success(let nbTrimestreSurcote):
            XCTAssertEqual((67 - 65) * 4, nbTrimestreSurcote)
            
        case .failure:
            XCTFail("fail")
        }
        
        // decote plafonnée
        birthDate           = (-57).years.from(now)! // 10 ans = 40 trimestres manquant pour atteindre age du taux plein
        dateOfPensionLiquid = Date.now
        dureeAssurance      = 140
        dureeDeReference    = 170 // 30 trimestre manquant pour avoir tous les trimestres
        result = RegimeGeneralTest.regimeGeneral.nbTrimestreDecote(birthDate           : birthDate,
                                                                   dureeAssurance      : dureeAssurance,
                                                                   dureeDeReference    : dureeDeReference,
                                                                   dateOfPensionLiquid : dateOfPensionLiquid)
        switch result {
        case .success(let nbTrimestreSurcote):
            XCTAssertEqual(20, nbTrimestreSurcote)
            
        case .failure:
            XCTFail("fail")
        }
    }
    
    func test_calcul_nb_Trimestre_Surcote_Ou_Decote() {
        var dureeAssurance      : Int
        var dureeDeReference    : Int
        var birthDate           : Date!
        var dateOfPensionLiquid : Date!
        var nbTrim : Int?
        
        // decote plafonnée
        birthDate           = 57.years.ago // 10 ans = 40 trimestres manquant pour atteindre age du taux plein
        dateOfPensionLiquid = Date.now
        dureeAssurance      = 140
        dureeDeReference    = 170 // 30 trimestre manquant pour avoir tous les trimestres
        nbTrim = RegimeGeneralTest.regimeGeneral.nbTrimestreSurDecote(birthDate           : birthDate,
                                                                      dureeAssurance      : dureeAssurance,
                                                                      dureeDeReference    : dureeDeReference,
                                                                      dateOfPensionLiquid : dateOfPensionLiquid)
        XCTAssertNotNil(nbTrim)
        XCTAssertEqual(-20, nbTrim)
        
        // decote
        birthDate           = 65.years.ago // 2 ans = 8 trimestres manquant pour atteindre age du taux plein
        dateOfPensionLiquid = Date.now
        dureeAssurance      = 140
        dureeDeReference    = 150 // 5 trimestre manquant pour avoir tous les trimestres
        nbTrim = RegimeGeneralTest.regimeGeneral.nbTrimestreSurDecote(birthDate           : birthDate,
                                                                      dureeAssurance      : dureeAssurance,
                                                                      dureeDeReference    : dureeDeReference,
                                                                      dateOfPensionLiquid : dateOfPensionLiquid)
        XCTAssertNotNil(nbTrim)
        XCTAssertEqual(-(67 - 65) * 4, nbTrim)
        
        // surcote
        birthDate           = 60.years.ago // 2 ans = 8 trimestres manquant pour atteindre age du taux plein
        dateOfPensionLiquid = Date.now
        dureeAssurance   = 145
        dureeDeReference = 140
        nbTrim = RegimeGeneralTest.regimeGeneral.nbTrimestreSurDecote(birthDate           : birthDate,
                                                                      dureeAssurance      : dureeAssurance,
                                                                      dureeDeReference    : dureeDeReference,
                                                                      dateOfPensionLiquid : dateOfPensionLiquid)
        XCTAssertNotNil(nbTrim)
        XCTAssertEqual(dureeAssurance - dureeDeReference, nbTrim)
    }
    
    func test_coefficient_de_majoration_pour_Enfant() {
        XCTAssertEqual(0.0, RegimeGeneralTest.regimeGeneral.coefficientMajorationEnfant(nbEnfant: 1))
        XCTAssertEqual(0.0, RegimeGeneralTest.regimeGeneral.coefficientMajorationEnfant(nbEnfant: 2))
        XCTAssertEqual(10.0, RegimeGeneralTest.regimeGeneral.coefficientMajorationEnfant(nbEnfant: 3))
        XCTAssertEqual(10.0, RegimeGeneralTest.regimeGeneral.coefficientMajorationEnfant(nbEnfant: 4))
    }
    
    func test_calcul_date_Taux_Plein() {
        var lastKnownSituation  : RegimeGeneralSituation
        var birthDate           : Date!
        var date                : Date?
        
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 135,
                                                    sam               : 0.0)
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : 1964,
                                         month    : 9,
                                         day      : 22)
        birthDate = Date.calendar.date(from: dateRefComp)!
        date = RegimeGeneralTest.regimeGeneral.dateTauxPlein(
            birthDate          : birthDate,
            lastKnownSituation : lastKnownSituation)
        XCTAssertNotNil(date)
        XCTAssertEqual(2028, date!.year)
        XCTAssertEqual(6, date!.month)
        XCTAssertEqual(30, date!.day)
    }
    
    func test_date_Age_Minimum_Legal() {
        var birthDate           : Date!
        var date                : Date?
        
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : 1964,
                                         month    : 9,
                                         day      : 22)
        birthDate = Date.calendar.date(from: dateRefComp)!
        date = RegimeGeneralTest.regimeGeneral.dateAgeMinimumLegal(birthDate: birthDate)
        XCTAssertNotNil(date)
        XCTAssertEqual(1964 + 62, date!.year)
        XCTAssertEqual(9, date!.month)
        XCTAssertEqual(22, date!.day)
    }
    
    func test_date_Taux_Plein_Legal() {
        var birthDate           : Date!
        var date                : Date?
        
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : 1964,
                                         month    : 9,
                                         day      : 22)
        birthDate = Date.calendar.date(from: dateRefComp)!
        date = RegimeGeneralTest.regimeGeneral.dateTauxPleinLegal(birthDate: birthDate)
        XCTAssertNotNil(date)
        XCTAssertEqual(1964 + 68, date!.year)
        XCTAssertEqual(9, date!.month)
        XCTAssertEqual(22, date!.day)
    }
    
    func test_calcul_taux_de_pension() {
        
    }
    
    func test_calcul_pension() {
        
    }
}
