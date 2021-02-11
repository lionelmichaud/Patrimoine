//
//  RegimeGeneralTest.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 16/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Patrimoine

class RegimeGeneralTest: XCTestCase { // swiftlint:disable:this type_body_length
    
    static var regimeGeneral: RegimeGeneral!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = RegimeGeneral.Model(for                  : RegimeGeneralTest.self,
                                        from                 : nil,
                                        dateDecodingStrategy : .iso8601,
                                        keyDecodingStrategy  : .useDefaultKeys)
        RegimeGeneralTest.regimeGeneral = RegimeGeneral(model: model)
        
        // inject dependency for tests
        RegimeGeneral.setSocioEconomyModel(
            SocioEconomy.Model(for: SocioEconomyModelTest.self,
                               from                 : nil,
                               dateDecodingStrategy : .iso8601,
                               keyDecodingStrategy  : .useDefaultKeys)
                .initialized())
        RegimeGeneral.setFiscalModel(
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
    
    func test_saving_to_test_bundle() throws {
        RegimeGeneralTest.regimeGeneral.saveToBundle(for                  : RegimeGeneralTest.self,
                                                     to                   : nil,
                                                     dateEncodingStrategy : .iso8601,
                                                     keyEncodingStrategy  : .useDefaultKeys)
    }
    
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
    
    func test_recherche_nb_Trim_Acquis_Apres_Period_Chomage_Non_Indemnise() {
        var nbTrimDejaCotises     : Int
        var ageEnFinIndemnisation : Int
        var nb                    : Int?
        
        nbTrimDejaCotises     = 19
        ageEnFinIndemnisation = 50
        nb = RegimeGeneralTest.regimeGeneral.nbTrimAcquisApresPeriodNonIndemnise(
            nbTrimestreAcquis: nbTrimDejaCotises,
            ageAtEndOfUnemployementAlloc: ageEnFinIndemnisation)
        XCTAssertEqual(4, nb)
        
        nbTrimDejaCotises     = 90
        ageEnFinIndemnisation = 50
        nb = RegimeGeneralTest.regimeGeneral.nbTrimAcquisApresPeriodNonIndemnise(
            nbTrimestreAcquis: nbTrimDejaCotises,
            ageAtEndOfUnemployementAlloc: ageEnFinIndemnisation)
        XCTAssertEqual(4, nb)
        
        nbTrimDejaCotises     = 90
        ageEnFinIndemnisation = 56
        nb = RegimeGeneralTest.regimeGeneral.nbTrimAcquisApresPeriodNonIndemnise(
            nbTrimestreAcquis: nbTrimDejaCotises,
            ageAtEndOfUnemployementAlloc: ageEnFinIndemnisation)
        XCTAssertEqual(20, nb)
        
        nbTrimDejaCotises     = 19
        ageEnFinIndemnisation = 56
        nb = RegimeGeneralTest.regimeGeneral.nbTrimAcquisApresPeriodNonIndemnise(
            nbTrimestreAcquis: nbTrimDejaCotises,
            ageAtEndOfUnemployementAlloc: ageEnFinIndemnisation)
        XCTAssertEqual(4, nb)
    }
    
    func test_recherche_age_Taux_Plein_Legal() {
        var age: Int?
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1948)
        XCTAssertEqual(61, age)
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1953)
        XCTAssertEqual(62, age)
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1956)
        XCTAssertEqual(64, age)
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1963)
        XCTAssertEqual(66, age)
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1964)
        XCTAssertEqual(67, age)
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1967)
        XCTAssertEqual(67, age)
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

    func test_calcul_duree_assurance_sans_période_de_chomage() {
        var lastKnownSituation    : RegimeGeneralSituation
        var dateOfRetirement      : Date
        var birthDate             : Date
        var extrapolationDuration : Int
        
        birthDate = date(year: 1964, month: 9, day: 22)
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 135,
                                                    sam               : 0.0)
        // Cessation d'activité 6 ans après la date du dernier relevé de situation
        extrapolationDuration = 6 // ans
        dateOfRetirement = extrapolationDuration.years.from(lastDayOf(year: 2019))!
        if let duree = RegimeGeneralTest.regimeGeneral.dureeAssurance(
            birthDate                : birthDate,
            lastKnownSituation       : lastKnownSituation,
            dateOfRetirement         : dateOfRetirement,
            dateOfEndOfUnemployAlloc : nil
        ) {
            let theory = 135 + extrapolationDuration * 4 // 159
            XCTAssertEqual(theory, duree.plafonne)
            XCTAssertEqual(theory, duree.deplafonne)
        } else {
            XCTFail("dureeAssurance failed")
        }
        
        // Cessation d'activité 6 ans + 9 mois après la date du dernier relevé de situation
        dateOfRetirement = 3.quarters.from(dateOfRetirement)!
        if let duree = RegimeGeneralTest.regimeGeneral.dureeAssurance(
            birthDate                : birthDate,
            lastKnownSituation       : lastKnownSituation,
            dateOfRetirement         : dateOfRetirement,
            dateOfEndOfUnemployAlloc : nil
        ) {
            let theory = 135 + extrapolationDuration * 4 + 3 // 162
            XCTAssertEqual(theory, duree.plafonne)
            XCTAssertEqual(theory, duree.deplafonne)
        } else {
            XCTFail("dureeAssurance failed")
        }
        
        // Cessation d'activité 20 ans après la date du dernier relevé de situation
        // la durée d'assurance ne peut dépasser la durée de référence soit 169 trimestres
        extrapolationDuration = 20 // ans
        dateOfRetirement = extrapolationDuration.years.from(lastDayOf(year: 2019))!
        if let duree = RegimeGeneralTest.regimeGeneral.dureeAssurance(
            birthDate                : birthDate,
            lastKnownSituation       : lastKnownSituation,
            dateOfRetirement         : dateOfRetirement,
            dateOfEndOfUnemployAlloc : nil
        ) {
            let theory = 169 // durée de référence pour une personne née en 1964
            XCTAssertEqual(theory, duree.plafonne)
        } else {
            XCTFail("dureeAssurance failed")
        }
    }

    func test_calcul_duree_assurance_avec_periode_de_chomage() {
        var lastKnownSituation       : RegimeGeneralSituation
        var dateOfRetirement         : Date
        var dateOfEndOfUnemployAlloc : Date?
        var birthDate                : Date
        
        birthDate = date(year: 1964, month: 9, day: 22)
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 135,
                                                    sam               : 0.0)
        // cas où la période de 20 trimestres chomage (+55 ans) se prolonge au-delà de l'age min de départ à la retraite (62 ans)
        dateOfRetirement = 2.years.from(lastDayOf(year: lastKnownSituation.atEndOf))!
        dateOfEndOfUnemployAlloc = 3.years.from(dateOfRetirement)!
        if let duree = RegimeGeneralTest.regimeGeneral.dureeAssurance(
            birthDate                : birthDate,
            lastKnownSituation       : lastKnownSituation,
            dateOfRetirement         : dateOfRetirement,
            dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc
        ) {
            let case1 = 135 + (2 * 4) + (3 * 4) + 20 // 175
            let case2 = 135 - 2 + (1964 + 62 - 2019) * 4 // 161 à 62 ans
            let theory = min(case1, case2) // 161
            XCTAssertEqual(theory, duree.plafonne)
        } else {
            XCTFail("dureeAssurance failed")
        }
        
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 79,
                                                    sam               : 0.0)
        // cas où la période de 4 trimestres chomage (80 trim acquis) se termine avant l'age min de départ à la retraite (62 ans)
        dateOfRetirement = 1.years.before(lastDayOf(year: 2019))!
        dateOfEndOfUnemployAlloc = 2.years.from(lastDayOf(year: 2019))!
        if let duree = RegimeGeneralTest.regimeGeneral.dureeAssurance(
            birthDate                : birthDate,
            lastKnownSituation       : lastKnownSituation,
            dateOfRetirement         : dateOfRetirement,
            dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc
        ) {
            XCTAssertEqual(79 + (2 + 1) * 4, duree.plafonne)
        } else {
            XCTFail("dureeAssurance failed")
        }
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
                // le test doit échouer car dureeAssurance > dureeDeReference
                XCTFail("fail")
                
            case .failure(let error):
                XCTAssertEqual(RegimeGeneral.ModelError.outOfBounds, error)
        }
        
        // decote
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 65.years.from(birthDate)! // manquent 2 ans = 8 trimestres manquant pour atteindre age du taux plein
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
        
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 65.years.from(birthDate)! // manquent 2 ans = 8 trimestres manquant pour atteindre age du taux plein
        dureeAssurance      = 140
        dureeDeReference    = 150 // 10 trimestre manquant pour avoir tous les trimestres
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
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 57.years.from(birthDate)! // manquent 10 ans = 40 trimestres manquant pour atteindre age du taux plein
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
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 57.years.from(birthDate)! // manquent 10 ans = 40 trimestres manquant pour atteindre age du taux plein
        dureeAssurance      = 140
        dureeDeReference    = 170 // 30 trimestre manquant pour avoir tous les trimestres
        nbTrim = RegimeGeneralTest.regimeGeneral.nbTrimestreSurDecote(birthDate           : birthDate,
                                                                      dureeAssurance      : dureeAssurance,
                                                                      dureeDeReference    : dureeDeReference,
                                                                      dateOfPensionLiquid : dateOfPensionLiquid)
        XCTAssertNotNil(nbTrim)
        XCTAssertEqual(-20, nbTrim)
        
        // decote
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 65.years.from(birthDate)! // manquent 2 ans = 8 trimestres manquant pour atteindre age du taux plein
        dureeAssurance      = 140
        dureeDeReference    = 150 // 5 trimestre manquant pour avoir tous les trimestres
        nbTrim = RegimeGeneralTest.regimeGeneral.nbTrimestreSurDecote(birthDate           : birthDate,
                                                                      dureeAssurance      : dureeAssurance,
                                                                      dureeDeReference    : dureeDeReference,
                                                                      dateOfPensionLiquid : dateOfPensionLiquid)
        XCTAssertNotNil(nbTrim)
        XCTAssertEqual(-(67 - 65) * 4, nbTrim)
        
        // surcote
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 60.years.from(birthDate)! // manquent 2 ans = 8 trimestres manquant pour atteindre age du taux plein
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
        date = RegimeGeneralTest.regimeGeneral.dateAgeTauxPlein(
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
    
    func test_date_Age_Taux_Plein_Legal() {
        var birthDate           : Date!
        var date                : Date?
        
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : 1964,
                                         month    : 9,
                                         day      : 22)
        birthDate = Date.calendar.date(from: dateRefComp)!
        date = RegimeGeneralTest.regimeGeneral.dateTauxPleinLegal(birthDate: birthDate)
        XCTAssertNotNil(date)
        XCTAssertEqual(1964 + 67, date!.year)
        XCTAssertEqual(9, date!.month)
        XCTAssertEqual(22, date!.day)
    }
    
    func test_calcul_taux_de_pension() {
        var dureeAssurance      : Int
        var dureeDeReference    : Int
        var birthDate           : Date!
        var dateOfPensionLiquid : Date!
        var taux : Double?
        
        // decote plafonnée
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 57.years.from(birthDate)! // manquent 10 ans = 40 trimestres manquant pour atteindre age du taux plein
        dureeAssurance      = 140
        dureeDeReference    = 170 // 30 trimestre manquant pour avoir tous les trimestres
        taux = RegimeGeneralTest.regimeGeneral.tauxDePension(birthDate           : birthDate,
                                                             dureeAssurance      : dureeAssurance,
                                                             dureeDeReference    : dureeDeReference,
                                                             dateOfPensionLiquid : dateOfPensionLiquid)
        XCTAssertNotNil(taux)
        XCTAssertEqual(50.0 - 20.0 * 0.625, taux)
        
        // decote
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 65.years.from(birthDate)! // manquent 2 ans = 8 trimestres manquant pour atteindre age du taux plein
        dureeAssurance      = 140
        dureeDeReference    = 150 // 5 trimestre manquant pour avoir tous les trimestres
        taux = RegimeGeneralTest.regimeGeneral.tauxDePension(birthDate           : birthDate,
                                                             dureeAssurance      : dureeAssurance,
                                                             dureeDeReference    : dureeDeReference,
                                                             dateOfPensionLiquid : dateOfPensionLiquid)
        XCTAssertNotNil(taux)
        XCTAssertEqual(50.0 - (67 - 65) * 4 * 0.625, taux)
        
        // surcote
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 60.years.from(birthDate)! // manquent 7 ans = 28 trimestres manquant pour atteindre age du taux plein
        dureeAssurance   = 145
        dureeDeReference = 140
        taux = RegimeGeneralTest.regimeGeneral.tauxDePension(birthDate           : birthDate,
                                                             dureeAssurance      : dureeAssurance,
                                                             dureeDeReference    : dureeDeReference,
                                                             dateOfPensionLiquid : dateOfPensionLiquid)
        XCTAssertNotNil(taux)
        XCTAssertEqual(50.0 * (1.0 + Double(dureeAssurance - dureeDeReference) * 1.25/100.0), taux)
    }
    
    func test_calcul_pension_sans_periode_de_chomage() {
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var nbEnfant                 : Int
        var dateOfRetirement         : Date
        var dateOfPensionLiquid      : Date
        var theory                   : Double = 0
        let sam = 36698.0
        
        // cas de travail salarié jusqu'à la retraite à taux plein
        birthDate          = date(year: 1964, month: 9, day: 22)
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 135,
                                                    sam               : sam)
        nbEnfant = 3
        dateOfRetirement = date(year: 2028, month: 7, day: 1) // date du taux plein
        dateOfPensionLiquid = dateOfRetirement
        
        if let (tauxDePension,
                majorationEnfant,
                dureeDeReference,
                dureeAssurancePlafonne,
                dureeAssuranceDeplafonne,
                pensionBrute,
                _) = RegimeGeneralTest.regimeGeneral.pension(
                    birthDate                : birthDate,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : nil,
                    dateOfPensionLiquid      : dateOfPensionLiquid,
                    lastKnownSituation       : lastKnownSituation,
                    nbEnfant                 : nbEnfant,
                    during                   : nil) {
            
            XCTAssertEqual(10.0, majorationEnfant)
            XCTAssertEqual(169, dureeDeReference)
            XCTAssertEqual(169, dureeAssurancePlafonne)
            XCTAssertEqual(169, dureeAssuranceDeplafonne)
            XCTAssertEqual(50.0, tauxDePension)
            theory = lastKnownSituation.sam * tauxDePension/100 * (1.0 + majorationEnfant/100) * dureeAssurancePlafonne.double() / dureeDeReference.double()
            print("** Cas de travail salarié jusqu'à la retraite à taux plein")
            print("**  - Pension annuelle  = \(theory)")
            print("**  - Pension mensuelle = \(theory / 12.0)")
            XCTAssertEqual(theory, pensionBrute)
        } else {
            XCTFail("test_calcul_pension = nil")
        }
        if let (pensionBrute,
                _) = RegimeGeneralTest.regimeGeneral.pension(
                    birthDate                : birthDate,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : nil,
                    dateOfPensionLiquid      : dateOfPensionLiquid,
                    lastKnownSituation       : lastKnownSituation,
                    nbEnfant                 : nbEnfant,
                    during                   : nil) {
            XCTAssertEqual(theory, pensionBrute)
        } else {
            XCTFail("test_calcul_pension = nil")
        }
        
        // cas de travail salarié jusqu'à la retraite à 62 ans (décote)
        dateOfRetirement = (62.years + 10.days).from(birthDate)! // pousser au début du trimestre suivant
        dateOfPensionLiquid = dateOfRetirement
        if let (tauxDePension,
                majorationEnfant,
                dureeDeReference,
                dureeAssurancePlafonne,
                dureeAssuranceDeplafonne,
                pensionBrute,
                _) = RegimeGeneralTest.regimeGeneral.pension(
                    birthDate                : birthDate,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : nil,
                    dateOfPensionLiquid      : dateOfPensionLiquid,
                    lastKnownSituation       : lastKnownSituation,
                    nbEnfant                 : nbEnfant,
                    during                   : nil) {
            
            XCTAssertEqual(10.0, majorationEnfant)
            XCTAssertEqual(169, dureeDeReference)
            let dureeAssTherory = 135 - 1 + (1964 + 62 - 2019) * 4 // 162
            XCTAssertEqual(dureeAssTherory, dureeAssurancePlafonne)
            XCTAssertEqual(dureeAssTherory, dureeAssuranceDeplafonne)
            let tauxTheory = 50.0 - Double((dureeDeReference - dureeAssuranceDeplafonne)) * 0.625 // 45.625
            XCTAssertEqual(tauxTheory, tauxDePension)
            theory = lastKnownSituation.sam * tauxDePension/100 * (1.0 + majorationEnfant/100) * dureeAssurancePlafonne.double() / dureeDeReference.double()
            print("** Cas de travail salarié jusqu'à la retraite à 62 ans (décote)")
            print("**  - Pension annuelle  = \(theory)")
            print("**  - Pension mensuelle = \(theory / 12.0)")
            XCTAssertEqual(theory, pensionBrute)
        } else {
            XCTFail("test_calcul_pension = nil")
        }
        if let (pensionBrute,
                _) = RegimeGeneralTest.regimeGeneral.pension(
                    birthDate                : birthDate,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : nil,
                    dateOfPensionLiquid      : dateOfPensionLiquid,
                    lastKnownSituation       : lastKnownSituation,
                    nbEnfant                 : nbEnfant,
                    during                   : nil) {
            XCTAssertEqual(theory, pensionBrute)
        } else {
            XCTFail("test_calcul_pension = nil")
        }
        
        // cas de travail salarié jusqu'à la retraite à 67 ans (surcote)
        dateOfRetirement = (67.years + 10.days).from(birthDate)!
        dateOfPensionLiquid = dateOfRetirement
        if let (tauxDePension,
                majorationEnfant,
                dureeDeReference,
                dureeAssurancePlafonne,
                dureeAssuranceDeplafonne,
                pensionBrute,
                _) = RegimeGeneralTest.regimeGeneral.pension(
                    birthDate                : birthDate,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : nil,
                    dateOfPensionLiquid      : dateOfPensionLiquid,
                    lastKnownSituation       : lastKnownSituation,
                    nbEnfant                 : nbEnfant,
                    during                   : nil) {
            
            XCTAssertEqual(10.0, majorationEnfant)
            XCTAssertEqual(169, dureeDeReference)
            XCTAssertEqual(169, dureeAssurancePlafonne)
            let tauxTheory = 50.0 * (1.0 + Double(dureeAssuranceDeplafonne - dureeDeReference) * 1.25/100.0) // 66.25
            XCTAssertEqual(tauxTheory, tauxDePension)
            theory = lastKnownSituation.sam * tauxDePension/100 * (1.0 + majorationEnfant/100) * dureeAssurancePlafonne.double() / dureeDeReference.double()
            print("** Cas de travail salarié jusqu'à la retraite à 67 ans (surcote)")
            print("**  - Pension annuelle  = \(theory)")
            print("**  - Pension mensuelle = \(theory / 12.0)")
            XCTAssertEqual(theory, pensionBrute)
        } else {
            XCTFail("test_calcul_pension = nil")
        }
        if let (pensionBrute,
                _) = RegimeGeneralTest.regimeGeneral.pension(
                    birthDate                : birthDate,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : nil,
                    dateOfPensionLiquid      : dateOfPensionLiquid,
                    lastKnownSituation       : lastKnownSituation,
                    nbEnfant                 : nbEnfant,
                    during                   : nil) {
            XCTAssertEqual(theory, pensionBrute)
        } else {
            XCTFail("test_calcul_pension = nil")
        }
        
        // cas de travail salarié jusqu'à fin 2021 puis rien jusqu'à liquidation à 62 ans
        dateOfRetirement = 62.years.from(birthDate)!
        dateOfPensionLiquid = 62.years.from(birthDate)!
        
    }
    
    func test_calcul_pension_avec_periode_de_chomage() {
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var nbEnfant                 : Int
        var dateOfRetirement         : Date
        var dateOfEndOfUnemployAlloc : Date?
        var dateOfPensionLiquid      : Date
        var theory                   : Double = 0
        let sam = 36698.0
        
        // cas de travail salarié jusqu'à la retraite à taux plein
        birthDate          = date(year: 1964, month: 9, day: 22)
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 135,
                                                    sam               : sam)
        nbEnfant = 3
        dateOfRetirement         = date(year : 2022, month : 1, day : 1) // fin d'activité salarié
        dateOfEndOfUnemployAlloc = 3.years.from(dateOfRetirement) // fin d'indemnisation chomage 3 ans plus tard
        dateOfPensionLiquid      = 62.years.from(birthDate)! // liquidation à 62 ans
        
        if let (tauxDePension,
                majorationEnfant,
                dureeDeReference,
                dureeAssurancePlafonne,
                dureeAssuranceDeplafonne,
                pensionBrute,
                _) = RegimeGeneralTest.regimeGeneral.pension(
                    birthDate                : birthDate,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc,
                    dateOfPensionLiquid      : dateOfPensionLiquid,
                    lastKnownSituation       : lastKnownSituation,
                    nbEnfant                 : nbEnfant,
                    during                   : nil) {
            
            XCTAssertEqual(10.0, majorationEnfant)
            XCTAssertEqual(169, dureeDeReference)
            let case1 = 135 + (2 * 4) + (3 * 4) + 20 // 175
            let case2 = 135 - 2 + (1964 + 62 - 2019) * 4 // 161 à 62 ans
            let dureeAssTheory = min(case1, case2) // 161
            XCTAssertEqual(dureeAssTheory, dureeAssurancePlafonne)
            XCTAssertEqual(dureeAssTheory, dureeAssuranceDeplafonne)
            let tauxTheory = 50.0 - Double(dureeDeReference - dureeAssurancePlafonne) * 0.625
            XCTAssertEqual(tauxTheory, tauxDePension)
            theory = lastKnownSituation.sam * tauxDePension/100 * (1.0 + majorationEnfant/100) * dureeAssurancePlafonne.double() / dureeDeReference.double()
            print("** Cas de travail salarié jusqu'à la retraite à taux plein")
            print("**  - Pension annuelle  = \(theory)")
            print("**  - Pension mensuelle = \(theory / 12.0)")
            XCTAssertEqual(theory, pensionBrute)
        } else {
            XCTFail("test_calcul_pension = nil")
        }
        if let (pensionBrute,
                _) = RegimeGeneralTest.regimeGeneral.pension(
                    birthDate                : birthDate,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc,
                    dateOfPensionLiquid      : dateOfPensionLiquid,
                    lastKnownSituation       : lastKnownSituation,
                    nbEnfant                 : nbEnfant,
                    during                   : nil) {
            XCTAssertEqual(theory, pensionBrute)
        } else {
            XCTFail("test_calcul_pension = nil")
        }
    }
} // swiftlint:disable:this file_length
