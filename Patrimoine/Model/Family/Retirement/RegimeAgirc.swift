//
//  RegimeAgirc.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Régime Complémentaire AGIRC-ARCCO

struct RegimeAgirc: Codable {
    
    // nested types
    
    struct SliceAvantAgeLegal: Codable {
        var ndTrimAvantAgeLegal : Int
        var coef                : Double
    }
    
    struct SliceApresAgeLegal: Codable {
        var nbTrimManquant     : Int
        var ndTrimPostAgeLegal : Int
        var coef               : Double
    }
    
    struct Model: Codable {
        let gridAvant62 : [SliceAvantAgeLegal]
        let gridApres62 : [SliceApresAgeLegal]
        let valeurDuPoint : Double = 1.2714
        let ageMinimum    : Int    = 57
    }
    
    // properties
    
    var model: Model
    
    // methods
    
    func dateAgeMinimumAgirc(birthDate: Date) -> Date? {
        model.ageMinimum.years.from(birthDate)
    }
    
    func coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: Int) -> Double? {
        guard let slice = model.gridAvant62.last(where: { $0.ndTrimAvantAgeLegal <= ndTrimAvantAgeLegal})  else { return nil }

        return slice.coef
    }
    
    func coefDeMinorationApresAgeLegal(nbTrimManquantPourTauxPlein : Int,
                                       nbTrimPostAgeLegalMin       : Int) -> Double {
        return 1.0
    }
    
    func projectedNumberOfPoints(lastAgircKnownSituation : (atEndOf: Int, nbPoints: Int, pointsParAn: Int),
                                 dateOfPensionLiquidComp : DateComponents) -> Int? {
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : lastAgircKnownSituation.atEndOf,
                                         month    : 12,
                                         day      : 31)
        let dureeRestant = Date.calendar.dateComponents([.year, .month, .day],
                                                        from: dateRefComp,
                                                        to  : dateOfPensionLiquidComp)
        guard let anneesPlaines = dureeRestant.year,
            let mois = dureeRestant.month else { return nil }
        
        let nbAnneeRestant: Double = anneesPlaines.double() + mois.double() / 12
        let nbPointsFutur : Double = lastAgircKnownSituation.pointsParAn.double() * nbAnneeRestant
        return lastAgircKnownSituation.nbPoints + Int(nbPointsFutur)
    }
    
    func pension(lastAgircKnownSituation : (atEndOf: Int, nbPoints: Int, pointsParAn: Int),
                 birthDate               : Date,
                 lastKnownSituation      : (atEndOf: Int, nbTrimestreAcquis: Int),
                 dateOfPensionLiquidComp : DateComponents,
                 ageOfPensionLiquidComp  : DateComponents) -> (coefMinoration: Double, projectedNbOfPoints: Int, pensionBrute: Double, pensionNette: Double)? {
        
        var coefMinoration: Double
        
        guard let dateOfPensionLiquid = Date.calendar.date(from: dateOfPensionLiquidComp) else {
            return nil
        }
        guard let dateOfAgeMinimumAgirc = dateAgeMinimumAgirc(birthDate:birthDate) else {
            return nil
        }
        guard let dateOfAgeMinimumLegal = Pension.model.regimeGeneral.dateAgeMinimumLegal(birthDate:birthDate) else {
            return nil
        }
        guard dateOfPensionLiquid >= dateOfAgeMinimumAgirc else {
            // pas de pension avant cet age minimum
            return (coefMinoration      : 0.0,
                    projectedNbOfPoints : 0,
                    pensionBrute        : 0.0,
                    pensionNette        : 0.0)
        }
        
        if dateOfPensionLiquid >= dateOfAgeMinimumLegal {
            // nombre de trimestre manquant au moment de la liquidation de la pensionpour pour obtenir le taux plein
            guard let nbTrimManquantPourTauxPlein =
                Pension.model.regimeGeneral.nbTrimManquantPourTauxPlein(birthYear               : birthDate.year,
                                                                        lastKnownSituation      : lastKnownSituation,
                                                                        dateOfPensionLiquidComp : dateOfPensionLiquidComp) else {
                                                                            return nil
            }
            // nombre de trimestre au-delà de l'age minimum légal de départ à la retraite au moment de la liquidation de la pension
            guard let yearOfPensionLiquid = ageOfPensionLiquidComp.year,
                let monthOfPensionLiquid = ageOfPensionLiquidComp.month else {
                    return nil
            }
            let nbTrimPostAgeLegalMin =
                (yearOfPensionLiquid - Pension.model.regimeGeneral.model.ageMinimumLegal) * 4
                    + monthOfPensionLiquid / 3
            // coefficient de minoration
            coefMinoration = coefDeMinorationApresAgeLegal (nbTrimManquantPourTauxPlein: nbTrimManquantPourTauxPlein,
                                                            nbTrimPostAgeLegalMin: nbTrimPostAgeLegalMin)
            
            // autre barême
        } else {
            // nombre de trimestre au-delà de l'age minimum AGIRC de demande de liquidation de la pension complémentaire
            guard let yearOfPensionLiquid = ageOfPensionLiquidComp.year,
                let monthOfPensionLiquid = ageOfPensionLiquidComp.month else {
                    return nil
            }
            let ndTrimAvantAgeLegal =
                Pension.model.regimeGeneral.model.ageMinimumLegal * 4 - (yearOfPensionLiquid * 4 + monthOfPensionLiquid / 3)
            
            // coefficient de minoration
            guard let coef = coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: ndTrimAvantAgeLegal) else {
                return nil
            }
            coefMinoration = coef
        }
        
        // projection du nb de points au moment de la demande de liquidation de la pension
        guard let projectedNumberOfPoints = self.projectedNumberOfPoints(lastAgircKnownSituation: lastAgircKnownSituation,
                                                                         dateOfPensionLiquidComp: dateOfPensionLiquidComp) else {
            return nil
        }
        
        // Pension = Nombre de points X Valeurs du point X Coefficient de minoration
        let pensionBrute = projectedNumberOfPoints.double() * model.valeurDuPoint * coefMinoration
        let pensionNette = Fiscal.model.socialTaxesOnPension.net(pensionBrute)
        
        return (coefMinoration      : coefMinoration,
                projectedNbOfPoints : projectedNumberOfPoints,
                pensionBrute        : pensionBrute,
                pensionNette        : pensionNette)
    }
}
