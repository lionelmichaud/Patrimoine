//
//  Retirement.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// https://www.service-public.fr/particuliers/vosdroits/F21552

struct Pension: Codable {
    struct Model: Codable {
        var regimeGeneral: RegimeGeneral
        var regimeAgirc  : RegimeAgirc
    }
    
    static var model: Model =
        Bundle.main.decode(Model.self,
                           from                 : "PensionModel.json",
                           dateDecodingStrategy : .iso8601,
                           keyDecodingStrategy  : .useDefaultKeys)
}

// MARK: - Régime Général

struct RegimeGeneral: Codable {

    // nested types

    struct Slice: Codable {
        var birthYear   : Int
        var ndTrimestre : Int // nb de trimestre pour bénéficer du taux plein
        var ageTauxPlein: Int // age minimum pour bénéficer du taux plein sans avoir le nb de trimestres minimum
    }
    
    struct Model: Codable {
        let dureeDeReferenceGrid : [Slice]
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
    /// - Returns: taux de reversion en tenant compte d'une décote éventuelle
    func tauxDePension(birthDate            : Date,
                       lastKnownSituation   : (atEndOf: Int, nbTrimestreAcquis: Int),
                       dateOfRetirementComp : DateComponents) -> Double? {
        guard let nbTrimestreDecote = nbTrimestreDecote(birthDate            : birthDate,
                                                        lastKnownSituation   : lastKnownSituation,
                                                        dateOfRetirementComp : dateOfRetirementComp) else {
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
    func nbTrimestreDecote(birthDate            : Date,
                           lastKnownSituation   : (atEndOf: Int, nbTrimestreAcquis: Int),
                           dateOfRetirementComp : DateComponents) -> Int? {
        //var dateDuTauxPlein     : Date?
        var dateDuTauxPleinComp : DateComponents
        var duree               : DateComponents
        
        // nb de trimestre manquant pour atteindre l'age à taux plein
        guard let dateDuTauxPlein = ageTauxPlein(birthYear: birthDate.year)?.years.from(birthDate) else {
            return nil
        }
        dateDuTauxPleinComp = Date.calendar.dateComponents([.year, .month, .day],
                                                           from: dateDuTauxPlein)
        duree = Date.calendar.dateComponents([.year, .quarter, .day],
                                             from : dateOfRetirementComp,
                                             to   : dateDuTauxPleinComp)
        let trimestresManquantAgeTauxPlein = max(0, (duree.year! * 4) + duree.quarter!)
        
        // nb de trimestre manquant pour atteindre le nb de trimestres requis
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
        dateDuTauxPleinComp = Date.calendar.dateComponents([.year, .month, .day],
                                                           from: dateTousTrimestre)
        duree               = Date.calendar.dateComponents([.year, .quarter, .day],
                                                           from: dateOfRetirementComp,
                                                           to  : dateDuTauxPleinComp)
        let trimestresManquantNbTrimestreTauxPlein = max(0, (duree.year! * 4) + duree.quarter!)
        
        // retenir le plus favorable des deux et limiter à 20 max
        return min(trimestresManquantNbTrimestreTauxPlein,
                   trimestresManquantAgeTauxPlein,
                   model.maxNbTrimestreDecote)
    }
    
    /// Calcul la durée d'assurance à la date prévisionnelle de demande de liquidation de la pension de retraite
    /// - Returns: durée d'assurance en nombre de trimestres
    func dureeAssurance(lastKnownSituation   : (atEndOf: Int, nbTrimestreAcquis: Int),
                        dateOfRetirementComp : DateComponents) -> Int {
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : lastKnownSituation.atEndOf,
                                         month    : 12,
                                         day      : 31)
        let duree = Date.calendar.dateComponents([.year, .quarter, .day],
                                                           from: dateRefComp,
                                                           to  : dateOfRetirementComp)
        let nbTrimestreFutur = (duree.year! * 4) + duree.quarter!
        return lastKnownSituation.nbTrimestreAcquis + nbTrimestreFutur
    }
    
    /// Trouve  la durée de référence pour obtenir une pension à taux plein
    /// - Parameter birthYear: Année de naissance
    /// - Returns: Durée de référence en nombre de trimestres pour obtenir une pension à taux plein ou nil
    func dureeDeReference(birthYear : Int) -> Int? {
        guard let slice = model.dureeDeReferenceGrid.last(where: { $0.birthYear <= birthYear})  else { return nil }
        return slice.ndTrimestre
    }
    
    /// Trouve l'age minimum pour bénéficer du taux plein sans avoir le nb de trimestres minimum
    /// - Parameter birthYear: Année de naissance
    /// - Returns: Age minimum pour bénéficer du taux plein sans avoir le nb de trimestres minimumou nil
    func ageTauxPlein(birthYear : Int) -> Int? {
        guard let slice = model.dureeDeReferenceGrid.last(where: { $0.birthYear <= birthYear})  else { return nil }
        return slice.ageTauxPlein
    }
    
    /// Calcul de la retraite du salarié du secteur privé
    /// - Parameters:
    ///   - sam: Salaire annuel moyen 
    ///   - tauxDePension: Taux de la pension
    ///   - dureeAssurance: Durée d'assurance du salarié au régime général
    ///   - dureeDeReference: Durée de référence pour obtenir une pension à taux plein
    /// - Returns: Le montant de la pension de retraite
    func pension(sam              : Double,
                 tauxDePension    : Double,
                 dureeAssurance   : Int,
                 dureeDeReference : Int) -> Double {
        // Salaire annuel moyen x Taux de la pension x (Durée d'assurance du salarié au régime général / Durée de référence pour obtenir une pension à taux plein)
        sam * tauxDePension * Double(dureeAssurance / dureeDeReference)
    }
    
    /// Calcul de la retraite du salarié du secteur privé
    /// - Parameters:
    ///   - sam: Salaire annuel moyen:
    /// - Important: Votre salaire annuel moyen est déterminé en calculant la moyenne des salaires bruts ayant donné lieu à cotisation au régime général durant les 25 années les plus avantageuses de votre carrière.
    ///   Tous les éléments de rémunération (salaire de base, primes, heures supplémentaires) et les indemnités journalières de maternité sont pris en compte pour le calcul du salaire annuel moyen.
    ///   Si vous avez travaillé moins de 25 ans, votre salaire annuel moyen est égal à la moyenne de vos salaires bruts durant ces années de travail.
    ///   - tauxDePension: Taux de la pension
    ///   - dureeAssurance: Durée d'assurance du salarié au régime général
    ///   - birthYear: Année de naissance
    /// - Returns: Le montant de la pension de retraite ou nil
    func pension(sam                  : Double,
                 birthDate            : Date,
                 dateOfRetirementComp : DateComponents,
                 lastKnownSituation   : (atEndOf: Int, nbTrimestreAcquis: Int)) -> Double? {
        // Salaire annuel moyen x Taux de la pension x (Durée d'assurance du salarié au régime général / Durée de référence pour obtenir une pension à taux plein)
        guard let tauxDePension = tauxDePension(birthDate: birthDate,
                                                lastKnownSituation: lastKnownSituation,
                                                dateOfRetirementComp: dateOfRetirementComp) else { return nil }
        
        guard let dureeDeReference = dureeDeReference(birthYear: birthDate.year) else { return nil }
        
        let _dureeAssurance = dureeAssurance(lastKnownSituation   : lastKnownSituation,
                                             dateOfRetirementComp : dateOfRetirementComp)
        return pension(sam              : sam,
                       tauxDePension    : tauxDePension,
                       dureeAssurance   : _dureeAssurance,
                       dureeDeReference : dureeDeReference)
    }
}

// MARK: - Régime Complémentaire AGIRC-ARCCO

struct RegimeAgirc: Codable {

}
