//
//  RegimeGeneral.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.RegimeGeneral")

// MARK: - Régime Général

struct RegimeGeneralSituation: Codable {
    var atEndOf           : Int    = Date.now.year
    var nbTrimestreAcquis : Int    = 0
    var sam               : Double = 0
}

struct RegimeGeneral: Codable {
    
    // MARK: - Nested types
    
    typealias PensionDetails = (tauxDePension    : Double,
                                majorationEnfant : Double,
                                dureeDeReference : Int,
                                dureeAssurance   : Int,
                                pensionBrute     : Double,
                                pensionNette     : Double)?
    
    enum ModelError: String, CustomStringConvertible, Error {
        case impossibleToCompute
        case ilegalValue
        case outOfBounds
        
        var description: String {
            self.rawValue
        }
    }
    
    struct Slice1: Codable {
        var birthYear   : Int
        var ndTrimestre : Int // nb de trimestre pour bénéficer du taux plein
        var ageTauxPlein: Int // age minimum pour bénéficer du taux plein sans avoir le nb de trimestres minimum
    }
    
    struct Slice2: Codable {
        var nbTrimestreAcquis  : Int
        var nbTrimNonIndemnise : Int
    }
    
    struct Model: BundleCodable {
        static var defaultFileName : String = "RetirementRegimeGeneralModelConfig.json"
        let dureeDeReferenceGrid   : [Slice1]
        let nbTrimNonIndemniseGrid : [Slice2]
        let ageMinimumLegal        : Int    // 62
        let nbOfYearForSAM         : Int    // 25 pour le calcul du SAM
        let maxReversionRate       : Double // 50.0 // % du SAM
        let decoteParTrimestre     : Double // 0.625 // % par trimestre
        let surcoteParTrimestre    : Double // 1.25  // % par trimestre
        let maxNbTrimestreDecote   : Int    // 20 // plafond
    }
    
    // MARK: - Static Properties
    
    static var simulationMode    : SimulationModeEnum = .deterministic
    // dependencies to other Models
    static var socioEconomyModel : SocioEconomy.Model = SocioEconomy.model
    
    static var devaluationRate: Double { // %
        socioEconomyModel.pensionDevaluationRate.value(withMode: simulationMode)
    }
    
    static var nbTrimAdditional: Double { // %
        socioEconomyModel.nbTrimTauxPlein.value(withMode: simulationMode)
    }
    
    static var yearlyRevaluationRate: Double { // %
        // on ne tient pas compte de l'inflation car les dépenses ne sont pas inflatées
        // donc les revenus non plus s'ils sont supposés progresser comme l'inflation
        // on ne tient donc compte que du delta par rapport à l'inflation
         -devaluationRate
    }
    
    // MARK: - Static Methods
    
    /// Coefficient de réévaluation de la pension en prenant comme base 1.0
    ///  la valeur à la date de liquidation de la pension.
    /// - Parameters:
    ///   - year: année de calcul du coefficient
    ///   - dateOfPensionLiquid: date de liquidation de la pension
    /// - Returns: Coefficient multiplicateur
    /// - Note: Coefficient = coef de dévaluation par rapport à l'inflation
    ///
    ///   On ne tient pas compte de l'inflation car les dépenses ne sont pas inflatées
    ///   donc les revenus non plus s'ils sont supposés progresser comme l'inflation
    ///   on ne tient donc compte que du delta par rapport à l'inflation
    static func revaluationCoef(during year         : Int,
                                dateOfPensionLiquid : Date) -> Double { // %
        pow(1.0 + yearlyRevaluationRate/100.0, Double(year - dateOfPensionLiquid.year))
    }
    
    // MARK: - Properties
    
    var model: Model
    
    // MARK: - Methods

    /// Calcul du taux de reversion en tenant compte d'une décote éventuelle
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - lastKnownSituation: dernière situation connue (année, nombre de trimestres de cotisation acquis)
    ///   - dateOfRetirementComp: date de demande de liquidation de la pension de retraite
    /// - Returns: taux de reversion en tenant compte d'une décote éventuelle en %
    func tauxDePension(birthDate           : Date,
                       dureeAssurance      : Int,
                       dureeDeReference    : Int,
                       dateOfPensionLiquid : Date) -> Double? {
        let result = nbTrimestreDecote(birthDate           : birthDate,
                                       dureeAssurance      : dureeAssurance,
                                       dureeDeReference    : dureeDeReference,
                                       dateOfPensionLiquid : dateOfPensionLiquid)
        switch result {
            case .success(let nbTrimestreDecote):
                // customLog.log(level: .info, "nb Trimestre Decote = \(nbTrimestreDecote, privacy: .public)")
                return model.maxReversionRate - model.decoteParTrimestre * nbTrimestreDecote.double()

            case .failure(let error):
                switch error {
                    case .outOfBounds:
                        // customLog.log(level: .info, "Surcote à calculer")
                        let result = nbTrimestreSurcote(dureeAssurance   : dureeAssurance,
                                                        dureeDeReference : dureeDeReference)
                        switch result {
                            case .success(let nbTrimestreSurcote):
                                // TODO: - prendre aussi en compte le cas Salarié plus favorable
                                return model.maxReversionRate + model.surcoteParTrimestre * nbTrimestreSurcote.double()
                                
                            case .failure(let error):
                                customLog.log(level: .default, "nbTrimestreSurcote: \(error)")
                                return nil
                        }

                    default:
                        customLog.log(level: .default, "nbTrimestreDecote: \(error)")
                        return nil
                }
        }
    }
    
    func nbTrimestreSurDecote(birthDate           : Date,
                              dureeAssurance      : Int,
                              dureeDeReference    : Int,
                              dateOfPensionLiquid : Date) -> Int? {
        let result = nbTrimestreDecote(birthDate           : birthDate,
                                       dureeAssurance      : dureeAssurance,
                                       dureeDeReference    : dureeDeReference,
                                       dateOfPensionLiquid : dateOfPensionLiquid)
        switch result {
            case .success(let nbTrimestreDecote):
                // il y a decote
                return -nbTrimestreDecote
                
            case .failure(let error):
                // il devrait y avoir surcote
                switch error {
                    case .outOfBounds:
                        let result = nbTrimestreSurcote(dureeAssurance   : dureeAssurance,
                                                        dureeDeReference : dureeDeReference)
                        switch result {
                            case .success(let nbTrimestreSurcote):
                                return nbTrimestreSurcote
                                
                            case .failure:
                                return nil
                        }
                        
                    default:
                        return nil
                }
        }
    }
    
    /// Calcul le nombre de trimestres supplémentaires obtenus, au-delà du minimum requis pour avoir une pension à taux plein
    /// - Parameters:
    ///   - dureeAssurance: nombre de trimestres d'assurance obtenus
    ///   - dureeDeReference: nombre de trimestres de référence pour obtenir le taux plein
    /// - Returns: nombre de trimestres de surcote obtenus
    func nbTrimestreSurcote(dureeAssurance   : Int,
                            dureeDeReference : Int) -> Result<Int, ModelError> {
        /// le nombre de trimestres supplémentaires entre la date de votre départ en retraite et
        /// la date à laquelle vous atteignez l'âge permettant de bénéficier automatiquement du taux plein
        guard dureeAssurance >= dureeDeReference else {
            return .failure(.outOfBounds)
        }
        
        let trimestreDeSurcote = dureeAssurance - dureeDeReference
        return .success(trimestreDeSurcote)
    }
    
    /// Calcul le nombre de trimestres manquants pour avoir une pension à taux plein
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - dureeAssurance: nb de trimestres cotisés
    ///   - dureeDeReference: nb de trimestres cotisés minimum pour avoir une pension à taux plein
    ///   - dateOfPensionLiquid: date de demande de liquidation de la pension de retraite
    /// - Returns: nombre de trimestres manquants pour avoir une pension à taux plein ou nil
    /// - Important: Pour déterminer le nombre de trimestres manquants, votre caisse de retraite compare :
    /// le nombre de trimestres manquants entre la date de votre départ en retraite et la date à laquelle vous atteignez l'âge permettant de bénéficier automatiquement du taux plein,
    /// et le nombre de trimestres manquant entre la date de votre départ en retraite et la durée d'assurance retraite ouvrant droit au taux plein.
    /// Le nombre de trimestres est arrondi au chiffre supérieur. Le nombre de trimestres manquants retenu est le plus avantageux pour vous.
    /// Le nombre de trimestres est plafonné à 20
    func nbTrimestreDecote(birthDate           : Date,
                           dureeAssurance      : Int,
                           dureeDeReference    : Int,
                           dateOfPensionLiquid : Date) -> Result<Int, ModelError> {
        guard dureeAssurance < dureeDeReference else {
            return .failure(.outOfBounds)
        }
        
        /// le nombre de trimestres manquants entre la date de votre départ en retraite et
        /// la date à laquelle vous atteignez l'âge permettant de bénéficier automatiquement du taux plein
        guard let dateDuTauxPlein = ageTauxPleinLegal(birthYear: birthDate.year)?.years.from(birthDate) else {
            customLog.log(level: .default, "date Du Taux Plein = nil")
            return .failure(.impossibleToCompute)
        }
        
        let duree = Date.calendar.dateComponents([.year, .month, .day],
                                                 from : dateOfPensionLiquid,
                                                 to   : dateDuTauxPlein)
        let (q1, r1) = duree.month!.quotientAndRemainder(dividingBy: 3)
        
        //    Le nombre de trimestres est arrondi au chiffre supérieur
        let trimestresManquantAgeTauxPlein = zeroOrPositive((duree.year! * 4) + (r1 > 0 ? q1 + 1 : q1))
        
        /// le nombre de trimestres manquant entre le nb de trimestre accumulés à la date de votre départ en retraite et
        /// la durée d'assurance retraite ouvrant droit au taux plein
        let trimestresManquantNbTrimestreTauxPlein = zeroOrPositive(dureeDeReference - dureeAssurance)
        
        // retenir le plus favorable des deux et limiter à 20 max
        return .success(min(trimestresManquantNbTrimestreTauxPlein,
                            trimestresManquantAgeTauxPlein,
                            model.maxNbTrimestreDecote))
    }
    
    /// Calcul la durée d'assurance à la date prévisionnelle de demande de liquidation de la pension de retraite
    /// - Parameters:
    ///   - lastKnownSituation: dernière situation connue (année, nombre de trimestres de cotisation acquis)
    ///   - dateOfRetirement: date de demande de liquidation de la pension de retraite
    ///   - dateOfEndOfUnemployAlloc: date de la fin d'indemnisation chômage après une période de travail
    /// - Returns: durée d'assurance en nombre de trimestres
    /// - Note:
    ///   - [service-public](https://www.service-public.fr/particuliers/vosdroits/F31249)
    ///   - [la-retraite-en-clair](https://www.la-retraite-en-clair.fr/parcours-professionnel-regimes-retraite/periode-inactivite-retraite/chomage-retraite)
    func dureeAssurance(lastKnownSituation       : RegimeGeneralSituation,
                        dateOfRetirement         : Date,
                        dateOfEndOfUnemployAlloc : Date?) -> Int {
        // date de la dernière situation connue
        let dateRef = lastDayOf(year: lastKnownSituation.atEndOf)
        
        var dateFinPeriodCotisationRetraite : Date
        if let dateFinAlloc = dateOfEndOfUnemployAlloc {
            // Période de travail suivi de période d'indemnisation chômage:
            // - Les périodes de chômage indemnisé sont considérées comme des trimestres d'assurance retraite au régime général de la Sécurité sociale dans la limite de 4 trimestres par an.
            // - Les périodes de chômage involontaire non indemnisé sont considérées comme des trimestres d'assurance retraite au régime général de la Sécurité sociale.
            //   - La 1re période de chômage non indemnisé, qu'elle soit continue ou non, est prise en compte dans la limite d'un an et demi (6 trimestres).
            //   - Chaque période ultérieure de chômage non indemnisé est prise en compte, dans la limite d’un an,
            //     à condition qu’elle succède sans interruption à une période de chômage indemnisé.
            //   - Cette deuxième limite est portée à 5 ans lorsque l’assuré justifie d’une durée de cotisation d’au moins 20 ans,
            //     est âgé d’au moins 55 ans à la date où il cesse de bénéficier du revenu de remplacement et ne relève pas à nouveau d’un régime obligatoire d’assurance vieillesse.
            let nbTrimSupplementaires = nbTrimAcquisApresPeriodNonIndemnise(nbTrimestreAcquis: lastKnownSituation.nbTrimestreAcquis)!
            dateFinPeriodCotisationRetraite = min(nbTrimSupplementaires.quarters.from(dateFinAlloc)!,
                                                  dateOfRetirement)
        } else {
            // période de travail non suivi de période d'indemnisation chômage
            dateFinPeriodCotisationRetraite = dateOfRetirement
        }
        
        if dateRef >= dateFinPeriodCotisationRetraite {
            // la date du dernier état est postérieure à la date de fin de cumul des trimestres, ils ne bougeront plus
            return lastKnownSituation.nbTrimestreAcquis
            
        } else {
            // on a encore des trimestres à accumuler
            let duree = Date.calendar.dateComponents([.year, .month, .day],
                                                     from: dateRef,
                                                     to  : dateFinPeriodCotisationRetraite)
            let (q, _) = duree.month!.quotientAndRemainder(dividingBy: 3)
            //    Le nombre de trimestres est arrondi au chiffre inférieur
            let nbTrimestreFutur = zeroOrPositive((duree.year! * 4) + q)
            
            return lastKnownSituation.nbTrimestreAcquis + nbTrimestreFutur
        }
    }
    
    /// Trouve  le nombre maximum de trimestre accumulable pendant une période de chômage non indemnisé
    /// suivant une période de de chômage indemnisé
    /// - Parameter nbTrimDejaCotises: nombre de trimestre cotisé au moment où débute la période de chômage non indemnisé
    /// - Returns: nombre maximum de trimestre accumulable pendant une période de chômage non indemnisé
    func nbTrimAcquisApresPeriodNonIndemnise(nbTrimestreAcquis : Int) -> Int? {
        model.nbTrimNonIndemniseGrid.last(\.nbTrimNonIndemnise, where: \.nbTrimestreAcquis, <=, nbTrimestreAcquis)
    }
    
    /// Trouve  la durée de référence pour obtenir une pension à taux plein
    /// - Parameter birthYear: Année de naissance
    /// - Returns: Durée de référence en nombre de trimestres pour obtenir une pension à taux plein ou nil
    func dureeDeReference(birthYear : Int) -> Int? {
        model.dureeDeReferenceGrid.last(\.ndTrimestre, where: \.birthYear, <=, birthYear)
    }
    
    /// Calcul le nb de trimestre manquant à la date prévisionnelle de demande de liquidation de la pension de retraite pour obtenir le taux plein
    /// - Parameters:
    ///   - birthYear: Année de naissance
    ///   - lastKnownSituation: dernière situation connue (année, nombre de trimestres de cotisation acquis)
    ///   - dateOfRetirement: date de demande de liquidation de la pension de retraite
    ///   - dateOfEndOfUnemployAlloc: date de la fin d'indemnisation chômage après une période de travail
    /// - Returns: nb de trimestre manquantà la date prévisionnelle de demande de liquidation de la pension de retraite pour obtenir le taux plein
    /// - Note: [la-retraite-en-clair](https://www.la-retraite-en-clair.fr/parcours-professionnel-regimes-retraite/periode-inactivite-retraite/chomage-retraite)
    func nbTrimManquantPourTauxPlein(birthYear                : Int,
                                     lastKnownSituation       : RegimeGeneralSituation,
                                     dateOfRetirement         : Date,
                                     dateOfEndOfUnemployAlloc : Date?) -> Int? {
        dureeDeReference(birthYear: birthYear) - dureeAssurance(lastKnownSituation      : lastKnownSituation,
                                                                dateOfRetirement        : dateOfRetirement,
                                                                dateOfEndOfUnemployAlloc: dateOfEndOfUnemployAlloc)
    }
    
    /// Trouve l'age minimum pour bénéficer du taux plein sans avoir le nb de trimestres minimum
    /// - Parameter birthYear: Année de naissance
    /// - Returns: Age minimum pour bénéficer du taux plein sans avoir le nb de trimestres minimumou nil
    func ageTauxPleinLegal(birthYear : Int) -> Int? {
        model.dureeDeReferenceGrid.last(\.ageTauxPlein, where: \.birthYear, <=, birthYear)
    }
    
    /// Calcule la date d'obtention du taux plein légal de retraite
    /// - Parameters:
    ///   - birthDate: date de naissance
    /// - Returns: date d'obtention du taux plein légal de retraite
    func dateTauxPleinLegal(birthDate: Date) -> Date? {
        guard let dateDuTauxPlein = ageTauxPleinLegal(birthYear: birthDate.year)?.years.from(birthDate) else {
            customLog.log(level: .default, "dateTauxPleinLegal: date Du Taux Plein = nil")
            return nil
        }
        return dateDuTauxPlein
    }
    
    func dateAgeMinimumLegal(birthDate: Date) -> Date? {
        model.ageMinimumLegal.years.from(birthDate)
    }
    
    /// Calcule la date d'obtention de tous les trimestres nécessaire pour obtenir le taux plein de retraite
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - lastKnownSituation: dernière situation connue (année, nombre de trimestres de cotisation acquis)
    /// - Returns: date d'obtention de tous les trimestres nécessaire pour obtenir le taux plein de retraite
    func dateTauxPlein(birthDate          : Date,
                       lastKnownSituation : RegimeGeneralSituation) -> Date? {
        guard let dureeDeReference = dureeDeReference(birthYear: birthDate.year) else {
            customLog.log(level: .default, "duree De Reference = nil")
            return nil
        }
        let trimestreManquant = zeroOrPositive(dureeDeReference - lastKnownSituation.nbTrimestreAcquis)
        let dateRef = lastDayOf(year: lastKnownSituation.atEndOf)
        guard let dateTousTrimestre = (trimestreManquant * 3).months.from(dateRef) else {
            customLog.log(level: .default, "date Tous Trimestre = nil")
            return nil
        }
        return dateTousTrimestre
    }
    
    /// Rend le coefficient de majoration de la pension pour enfants nés
    /// - Parameter nbEnfant: nombre d'enfants nés
    /// - Returns: coeffcient de majoration appliqué à la pension de retraite
    func coefficientMajorationEnfant(nbEnfant: Int) -> Double {
        switch nbEnfant {
            case 3...:
                return 10.0 // %
            default:
                return 0.0
        }
    }
    
    /// Calcul de la retraite brutte du salarié du secteur privé
    /// - Parameters:
    ///   - sam: Salaire annuel moyen
    ///   - tauxDePension: Taux de la pension
    ///   - dureeAssurance: Durée d'assurance du salarié au régime général
    ///   - dureeDeReference: Durée de référence pour obtenir une pension à taux plein
    ///   - majorationEnfant: coefficient de majoration de la pension pour enfants nés
    /// - Important: Votre salaire annuel moyen est déterminé en calculant la moyenne des salaires bruts ayant donné lieu à cotisation au régime général
    ///   durant les 25 années les plus avantageuses de votre carrière.
    ///   Tous les éléments de rémunération (salaire de base, primes, heures supplémentaires) et les indemnités journalières de maternité sont pris en compte
    ///   pour le calcul du salaire annuel moyen.
    ///   Si vous avez travaillé moins de 25 ans, votre salaire annuel moyen est égal à la moyenne de vos salaires bruts durant ces années de travail.
    ///   - tauxDePension: Taux de la pension
    ///   - dureeAssurance: Durée d'assurance du salarié au régime général
    ///   - birthYear: Année de naissance
    /// - Returns: Le montant brut de la pension de retraite
    func pension(sam              : Double,
                 tauxDePension    : Double,
                 majorationEnfant : Double,
                 dureeAssurance   : Int,
                 dureeDeReference : Int) -> Double {
        // Salaire annuel moyen x Taux de la pension x Majoration enfant x(Durée d'assurance du salarié au régime général / Durée de référence pour obtenir une pension à taux plein)
        sam * tauxDePension/100 * (1.0 + majorationEnfant/100) * dureeAssurance.double() / dureeDeReference.double()
    }
    
    /// Calcule les données relatives à la pension de retraite
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - dateOfRetirement: date de cessation d'activité
    ///   - dateOfEndOfUnemployAlloc: date de fin de perception des allocations chomage
    ///   - dateOfPensionLiquid: date de demande de liquidation de la pension
    ///   - lastKnownSituation: dernière situation connue pour le régime général
    ///   - nbEnfant: nb d'enfant aus sens de la retraite (pour les majorations)
    ///   - year: année de calcul
    /// - Returns: Les données relatives à la pension de retraite ou nil
    func pension(birthDate                : Date, // swiftlint:disable:this function_parameter_count
                 dateOfRetirement         : Date,
                 dateOfEndOfUnemployAlloc : Date?,
                 dateOfPensionLiquid      : Date,
                 lastKnownSituation       : RegimeGeneralSituation,
                 nbEnfant                 : Int,
                 during year              : Int? = nil)
    -> (brut : Double,
        net  : Double)? {
        // Salaire annuel moyen x Taux de la pension x Majoration enfant x(Durée d'assurance du salarié au régime général / Durée de référence pour obtenir une pension à taux plein)
        let dureeAssurance = self.dureeAssurance(lastKnownSituation       : lastKnownSituation,
                                                 dateOfRetirement         : dateOfRetirement,
                                                 dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc)
        
        guard let dureeDeReference = dureeDeReference(birthYear: birthDate.year) else {
            customLog.log(level: .default, "duree De Reference = nil")
            return nil
        }
        
        guard let tauxDePension = tauxDePension(birthDate           : birthDate,
                                                dureeAssurance      : dureeAssurance,
                                                dureeDeReference    : dureeDeReference,
                                                dateOfPensionLiquid : dateOfPensionLiquid) else {
            customLog.log(level: .default, "taux De Pension = nil")
            return nil
        }
        
        let majorationEnfant = self.coefficientMajorationEnfant(nbEnfant: nbEnfant)
        
        var pensionBrute = pension(sam              : lastKnownSituation.sam,
                                   tauxDePension    : tauxDePension,
                                   majorationEnfant : majorationEnfant,
                                   dureeAssurance   : dureeAssurance,
                                   dureeDeReference : dureeDeReference)
        if let yearEval = year {
            if yearEval < dateOfPensionLiquid.year {
                customLog.log(level: .error, "pension / yearEval < dateOfPensionLiquid")
            }
            // révaluer le montant de la pension à la date demandée
            pensionBrute = pensionBrute * RegimeGeneral.revaluationCoef(during              : yearEval,
                                                                        dateOfPensionLiquid : dateOfPensionLiquid)
        }
        
        let pensionNette = Fiscal.model.pensionTaxes.netRegimeGeneral(pensionBrute)
        
        return (brut : pensionBrute,
                net  : pensionNette)
    }
    
    /// Calcule les données relatives à la pension de retraite
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - dateOfRetirement: date de cessation d'activité
    ///   - dateOfEndOfUnemployAlloc: date de fin de perception des allocations chomage
    ///   - dateOfPensionLiquid: date de demande de liquidation de la pension
    ///   - lastKnownSituation: dernière situation connue pour le régime général
    ///   - nbEnfant: nb d'enfant aus sens de la retraite (pour les majorations)
    ///   - year: année de calcul
    /// - Returns: Les données relatives à la pension de retraite ou nil
    func pension(birthDate                : Date, // swiftlint:disable:this function_parameter_count
                 dateOfRetirement         : Date,
                 dateOfEndOfUnemployAlloc : Date?,
                 dateOfPensionLiquid      : Date,
                 lastKnownSituation       : RegimeGeneralSituation,
                 nbEnfant                 : Int,
                 during year              : Int? = nil) ->
    (tauxDePension    : Double,
     majorationEnfant : Double,
     dureeDeReference : Int,
     dureeAssurance   : Int,
     pensionBrute     : Double,
     pensionNette     : Double)? {
        // Salaire annuel moyen x Taux de la pension x (Durée d'assurance du salarié au régime général / Durée de référence pour obtenir une pension à taux plein)
        let dureeAssurance = self.dureeAssurance(lastKnownSituation       : lastKnownSituation,
                                                 dateOfRetirement         : dateOfRetirement,
                                                 dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc)
        // customLog.log(level: .info, "duree Assurance = \(dureeAssurance, privacy: .public)")

        guard let dureeDeReference = dureeDeReference(birthYear: birthDate.year) else {
            customLog.log(level: .default, "duree De Reference = nil")
            return nil
        }
        // customLog.log(level: .info, "duree De Reference = \(dureeDeReference, privacy: .public)")

        guard let tauxDePension = tauxDePension(birthDate           : birthDate,
                                                dureeAssurance      : dureeAssurance,
                                                dureeDeReference    : dureeDeReference,
                                                dateOfPensionLiquid : dateOfPensionLiquid) else {
            customLog.log(level: .default, "taux De Pension = nil")
            return nil
        }
        // customLog.log(level: .info, "taux De Pension = \(tauxDePension, privacy: .public)")

        let majorationEnfant = self.coefficientMajorationEnfant(nbEnfant: nbEnfant)
        
        var pensionBrute = pension(sam              : lastKnownSituation.sam,
                                   tauxDePension    : tauxDePension,
                                   majorationEnfant : majorationEnfant,
                                   dureeAssurance   : dureeAssurance,
                                   dureeDeReference : dureeDeReference)
        // customLog.log(level: .info, "pension Brute = \(pensionBrute, privacy: .public)")

        var pensionNette = Fiscal.model.pensionTaxes.netRegimeGeneral(pensionBrute)
        // customLog.log(level: .info, "pension Nette = \(pensionNette, privacy: .public)")

        if let yearEval = year {
            if yearEval < dateOfPensionLiquid.year {
                customLog.log(level: .error, "pension / yearEval < dateOfPensionLiquid")
            }
            // révaluer le montant de la pension à la date demandée
            let coefReavluation = RegimeGeneral.revaluationCoef(during              : yearEval,
                                                                dateOfPensionLiquid : dateOfPensionLiquid)

            pensionBrute *= coefReavluation
            pensionNette *= coefReavluation
        }
        
        return (tauxDePension    : tauxDePension,
                majorationEnfant : majorationEnfant,
                dureeDeReference : dureeDeReference,
                dureeAssurance   : dureeAssurance,
                pensionBrute     : pensionBrute,
                pensionNette     : pensionNette)
    }
}
