//
//  RegimeGeneral.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Régime Général

struct RegimeGeneralSituation: Codable {
    var atEndOf           : Int    = Date.now.year
    var nbTrimestreAcquis : Int    = 0
    var sam               : Double = 0
}

struct RegimeGeneral: Codable {
    
    // nested types
    
    struct Slice: Codable {
        var birthYear   : Int
        var ndTrimestre : Int // nb de trimestre pour bénéficer du taux plein
        var ageTauxPlein: Int // age minimum pour bénéficer du taux plein sans avoir le nb de trimestres minimum
    }
    
    struct Model: Codable {
        let dureeDeReferenceGrid : [Slice]
        let ageMinimumLegal      : Int    = 62
        let nbOfYearForSAM       : Int    = 25 // pour le calcul du SAM
        let maxReversionRate     : Double = 50.0 // % du SAM
        let decoteParTrimestre   : Double = 0.625 // % par trimestre
        let maxNbTrimestreDecote : Int    = 20 // plafond
    }
    
    // properties
    
    var model: Model
    
    // methods
    
    /// Calcul du taux de reversion en tenant compte d'une décote éventuelle
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - lastKnownSituation: dernière situation connue (année, nombre de trimestres de cotisation acquis)
    ///   - dateOfRetirementComp: date de demande de liquidation de la pension de retraite
    /// - Returns: taux de reversion en tenant compte d'une décote éventuelle en %
    func tauxDePension(birthDate           : Date,
                       lastKnownSituation  : RegimeGeneralSituation,
                       dateOfPensionLiquid : Date) -> Double? {
        guard let nbTrimestreDecote = nbTrimestreDecote(birthDate           : birthDate,
                                                        lastKnownSituation  : lastKnownSituation,
                                                        dateOfPensionLiquid : dateOfPensionLiquid) else {
                                                            return nil
        }
        return model.maxReversionRate - model.decoteParTrimestre * nbTrimestreDecote.double()
    }
    
    /// Calcul nombre de trimestres manquants pour avoir une pension à taux plein
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - lastKnownSituation: dernière situation connue (année, nombre de trimestres de cotisation acquis)
    ///   - dateOfRetirementComp: date de demande de liquidation de la pension de retraite
    /// - Returns: nombre de trimestres manquants pour avoir une pension à taux plein ou nil
    /// - Important: Pour déterminer le nombre de trimestres manquants, votre caisse de retraite compare :
    /// le nombre de trimestres manquants entre la date de votre départ en retraite et la date à laquelle vous atteignez l'âge permettant de bénéficier automatiquement du taux plein,
    /// et le nombre de trimestres manquant entre la date de votre départ en retraite et la durée d'assurance retraite ouvrant droit au taux plein.
    /// Le nombre de trimestres est arrondi au chiffre supérieur. Le nombre de trimestres manquants retenu est le plus avantageux pour vous.
    /// Le nombre de trimestres est plafonné à 20
    func nbTrimestreDecote(birthDate           : Date,
                           lastKnownSituation  : RegimeGeneralSituation,
                           dateOfPensionLiquid : Date) -> Int? {
        var duree: DateComponents
        
        /// le nombre de trimestres manquants entre la date de votre départ en retraite et la date à laquelle vous atteignez l'âge permettant de bénéficier automatiquement du taux plein
        guard let dateDuTauxPlein = ageTauxPleinLegal(birthYear: birthDate.year)?.years.from(birthDate) else {
            return nil
        }
        duree = Date.calendar.dateComponents([.year, .month, .day],
                                             from : dateOfPensionLiquid,
                                             to   : dateDuTauxPlein)
        let (q1, r1) = duree.month!.quotientAndRemainder(dividingBy: 3)
        //    Le nombre de trimestres est arrondi au chiffre supérieur
        let trimestresManquantAgeTauxPlein = max(0, (duree.year! * 4) + (r1 > 0 ? q1 + 1 : q1))
        
        /// le nombre de trimestres manquant entre la date de votre départ en retraite et la durée d'assurance retraite ouvrant droit au taux plein
        guard let dureeDeReference = dureeDeReference(birthYear: birthDate.year) else {
            return nil
        }
        let trimestreRestant = max(0, dureeDeReference - lastKnownSituation.nbTrimestreAcquis)
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : lastKnownSituation.atEndOf,
                                         month    : 12,
                                         day      : 31,
                                         hour     : 23)
        let dateRef = Date.calendar.date(from: dateRefComp)!
        guard let dateTousTrimestre = (trimestreRestant * 3).months.from(dateRef) else {
            return nil
        }
        duree = Date.calendar.dateComponents([.year, .month, .day],
                                             from: dateOfPensionLiquid,
                                             to  : dateTousTrimestre)
        let (q2, r2) = duree.month!.quotientAndRemainder(dividingBy: 3)
        //    Le nombre de trimestres est arrondi au chiffre supérieur
        let trimestresManquantNbTrimestreTauxPlein = max(0, (duree.year! * 4) + (r2 > 0 ? q2 + 1 : q2))
        
        // retenir le plus favorable des deux et limiter à 20 max
        return min(trimestresManquantNbTrimestreTauxPlein,
                   trimestresManquantAgeTauxPlein,
                   model.maxNbTrimestreDecote)
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
            // - Les périodes de chômage involontaire non indemnisé sont considérées comme des trimestres d'assurance retraite au régime général de la Sécurité sociale. La 1re période de chômage non indemnisé, qu'elle soit continue ou non, est prise en compte dans la limite d'un an et demi (6 trimestres).
            dateFinAssurance = (1.years + 6.months).from(dateFinAlloc)!
            
        } else {
            // période de travail non suivi de période d'indeminsation chômage
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
        guard let slice = model.dureeDeReferenceGrid.last(where: { $0.birthYear <= birthYear}) else { return nil }
        return slice.ndTrimestre
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
        guard let slice = model.dureeDeReferenceGrid.last(where: { $0.birthYear <= birthYear}) else { return nil }
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
            return nil
        }
        let trimestreRestant = max(0, dureeDeReference - lastKnownSituation.nbTrimestreAcquis)
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : lastKnownSituation.atEndOf,
                                         month    : 12,
                                         day      : 31)
        let dateRef = Date.calendar.date(from: dateRefComp)!
        guard let dateTousTrimestre = (trimestreRestant * 3).months.from(dateRef) else {
            return nil
        }
        return dateTousTrimestre
    }
    
    /// Calcul de la retraite brutte du salarié du secteur privé
    /// - Parameters:
    ///   - sam: Salaire annuel moyen
    ///   - tauxDePension: Taux de la pension
    ///   - dureeAssurance: Durée d'assurance du salarié au régime général
    ///   - dureeDeReference: Durée de référence pour obtenir une pension à taux plein
    /// - Returns: Le montant brut de la pension de retraite
    func pension(sam              : Double,
                 tauxDePension    : Double,
                 dureeAssurance   : Int,
                 dureeDeReference : Int) -> Double {
        // Salaire annuel moyen x Taux de la pension x (Durée d'assurance du salarié au régime général / Durée de référence pour obtenir une pension à taux plein)
        sam * tauxDePension/100 * dureeAssurance.double() / dureeDeReference.double()
    }
    
    /// Calcul de la retraite brutte du salarié du secteur privé
    /// - Parameters:
    ///   - sam: Salaire annuel moyen:
    /// - Important: Votre salaire annuel moyen est déterminé en calculant la moyenne des salaires bruts ayant donné lieu à cotisation au régime général durant les 25 années les plus avantageuses de votre carrière.
    ///   Tous les éléments de rémunération (salaire de base, primes, heures supplémentaires) et les indemnités journalières de maternité sont pris en compte pour le calcul du salaire annuel moyen.
    ///   Si vous avez travaillé moins de 25 ans, votre salaire annuel moyen est égal à la moyenne de vos salaires bruts durant ces années de travail.
    ///   - tauxDePension: Taux de la pension
    ///   - dureeAssurance: Durée d'assurance du salarié au régime général
    ///   - birthYear: Année de naissance
    /// - Returns: Le montant brut de la pension de retraite ou nil
    func pension(birthDate                : Date,
                 dateOfRetirement         : Date,
                 dateOfEndOfUnemployAlloc : Date?,
                 dateOfPensionLiquid      : Date,
                 lastKnownSituation       : RegimeGeneralSituation) -> Double? {
        // Salaire annuel moyen x Taux de la pension x (Durée d'assurance du salarié au régime général / Durée de référence pour obtenir une pension à taux plein)
        guard let tauxDePension = tauxDePension(birthDate           : birthDate,
                                                lastKnownSituation  : lastKnownSituation,
                                                dateOfPensionLiquid : dateOfPensionLiquid) else { return nil }
        
        guard let dureeDeReference = dureeDeReference(birthYear: birthDate.year) else { return nil }
        
        let dureeAssurance = self.dureeAssurance(lastKnownSituation       : lastKnownSituation,
                                                 dateOfRetirement         : dateOfRetirement,
                                                 dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc)
        return pension(sam              : lastKnownSituation.sam,
                       tauxDePension    : tauxDePension,
                       dureeAssurance   : dureeAssurance,
                       dureeDeReference : dureeDeReference)
    }
    
    /// version détaillée
    func pensionWithDetail(birthDate                : Date,
                           dateOfRetirement         : Date,
                           dateOfEndOfUnemployAlloc : Date?,
                           dateOfPensionLiquid      : Date,
                           lastKnownSituation       : RegimeGeneralSituation) ->
        (tauxDePension   : Double,
        dureeDeReference : Int,
        dureeAssurance   : Int,
        pensionBrute     : Double,
        pensionNette     : Double)? {
            // Salaire annuel moyen x Taux de la pension x (Durée d'assurance du salarié au régime général / Durée de référence pour obtenir une pension à taux plein)
            guard let tauxDePension = tauxDePension(birthDate           : birthDate,
                                                    lastKnownSituation  : lastKnownSituation,
                                                    dateOfPensionLiquid : dateOfPensionLiquid) else { return nil }
            
            guard let dureeDeReference = dureeDeReference(birthYear: birthDate.year) else { return nil }
            
            let dureeAssurance = self.dureeAssurance(lastKnownSituation       : lastKnownSituation,
                                                     dateOfRetirement         : dateOfRetirement,
                                                     dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc)
            let pensionBrute = pension(sam              : lastKnownSituation.sam,
                                       tauxDePension    : tauxDePension,
                                       dureeAssurance   : dureeAssurance,
                                       dureeDeReference : dureeDeReference)
            let pensionNette = Fiscal.model.pensionTaxes.net(pensionBrute)
            
            return (tauxDePension    : tauxDePension,
                    dureeDeReference : dureeDeReference,
                    dureeAssurance   : dureeAssurance,
                    pensionBrute     : pensionBrute,
                    pensionNette     : pensionNette)
    }
}

