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
    
    enum RegimeGeneralError: String, CustomStringConvertible, Error {
        case impossibleToCompute
        case ilegalValue
        case outsiteBounds
        
        var description: String {
            self.rawValue
        }
    }
    
    struct Slice: Codable {
        var birthYear   : Int
        var ndTrimestre : Int // nb de trimestre pour bénéficer du taux plein
        var ageTauxPlein: Int // age minimum pour bénéficer du taux plein sans avoir le nb de trimestres minimum
    }
    
    struct Model: Codable {
        let dureeDeReferenceGrid : [Slice]
        let ageMinimumLegal      : Int    // 62
        let nbOfYearForSAM       : Int    // 25 pour le calcul du SAM
        let maxReversionRate     : Double // 50.0 // % du SAM
        let decoteParTrimestre   : Double // 0.625 // % par trimestre
        let surcoteParTrimestre  : Double // 1.25  // % par trimestre
        let maxNbTrimestreDecote : Int    // 20 // plafond
    }
    
    // MARK: - Static Properties
    
    static var simulationMode : SimulationModeEnum = .deterministic
    
    // MARK: - Static Methods
    
    static var inflation: Double { // %
        Economy.model.inflation.value(withMode: simulationMode)
    }
    
    static var devaluationRate: Double { // %
        SocioEconomy.model.pensionDevaluationRate.value(withMode: simulationMode)
    }
    
    static var nbTrimAdditional: Double { // %
        SocioEconomy.model.nbTrimTauxPlein.value(withMode: simulationMode)
    }
    
    static var yearlyRevaluationRate: Double { // %
        // on ne tient pas compte de l'inflation car les dépenses ne sont pas inflatées
        // donc les revenus non plus s'ils sont supposés progresser comme l'inflation
        // on ne tient donc compte que du delta par rapport à l'inflation
         -devaluationRate
    }
    
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
                    case .outsiteBounds:
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
                    case .outsiteBounds:
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
    
    /// Calcul nombre de trimestres supplémentaires audelà du minimum pour avoir une pension à taux plein
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - dateOfPensionLiquid: date de demande de liquidation de la pension de retraite
    /// - Returns: nombre de trimestres de surcote
    func nbTrimestreSurcote(dureeAssurance   : Int,
                            dureeDeReference : Int) -> Result<Int, RegimeGeneralError> {
        /// le nombre de trimestres supplémentaires entre la date de votre départ en retraite et la date à laquelle vous atteignez l'âge permettant de bénéficier automatiquement du taux plein
        guard dureeAssurance >= dureeDeReference else {
            // customLog.log(level: .info, "Pas de surcote, il doit y avoir décote de la pension régime général")
            return .failure(.outsiteBounds)
        }
        
        let trimestreDeSurcote = dureeAssurance - dureeDeReference
        // customLog.log(level: .info, "trimestre De Surcote = \(trimestreDeSurcote, privacy: .public)")
        
        return .success(trimestreDeSurcote)
    }
    
    /// Calcul nombre de trimestres manquants pour avoir une pension à taux plein
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
                           dateOfPensionLiquid : Date) -> Result<Int, RegimeGeneralError> {
        // customLog.log(level: .info, "Durée de référence = \(dureeDeReference, privacy: .public)")
        
        /// le nombre de trimestres manquants entre la date de votre départ en retraite et la date à laquelle vous atteignez l'âge permettant de bénéficier automatiquement du taux plein
        guard let dateDuTauxPlein = ageTauxPleinLegal(birthYear: birthDate.year)?.years.from(birthDate) else {
            customLog.log(level: .default, "date Du Taux Plein = nil")
            return .failure(.impossibleToCompute)
        }
        // customLog.log(level: .info, "date Du Taux Plein = \(dateDuTauxPlein, privacy: .public)")
        
        guard dureeAssurance < dureeDeReference else {
            // customLog.log(level: .info, "Pas de decote, il doit y avoir surcote de la pension régime général")
            return .failure(.outsiteBounds)
        }
        // customLog.log(level: .info, "date Of Pension Liquid = \(dateOfPensionLiquid, privacy: .public)")

        let duree = Date.calendar.dateComponents([.year, .month, .day],
                                                 from : dateOfPensionLiquid,
                                                 to   : dateDuTauxPlein)
        let (q1, r1) = duree.month!.quotientAndRemainder(dividingBy: 3)
        
        //    Le nombre de trimestres est arrondi au chiffre supérieur
        let trimestresManquantAgeTauxPlein = max(0, (duree.year! * 4) + (r1 > 0 ? q1 + 1 : q1))
        // customLog.log(level: .info, "trimestres Manquant Age Taux Plein = \(trimestresManquantAgeTauxPlein, privacy: .public)")
        
        /// le nombre de trimestres manquant entre le nb de trimestre accumulés à la date de votre départ en retraite et la durée d'assurance retraite ouvrant droit au taux plein
        let trimestresManquantNbTrimestreTauxPlein = max(0, dureeDeReference - dureeAssurance)
        // customLog.log(level: .info, "trimestres Manquant Nb Trimestre Taux Plein = \(trimestresManquantNbTrimestreTauxPlein, privacy: .public)")
        // customLog.log(level: .info, "model.max Nb Trimestre Decote = \(model.maxNbTrimestreDecote, privacy: .public)")
        
        // retenir le plus favorable des deux et limiter à 20 max
        return .success(min(trimestresManquantNbTrimestreTauxPlein,
                            trimestresManquantAgeTauxPlein,
                            model.maxNbTrimestreDecote))
    }
    
    /// Calcul la durée d'assurance à la date prévisionnelle de demande de liquidation de la pension de retraite
    /// - Parameters:
    ///   - lastKnownSituation: dernière situation connue (année, nombre de trimestres de cotisation acquis)
    ///   - dateOfRetirementComp: date de demande de liquidation de la pension de retraite
    /// - Returns: durée d'assurance en nombre de trimestres
    /// - Reference: https://www.service-public.fr/particuliers/vosdroits/F31249
    func dureeAssurance(lastKnownSituation       : RegimeGeneralSituation,
                        dateOfRetirement         : Date,
                        dateOfEndOfUnemployAlloc : Date?) -> Int {
        var dateFinAssurance : Date
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : lastKnownSituation.atEndOf,
                                         month    : 12,
                                         day      : 31,
                                         hour     : 23)
        let dateRef = Date.calendar.date(from: dateRefComp)!
        
        if let dateFinAlloc = dateOfEndOfUnemployAlloc {
            // Période de travail suivi de période d'indeminsation chômage:
            // - Les périodes de chômage indemnisé sont considérées comme des trimestres d'assurance retraite au régime général de la Sécurité sociale dans la limite de 4 trimestres par an.
            // - Les périodes de chômage involontaire non indemnisé sont considérées comme des trimestres d'assurance retraite au régime général de la Sécurité sociale.
            //   La 1re période de chômage non indemnisé, qu'elle soit continue ou non, est prise en compte dans la limite d'un an et demi (6 trimestres).
            dateFinAssurance = (1.years + 6.months).from(dateFinAlloc)!
            
        } else {
            // période de travail non suivi de période d'indemnisation chômage
            dateFinAssurance = dateOfRetirement
        }
        if dateRef >= dateFinAssurance {
            // la date du dernier état est postérieure à la date de fin de cumul des trimestres, ils ne bougeront plus
            return lastKnownSituation.nbTrimestreAcquis
            
        } else {
            // on a encore des trimestres à accumuler
            let duree = Date.calendar.dateComponents([.year, .month, .day],
                                                     from: dateRef,
                                                     to  : dateFinAssurance)
            let (q, _) = duree.month!.quotientAndRemainder(dividingBy: 3)
            //    Le nombre de trimestres est arrondi au chiffre inférieur
            let nbTrimestreFutur = max(0, (duree.year! * 4) + q)
            
            return lastKnownSituation.nbTrimestreAcquis + nbTrimestreFutur
        }
    }
    
    /// Trouve  la durée de référence pour obtenir une pension à taux plein
    /// - Parameter birthYear: Année de naissance
    /// - Returns: Durée de référence en nombre de trimestres pour obtenir une pension à taux plein ou nil
    func dureeDeReference(birthYear : Int) -> Int? {
        guard let slice = model.dureeDeReferenceGrid.last(where: { $0.birthYear <= birthYear}) else {
            customLog.log(level: .default, "dureeDeReference slice = nil")
            return nil
        }
        return slice.ndTrimestre + Int(RegimeGeneral.nbTrimAdditional)
    }
    
    /// Calcul le nb de trimestre manquantà la date prévisionnelle de demande de liquidation de la pension de retraite pour obtenir le taux plein
    /// - Parameters:
    ///   - birthYear: Année de naissance
    ///   - lastKnownSituation: dernière situation connue (année, nombre de trimestres de cotisation acquis)
    ///   - dateOfRetirementComp: date de demande de liquidation de la pension de retraite
    /// - Returns: nb de trimestre manquantà la date prévisionnelle de demande de liquidation de la pension de retraite pour obtenir le taux plein
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
        guard let slice = model.dureeDeReferenceGrid.last(where: { $0.birthYear <= birthYear}) else {
            customLog.log(level: .default, "ageTauxPleinLegal slice = nil")
            return nil
        }
        return slice.ageTauxPlein
    }
    
    /// Calcule la date d'obtention du taux plein légal de retraite
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - lastKnownSituation: dernière situation connue (année, nombre de trimestres de cotisation acquis)
    /// - Returns: date d'obtention du taux plein légal de retraite
    func dateTauxPleinLegal(birthDate            : Date,
                            lastKnownSituation   : (atEndOf: Int, nbTrimestreAcquis: Int)) -> Date? {
        guard let dateDuTauxPlein = ageTauxPleinLegal(birthYear: birthDate.year)?.years.from(birthDate) else {
            customLog.log(level: .default, "date Du Taux Plein = nil")
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
        let trimestreRestant = max(0, dureeDeReference - lastKnownSituation.nbTrimestreAcquis)
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : lastKnownSituation.atEndOf,
                                         month    : 12,
                                         day      : 31)
        let dateRef = Date.calendar.date(from: dateRefComp)!
        guard let dateTousTrimestre = (trimestreRestant * 3).months.from(dateRef) else {
            customLog.log(level: .default, "date Tous Trimestre = nil")
            return nil
        }
        return dateTousTrimestre
    }
    
    func majorationEnfant(nbEnfant: Int) -> Double {
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
        
        let majorationEnfant = self.majorationEnfant(nbEnfant: nbEnfant)
        
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
        
        let pensionNette = Fiscal.model.pensionTaxes.net(pensionBrute)
        
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

        let majorationEnfant = self.majorationEnfant(nbEnfant: nbEnfant)
        
        var pensionBrute = pension(sam              : lastKnownSituation.sam,
                                   tauxDePension    : tauxDePension,
                                   majorationEnfant : majorationEnfant,
                                   dureeAssurance   : dureeAssurance,
                                   dureeDeReference : dureeDeReference)
        // customLog.log(level: .info, "pension Brute = \(pensionBrute, privacy: .public)")

        var pensionNette = Fiscal.model.pensionTaxes.net(pensionBrute)
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
