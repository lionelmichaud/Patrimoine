//
//  RegimeAgirc+Pension.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 27/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.RegimeAgirc.pension")

extension RegimeAgirc {
    /// Calcul de la pension Agirc
    /// - Parameters:
    ///   - lastAgircKnownSituation: nière situation connue pour le régime AGIRC
    ///   - birthDate: date de naissance
    ///   - lastKnownSituation: dernière situation connue pour le régime général
    ///   - dateOfRetirement: date de cessation d'activité
    ///   - dateOfEndOfUnemployAlloc: date de fin de perception des allocations chomage
    ///   - dateOfPensionLiquid: date de demande de liquidation de la pension
    ///   - nbEnfantNe: nombre d'enfants nés
    ///   - nbEnfantACharge: nombre d'enfants à charge au début de l'année
    ///   - year: année de calcul. si nil alors calcul réalisé  la date de liquidation de la pension
    /// - Returns: pension Agirc
    /// - Waring:
    ///   - avant l'age du taux plein l'abattement est définitif
    func pension(lastAgircKnownSituation  : RegimeAgircSituation, // swiftlint:disable:this function_parameter_count
                 birthDate                : Date,
                 lastKnownSituation       : RegimeGeneralSituation,
                 dateOfRetirement         : Date,
                 dateOfEndOfUnemployAlloc : Date?,
                 dateOfPensionLiquid      : Date,
                 nbEnfantNe               : Int,
                 nbEnfantACharge          : Int,
                 during year              : Int? = nil) ->
    (coefMinoration       : Double,
     majorationPourEnfant : Double,
     projectedNbOfPoints  : Int,
     pensionBrute         : Double,
     pensionNette         : Double)? {
        
        // Vérifier que l'on a atteint l'age minimum de liquidation de la pension Agirc
        guard let dateOfAgeMinimumAgirc = dateAgeMinimumAgirc(birthDate:birthDate) else {
            customLog.log(level: .default,
                          "pension:dateOfAgeMinimumAgirc = nil")
            return nil
        }
        //customLog.log(level: .info, "date Of Age Minimum Agirc = \(dateOfAgeMinimumAgirc, privacy: .public)")
        
        guard dateOfPensionLiquid >= dateOfAgeMinimumAgirc else {
            // pas de pension avant cet age minimum
            return (coefMinoration       : 0,
                    majorationPourEnfant : 0,
                    projectedNbOfPoints  : 0,
                    pensionBrute         : 0,
                    pensionNette         : 0)
        }
        //customLog.log(level: .info, "date Of Pension Liquid = \(dateOfPensionLiquid, privacy: .public)")
        
        // Projection du nb de points au moment de la demande de liquidation de la pension
        guard let projectedNumberOfPoints = self.projectedNumberOfPoints(
                lastAgircKnownSituation : lastAgircKnownSituation,
                dateOfRetirement        : dateOfRetirement,
                dateOfEndOfUnemployAlloc: dateOfEndOfUnemployAlloc) else {
            customLog.log(level: .default, "pension:projectedNumberOfPoints = nil")
            return nil
        }
        //customLog.log(level: .info, "projected Number Of Points = \(projectedNumberOfPoints, privacy: .public)")
        
        // Calcul du coefficient de minoration / majoration
        guard let coefMinoration = coefMinorationMajoration(
                birthDate                : birthDate,
                lastKnownSituation       : lastKnownSituation,
                dateOfRetirement         : dateOfRetirement,
                dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc,
                dateOfPensionLiquid      : dateOfPensionLiquid,
                during                   : year ?? dateOfPensionLiquid.year) else {
            customLog.log(level: .default, "pension:coefMinoration = nil")
            return nil
        }
        
        let pensionAvantMajorationPourEnfant = projectedNumberOfPoints.double() * valeurDuPoint * coefMinoration
        
        // Calcul de la majoration pour enfant nés
        let majorPourEnfantNe = majorationPourEnfantNe(
            pensionBrute : pensionAvantMajorationPourEnfant,
            nbEnfantNe   : nbEnfantNe)
        
        // Calcul de la majoration pour enfant à charge (non plafonnée)
        let coefMajorationEnfantACharge = coefMajorationPourEnfantACharge(
            nbEnfantACharge : nbEnfantACharge)
        let majorPourEnfantACharge =
            pensionAvantMajorationPourEnfant * (coefMajorationEnfantACharge - 1.0)
        
        // on retient la plus favorable des deux majorations
        let majorationPourEnfant = max(majorPourEnfantNe, majorPourEnfantACharge)
        
        // Pension = Nombre de points X Valeurs du point X Coefficient de minoration X Coefficient de majoration enfants
        var pensionBrute = pensionAvantMajorationPourEnfant + majorationPourEnfant
        //customLog.log(level: .info, "pension Brute = \(pensionBrute, privacy: .public)")
        
        if let yearEval = year {
            if yearEval < dateOfPensionLiquid.year {
                customLog.log(level: .error,
                              "pension:yearEval < dateOfPensionLiquid")
                fatalError("pension:yearEval < dateOfPensionLiquid")
            }
            // révaluer le montant de la pension à la date demandée
            let coefReavluation = RegimeAgirc.revaluationCoef(
                during              : yearEval,
                dateOfPensionLiquid : dateOfPensionLiquid)
            
            pensionBrute *= coefReavluation
        }
        
        let pensionNette = RegimeAgirc.fiscalModel.pensionTaxes.netRegimeAgirc(pensionBrute)
        //customLog.log(level: .info, "pension Nette = \(pensionNette, privacy: .public)")
        
        return (coefMinoration       : coefMinoration,
                majorationPourEnfant : majorationPourEnfant,
                projectedNbOfPoints  : projectedNumberOfPoints,
                pensionBrute         : pensionBrute,
                pensionNette         : pensionNette)
    }
}
