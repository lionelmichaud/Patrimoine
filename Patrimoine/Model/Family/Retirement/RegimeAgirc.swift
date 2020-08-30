//
//  RegimeAgirc.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

fileprivate let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.RegimeAgirc")

// MARK: - Régime Complémentaire AGIRC-ARCCO

struct RegimeAgircSituation: Codable {
    var atEndOf     : Int = Date.now.year
    var nbPoints    : Int = 0
    var pointsParAn : Int = 0
}

struct RegimeAgirc: Codable {
    
    // MARK: - Nested types
    
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
        let gridAvant62   : [SliceAvantAgeLegal]
        let gridApres62   : [SliceApresAgeLegal]
        let valeurDuPoint : Double // 1.2714
        let ageMinimum    : Int    // 57
    }
    
    // MARK: - Properties
    
    var model: Model
    
    // MARK: - Methods
    
    /// Age minimum pour demander la liquidation de pension Agirc
    /// - Parameter birthDate: date de naissance
    /// - Returns: Age minimum pour demander la liquidation de pension Agirc
    func dateAgeMinimumAgirc(birthDate: Date) -> Date? {
        model.ageMinimum.years.from(birthDate)
    }
    
    /// Calcul du coefficient de minoration de la pension Agirc si la date de liquidation est avant l'age légal (62 ans)
    /// - Parameter ndTrimAvantAgeLegal: nb de trimestres entre la date de liquidation Agirc et la date de l'age légal
    /// - Returns: coefficient de minoration de la pension
    func coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: Int) -> Double? {
        guard let slice = model.gridAvant62.last(where: { $0.ndTrimAvantAgeLegal <= ndTrimAvantAgeLegal})  else {
            customLog.log(level: .default, "coefDeMinorationAvantAgeLegal slice = nil")
            return nil
        }
        
        return slice.coef
    }
    
    /// Calcul du coefficient de minoration de la pension Agirc si la date de liquidation est après l'age légal (62 ans)
    /// - Parameters:
    ///   - nbTrimManquantPourTauxPlein: nb de Trimestres Manquants Pour obtenir le Taux Plein
    ///   - nbTrimPostAgeLegalMin: nb de trimestres entre la date de l'age légal et la date de liquidation Agirc
    /// - Returns: coefficient de minoration de la pension
    func coefDeMinorationApresAgeLegal(nbTrimManquantPourTauxPlein : Int,
                                       nbTrimPostAgeLegalMin       : Int) -> Double? {
        // coefficient de réduction basé sur le nb de trimestre manquants pour obtenir le taux plein
        guard let slice1 = model.gridApres62.last(where: { $0.nbTrimManquant <= nbTrimManquantPourTauxPlein})  else {
            customLog.log(level: .default, "coefDeMinorationApresAgeLegal slice1 = nil")
            return nil
        }
        let coef1 = slice1.coef
        
        // coefficient basé sur l'age
        guard let slice2 = model.gridApres62.last(where: { $0.ndTrimPostAgeLegal >= nbTrimPostAgeLegalMin})  else {
            customLog.log(level: .default, "coefDeMinorationApresAgeLegal slice2 = nil")
            return nil
        }
        let coef2 = slice2.coef
        
        // le coefficient applicable est déterminé par génération en fonction de l'âge atteint ou de la durée d'assurance, en retenant la solution la plus avantageuse pour l'intéressé
        return max(coef1, coef2)
    }
    
    /// Projection du nombre de points Agirc sur la base du dernier relevé de points et de la prévision de carrière future
    /// - Parameters:
    ///   - lastAgircKnownSituation: dernier relevé de situation Agirc
    ///   - dateOfPensionLiquid: date de liquidation de la pension agirc
    /// - Returns: nombre de points Agirc projeté à la liquidation de la pension
    func projectedNumberOfPoints(lastAgircKnownSituation  : RegimeAgircSituation,
                                 dateOfRetirement         : Date,
                                 dateOfEndOfUnemployAlloc : Date?) -> Int? {
        var nbPointsFuturActivite : Double
        var nbPointsFuturChomage  : Double
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : lastAgircKnownSituation.atEndOf,
                                         month    : 12,
                                         day      : 31,
                                         hour     : 23)
        let dateRef = Date.calendar.date(from: dateRefComp)!
        
        // nombre de points futurs dûs au titre de la future carrière de salarié
        if dateRef >= dateOfRetirement {
            // la date du dernier état est postérieure à la date de fin d'activité salarié
            nbPointsFuturActivite = 0.0
            
        } else {
            // période restant à cotiser à l'Agirc pendant la carrière de salarié
            let dureeRestant = Date.calendar.dateComponents([.year, .month, .day],
                                                            from: dateRef,
                                                            to  : dateOfRetirement)
            guard let anneesPleines = dureeRestant.year,
                  let moisPleins = dureeRestant.month else {
                customLog.log(level: .default, "anneesPleines OU moisPleins = nil")
                return nil
            }
            
            let nbAnneeRestant: Double = anneesPleines.double() + moisPleins.double() / 12
            nbPointsFuturActivite = lastAgircKnownSituation.pointsParAn.double() * nbAnneeRestant
        }
        
        // nombre de points futurs dûs au titre de la période de chomage indemnisé
        // https://www.previssima.fr/question-pratique/mes-periodes-de-chomage-comptent-elles-pour-ma-retraite-complementaire.html
        guard dateOfEndOfUnemployAlloc != nil else {
            // pas de période de chomage indemnisé donnant droit à des points supplémentaires
            return lastAgircKnownSituation.nbPoints + Int(nbPointsFuturActivite)
        }
        
        guard dateRef < dateOfEndOfUnemployAlloc! else {
            // la date du dernier état est postérieure à la date de fin d'indemnisation chomage, le nb de point ne bougera plus
            return lastAgircKnownSituation.nbPoints + Int(nbPointsFuturActivite)
        }
        // on a encore des trimestres à accumuler
        // période restant à cotiser à l'Agirc pendant la période de chomage indemnisée
        let dureeRestant = Date.calendar.dateComponents([.year, .month, .day],
                                                        from: dateRef > dateOfRetirement ? dateRef : dateOfRetirement,
                                                        to  : dateOfEndOfUnemployAlloc!)
        guard let anneesPleines = dureeRestant.year,
              let moisPleins = dureeRestant.month else {
            customLog.log(level: .default, "anneesPleines OU moisPleins = nil")
            return nil
        }
        let nbAnneeRestant: Double = anneesPleines.double() + moisPleins.double() / 12
        // le nb de point acqui par an au chomage semble être le même qu'en période d'activité
        // TODO: - pas tout à fait car il est basé sur le SJR qui peut être inférieur au salaire journalier réel: passer SJR en paramètre
        nbPointsFuturChomage = lastAgircKnownSituation.pointsParAn.double() * nbAnneeRestant
        
        return lastAgircKnownSituation.nbPoints + Int(nbPointsFuturActivite + nbPointsFuturChomage)
    }
    
    /// Calcul de la pension Agirc
    /// - Parameters:
    ///   - lastAgircKnownSituation:
    ///   - birthDate:
    ///   - lastKnownSituation:
    ///   - dateOfRetirement:
    ///   - dateOfEndOfUnemployAlloc:
    ///   - dateOfPensionLiquid:
    ///   - ageOfPensionLiquidComp:
    /// - Returns: pension Agirc
    func pension(lastAgircKnownSituation  : RegimeAgircSituation,
                 birthDate                : Date,
                 lastKnownSituation       : RegimeGeneralSituation,
                 dateOfRetirement         : Date,
                 dateOfEndOfUnemployAlloc : Date?,
                 dateOfPensionLiquid      : Date,
                 ageOfPensionLiquidComp   : DateComponents) ->
    (coefMinoration     : Double,
     projectedNbOfPoints : Int,
     pensionBrute        : Double,
     pensionNette        : Double)? {
        
        var coefMinoration: Double
        
        guard let dateOfAgeMinimumAgirc = dateAgeMinimumAgirc(birthDate:birthDate) else {
            customLog.log(level: .default, "dateOfAgeMinimumAgirc = nil")
            return nil
        }
        customLog.log(level: .info, "date Of Age Minimum Agirc = \(dateOfAgeMinimumAgirc, privacy: .public)")
        
        guard let dateOfAgeMinimumLegal = Pension.model.regimeGeneral.dateAgeMinimumLegal(birthDate:birthDate) else {
            customLog.log(level: .default, "dateOfAgeMinimumLegal = nil")
            return nil
        }
        customLog.log(level: .info, "date Of Age Minimum Legal = \(dateOfAgeMinimumLegal, privacy: .public)")
        
        guard dateOfPensionLiquid >= dateOfAgeMinimumAgirc else {
            // pas de pension avant cet age minimum
            return (coefMinoration      : 0.0,
                    projectedNbOfPoints : 0,
                    pensionBrute        : 0.0,
                    pensionNette        : 0.0)
        }
        customLog.log(level: .info, "date Of Pension Liquid = \(dateOfPensionLiquid, privacy: .public)")

        if dateOfPensionLiquid >= dateOfAgeMinimumLegal {
            // nombre de trimestre manquant au moment de la liquidation de la pension pour pour obtenir le taux plein
            guard var nbTrimManquantPourTauxPlein =
                    Pension.model.regimeGeneral.nbTrimManquantPourTauxPlein(birthYear                : birthDate.year,
                                                                            lastKnownSituation       : lastKnownSituation,
                                                                            dateOfRetirement         : dateOfRetirement,
                                                                            dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc) else {
                customLog.log(level: .default, "nbTrimManquantPourTauxPlein = nil")
                return nil
            }
            nbTrimManquantPourTauxPlein = max(nbTrimManquantPourTauxPlein, 0)
            customLog.log(level: .info, "nb Trim Manquant Pour Taux Plein = \(nbTrimManquantPourTauxPlein, privacy: .public)")
            
            // nombre de trimestre au-delà de l'age minimum légal de départ à la retraite au moment de la liquidation de la pension
            guard let yearOfPensionLiquid = ageOfPensionLiquidComp.year,
                  let monthOfPensionLiquid = ageOfPensionLiquidComp.month else {
                customLog.log(level: .default, "yearOfPensionLiquid OU monthOfPensionLiquid = nil")
                return nil
            }
            let nbTrimPostAgeLegalMin = (yearOfPensionLiquid - Pension.model.regimeGeneral.model.ageMinimumLegal) * 4
                                                + monthOfPensionLiquid / 3
            if nbTrimPostAgeLegalMin < 0 {
                customLog.log(level: .error, "nb Trim Post Age Legal Min < 0 = \(nbTrimPostAgeLegalMin, privacy: .public)")
                fatalError("Agirc pension nbTrimPostAgeLegalMin < 0 = \(nbTrimPostAgeLegalMin)")
            }
            customLog.log(level: .info, "nb Trim Post Age Legal Min = \(nbTrimPostAgeLegalMin, privacy: .public)")
            
            // coefficient de minoration
            guard let coef = coefDeMinorationApresAgeLegal (nbTrimManquantPourTauxPlein : nbTrimManquantPourTauxPlein,
                                                            nbTrimPostAgeLegalMin       : nbTrimPostAgeLegalMin) else {
                customLog.log(level: .default, "pension coef = nil")
                return nil
            }
            coefMinoration = coef

            // autre barême
        } else {
            // nombre de trimestre au-delà de l'age minimum AGIRC de demande de liquidation de la pension complémentaire
            guard let yearOfPensionLiquid = ageOfPensionLiquidComp.year,
                  let monthOfPensionLiquid = ageOfPensionLiquidComp.month else {
                customLog.log(level: .default, "yearOfPensionLiquid OU monthOfPensionLiquid = nil")
                return nil
            }
            let ndTrimAvantAgeLegal =
                Pension.model.regimeGeneral.model.ageMinimumLegal * 4 - (yearOfPensionLiquid * 4 + monthOfPensionLiquid / 3)
            
            // coefficient de minoration
            guard let coef = coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: ndTrimAvantAgeLegal) else {
                customLog.log(level: .default, "pension coef = nil")
                return nil
            }
            coefMinoration = coef
        }
        customLog.log(level: .info, "coef Minoration= \(coefMinoration, privacy: .public)")

        // projection du nb de points au moment de la demande de liquidation de la pension
        guard let projectedNumberOfPoints = self.projectedNumberOfPoints(lastAgircKnownSituation : lastAgircKnownSituation,
                                                                         dateOfRetirement        : dateOfRetirement,
                                                                         dateOfEndOfUnemployAlloc: dateOfEndOfUnemployAlloc) else {
            customLog.log(level: .default, "projectedNumberOfPoints = nil")
            return nil
        }
        customLog.log(level: .info, "projected Number Of Points = \(projectedNumberOfPoints, privacy: .public)")

        // Pension = Nombre de points X Valeurs du point X Coefficient de minoration
        let pensionBrute = projectedNumberOfPoints.double() * model.valeurDuPoint * coefMinoration
        customLog.log(level: .info, "pension Brute = \(projectedNumberOfPoints, privacy: .public)")

        let pensionNette = Fiscal.model.pensionTaxes.net(pensionBrute)
        customLog.log(level: .info, "pension Nette = \(pensionNette, privacy: .public)")

        return (coefMinoration      : coefMinoration,
                projectedNbOfPoints : projectedNumberOfPoints,
                pensionBrute        : pensionBrute,
                pensionNette        : pensionNette)
    }
}
