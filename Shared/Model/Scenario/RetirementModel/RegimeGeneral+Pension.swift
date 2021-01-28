//
//  RegimeGeneral+Pension.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 27/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.RegimeGeneral")

extension RegimeGeneral {
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
        if let (_, _, _, _, _, pensionBrute, pensionNette) = pension(
            birthDate                : birthDate,
            dateOfRetirement         : dateOfRetirement,
            dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc,
            dateOfPensionLiquid      : dateOfPensionLiquid,
            lastKnownSituation       : lastKnownSituation,
            nbEnfant                 : nbEnfant,
            during                   : year) {
            return (brut : pensionBrute,
                    net  : pensionNette)
        } else {
            return nil
        }
    }
    
    /// Calcule les données relatives à la pension de retraite
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - dateOfRetirement: date de cessation d'activité
    ///   - dateOfEndOfUnemployAlloc: date de la fin d'indemnisation chômage après une période de travail
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
    (tauxDePension            : Double,
     majorationEnfant         : Double,
     dureeDeReference         : Int,
     dureeAssurancePlafonne   : Int,
     dureeAssuranceDeplafonne : Int,
     pensionBrute             : Double,
     pensionNette             : Double)? {
        // Salaire annuel moyen x Taux de la pension x (Durée d'assurance du salarié au régime général / Durée de référence pour obtenir une pension à taux plein)
        guard let dureeAssurance = dureeAssurance(birthDate                : birthDate,
                                                  lastKnownSituation       : lastKnownSituation,
                                                  dateOfRetirement         : dateOfRetirement,
                                                  dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc) else {
            customLog.log(level: .default, "duree d'Assurance = nil")
            return nil
        }
        
        guard let dureeDeReference = dureeDeReference(birthYear: birthDate.year) else {
            customLog.log(level: .default, "duree De Reference = nil")
            return nil
        }
        
        guard let tauxDePension = tauxDePension(birthDate           : birthDate,
                                                dureeAssurance      : dureeAssurance.deplafonne,
                                                dureeDeReference    : dureeDeReference,
                                                dateOfPensionLiquid : dateOfPensionLiquid) else {
            customLog.log(level: .default, "taux De Pension = nil")
            return nil
        }
        
        let majorationEnfant = self.coefficientMajorationEnfant(nbEnfant: nbEnfant)
        
        var pensionBrute = pension(sam              : lastKnownSituation.sam,
                                   tauxDePension    : tauxDePension,
                                   majorationEnfant : majorationEnfant,
                                   dureeAssurance   : dureeAssurance.plafonne,
                                   dureeDeReference : dureeDeReference)
        
        if let yearEval = year {
            if yearEval < dateOfPensionLiquid.year {
                customLog.log(level: .error, "pension:yearEval < dateOfPensionLiquid")
                fatalError("pension:yearEval < dateOfPensionLiquid")
            }
            // révaluer le montant de la pension à la date demandée
            pensionBrute = pensionBrute * RegimeGeneral.revaluationCoef(during              : yearEval,
                                                                        dateOfPensionLiquid : dateOfPensionLiquid)
        }
        
        let pensionNette = RegimeGeneral.fiscalModel.pensionTaxes.netRegimeGeneral(pensionBrute)
        
        return (tauxDePension            : tauxDePension,
                majorationEnfant         : majorationEnfant,
                dureeDeReference         : dureeDeReference,
                dureeAssurancePlafonne   : dureeAssurance.plafonne,
                dureeAssuranceDeplafonne : dureeAssurance.deplafonne,
                pensionBrute             : pensionBrute,
                pensionNette             : pensionNette)
    }
}
