//
//  RegimeAgirc.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.RegimeAgirc")

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
    
    struct MajorationPourEnfant: Codable {
        var majorPourEnfantsNes   : Double // % [0, 100]
        var nbEnafntNesMin        : Int
        var majorParEnfantACharge : Double // % [0, 100]
        var plafondMajoEnfantNe   : Double // €
    }
    
    struct Model: BundleCodable, Versionable {
        static var defaultFileName : String = "RegimeAgircModel.json"

        var version              : Version
        let gridAvant62          : [SliceAvantAgeLegal]
        let gridApres62          : [SliceApresAgeLegal]
        let valeurDuPoint        : Double // 1.2714
        let ageMinimum           : Int    // 57
        let majorationPourEnfant : MajorationPourEnfant
    }
    
    // MARK: - Static Properties
    
    static var simulationMode : SimulationModeEnum = .deterministic
    // dependencies to other Models
    static var socioEconomyModel : SocioEconomy.Model = SocioEconomy.model
    static var fiscalModel       : Fiscal.Model       = Fiscal.model

    // MARK: - Static Methods
    
    static var devaluationRate: Double { // %
        socioEconomyModel.pensionDevaluationRate.value(withMode: simulationMode)
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
    
    private var model: Model
    
    var valeurDuPoint : Double {
        model.valeurDuPoint
    }
    
    var ageMinimum    : Int {
        model.ageMinimum
    }
    
    // MARK: - Initializer
    
    init(model: Model) {
        self.model = model
    }
    
    // MARK: - Methods
    
    /// Encode l'objet dans un fichier stocké dans le Bundle de contenant la définition de la classe aClass
    func saveToBundle(for aClass           : AnyClass,
                      to file              : String?,
                      dateEncodingStrategy : JSONEncoder.DateEncodingStrategy,
                      keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy) {
        model.saveToBundle(for                  : aClass,
                           to                   : file,
                           dateEncodingStrategy : dateEncodingStrategy,
                           keyEncodingStrategy  : keyEncodingStrategy)
    }
    
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
        model.gridAvant62.last(\.coef, where: \.ndTrimAvantAgeLegal, <=, ndTrimAvantAgeLegal)
    }
    
    /// Calcul du coefficient de minoration de la pension Agirc si la date de liquidation est après l'age légal (62 ans)
    /// - Parameters:
    ///   - nbTrimManquantPourTauxPlein: nb de Trimestres Manquants avant l'âge légale du Taux Plein (67)
    ///   - nbTrimPostAgeLegalMin: nb de trimestres entre la date de l'age minimum légal (62) et la date de demande de liquidation Agirc
    /// - Returns: coefficient de minoration de la pension
    func coefDeMinorationApresAgeLegal(nbTrimManquantPourTauxPlein : Int,
                                       nbTrimPostAgeLegalMin       : Int) -> Double? {
        // coefficient de réduction basé sur le nb de trimestre manquants pour obtenir le taux plein
        guard let coef1 = model.gridApres62.last(\.coef, where: \.nbTrimManquant, <=, nbTrimManquantPourTauxPlein)  else {
            customLog.log(level: .default, "coefDeMinorationApresAgeLegal coef1 = nil")
            return nil
        }
        
        // coefficient basé sur l'age
        guard let coef2 = model.gridApres62.last(\.coef, where: \.ndTrimPostAgeLegal, >=, nbTrimPostAgeLegalMin)  else {
            customLog.log(level: .default, "coefDeMinorationApresAgeLegal coef2 = nil")
            return nil
        }
        
        // le coefficient applicable est déterminé par génération en fonction de l'âge atteint
        // ou de la durée d'assurance, en retenant la solution la plus avantageuse pour l'intéressé
        return max(coef1, coef2)
    }
    
    /// Projection du nombre de points Agirc sur la base du dernier relevé de points et de la prévision de carrière future
    /// - Parameters:
    ///   - lastAgircKnownSituation: dernier relevé de situation Agirc
    ///   - dateOfRetirement: date de cessation d'activité
    ///   - dateOfEndOfUnemployAlloc: date de la fin d'indemnisation chômage après une période de travail
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
    
    fileprivate func coefMinorationMajorationAvantTauxPlein(_ dateOfPensionLiquid: Date,
                                                            _ dateAgeMinimumLegal: Date,
                                                            _ nbTrimAudelaDuTauxPlein: Int) -> Double? {
        // pension liquidable mais abattement définitif selon table
        // Délais restant à courir avant l'âge légal minimal de départ
        let delai = Date.calendar.dateComponents([.year, .month, .day],
                                                 from : dateOfPensionLiquid,
                                                 to   : dateAgeMinimumLegal)
        let (q1, r1) = delai.month!.quotientAndRemainder(dividingBy: 3)
        //    Le nombre de trimestres manquant est arrondi au chiffre supérieur
        let ndTrimAvantAgeLegal   = (delai.year! * 4) + (r1 > 0 ? q1 + 1 : q1)
        //    Le nombre de trimestres excédentaire est arrondi au chiffre inférieur
        let nbTrimPostAgeLegalMin = -(delai.year! * 4 + q1)
        
        let ecartTrimAgircLegal = (Retirement.model.regimeGeneral.ageMinimumLegal - model.ageMinimum) * 4
        //let eacrtTrimLegalTauxPlein =
        
        switch ndTrimAvantAgeLegal {
            case ...0:
                // Liquidation de la pension AVANT l'obtention du taux plein
                // et APRES l'age l'age légal de liquidation de la pension du régime général
                // coefficient de minoration
                // (a) Nombre de trimestre manquant au moment de la liquidation de la pension pour pour obtenir le taux plein
                let nbTrimManquantPourTauxPlein = -nbTrimAudelaDuTauxPlein
                // (b) Nombre de trimestre manquant au moment de la liquidation de la pension pour atteindre l'age du taux plein légal
                //   nbTrimPostAgeLegalMin
                // (c) prendre le cas le plus favorable
                // coefficient de minoration
                guard let coef = coefDeMinorationApresAgeLegal(
                        nbTrimManquantPourTauxPlein : nbTrimManquantPourTauxPlein,
                        nbTrimPostAgeLegalMin       : nbTrimPostAgeLegalMin) else {
                    customLog.log(level: .default, "pension coef = nil")
                    return nil
                }
                return coef
                
            case 1...ecartTrimAgircLegal:
                // Liquidation de la pension AVANT l'obtention du taux plein
                // et AVANT l'age l'age légal de liquidation de la pension du régime général
                // et APRES l'age minimum de liquidation de la pension AGIRC
                // coefficient de minoration
                guard let coef = coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: ndTrimAvantAgeLegal) else {
                    customLog.log(level: .default, "pension coef = nil")
                    return nil
                }
                return coef
                
            case (ecartTrimAgircLegal+1)...:
                // Liquidation de la pension AVANT l'obtention du taux plein
                // et AVANT l'age l'age légal de liquidation de la pension du régime général
                // et AVANT l'age minimum de liquidation de la pension AGIRC
                // pas de pension AGIRC avant l'age minimum AGIRC
                return nil
                
            default:
                // on ne devrait jamais passer par là
                return nil
        }
    }
    
    /// Calcul le coefficient de minoration ou de majoration de la pension complémentaire selon
    /// l'accord du 30 Octobre 2015.
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - lastKnownSituation: dernière situation connue pour le régime général
    ///   - dateOfRetirement: date de cessation d'activité
    ///   - dateOfEndOfUnemployAlloc: date de fin de perception des allocations chomage
    ///   - dateOfPensionLiquid: date de demande de liquidation de la pension
    ///   - year: année de calcul
    /// - Returns: Coefficient de minoration ou de majoration [0, 1]
    /// - Note: 
    ///  - [www.agirc-arrco.fr](https://www.agirc-arrco.fr/particuliers/demander-retraite/conditions-pour-la-retraite/)
    ///  - [www.retraite.com](https://www.retraite.com/calcul-retraite/calcul-retraite-complementaire.html)
    func coefMinorationMajoration(birthDate                : Date, // swiftlint:disable:this function_parameter_count cyclomatic_complexity
                                  lastKnownSituation       : RegimeGeneralSituation,
                                  dateOfRetirement         : Date,
                                  dateOfEndOfUnemployAlloc : Date?,
                                  dateOfPensionLiquid      : Date,
                                  during year              : Int) -> Double? {
        // nombre de trimestre manquant au moment de la liquidation de la pension pour pour obtenir le taux plein
        guard let nbTrimAudelaDuTauxPlein =
                -Retirement.model.regimeGeneral.nbTrimManquantPourTauxPlein(
                    birthDate                : birthDate,
                    lastKnownSituation       : lastKnownSituation,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc) else {
            customLog.log(level: .default, "nbTrimManquantPourTauxPlein = nil")
            return nil
        }
        //customLog.log(level: .info, "nb Trim Au-delà du Taux Plein = \(nbTrimAudelaDuTauxPlein, privacy: .public)")

        // age actuel et age du taux plein
        let age = year - birthDate.year
        guard let ageTauxPleinLegal =
                Retirement.model.regimeGeneral.ageTauxPleinLegal(birthYear: birthDate.year) else {
            customLog.log(level: .default, "ageTauxPleinLegal: Age Du Taux Plein = nil")
            return nil
        }
        
        // délai écoulé depuis la date de liqudation de la pension
        let dateAtEndOfYear = lastDayOf(year: year)
        guard let delayAfterPensionLiquidation = Date.calendar.dateComponents([.year, .month, .day],
                                                       from: dateOfPensionLiquid,
                                                       to  : dateAtEndOfYear).year else {
            customLog.log(level: .default, "délai écoulé depuis la date de liqudation de la pension = nil")
            return nil
        }
        guard delayAfterPensionLiquidation >= 0 else {
            customLog.log(level: .default, "délai écoulé depuis la date de liqudation de la pension < 0")
            return nil
        }
        
        switch nbTrimAudelaDuTauxPlein {
            case ...(-1):
                // Liquidation de la pension AVANT l'obtention du taux plein
                guard let dateAgeMinimumLegal = Retirement.model.regimeGeneral.dateAgeMinimumLegal(birthDate: birthDate) else {
                    customLog.log(level: .error,
                                  "coefMinorationMajoration:dateAgeMinimumLegal = nil")
                    fatalError("coefMinorationMajoration:dateAgeMinimumLegal = nil")
                }
                return coefMinorationMajorationAvantTauxPlein(dateOfPensionLiquid,
                                                             dateAgeMinimumLegal,
                                                             nbTrimAudelaDuTauxPlein)
                
            // Liquidation de la pension APRES l'obtention du taux plein
            case 0...3:
                // (1) Liquidation dans l'année date d'obtention du taux plein au régime général
                if age >= ageTauxPleinLegal {
                    // (2) on a dépassé l'âge d'obtention du taux plein légal
                    //     => taux plein
                    return 1.0
                } else {
                    // (2) les 3 années suivant la date d'obtention du taux plein légal (et avant 67 ans)
                    //     => minoration de 10% pendant 3 ans s’applique au montant de votre retraite complémentaire
                    return delayAfterPensionLiquidation <= 3 ? 0.9 : 1.0
                }
                
            case 4...7:
                // (1) Liquidation dans l'année date d'obtention du taux plein au régime général + 1 an
                //     => taux plein
                return 1.0
                
            case 8...11:
                // (1) Liquidation dans l'année date d'obtention du taux plein au régime général + 2 ans
                if age >= ageTauxPleinLegal {
                    // (2) on a dépassé l'âge d'obtention du taux plein légal
                    //     => taux plein
                    return 1.0
                } else {
                    // (2) les 3 années suivant la date d'obtention du taux plein légal (et avant 67 ans)
                    //     => minoration de 10% pendant 3 ans s’applique au montant de votre retraite complémentaire
                    return delayAfterPensionLiquidation <= 1 ? 1.1 : 1.0
                }
                
            case 12...15:
                // (1) Liquidation dans l'année date d'obtention du taux plein au régime général + 3 ans
                if age >= ageTauxPleinLegal {
                    // (2) on a dépassé l'âge d'obtention du taux plein légal
                    //     => taux plein
                    return 1.0
                } else {
                    // (2) les 3 années suivant la date d'obtention du taux plein légal (et avant 67 ans)
                    //     => minoration de 10% pendant 3 ans s’applique au montant de votre retraite complémentaire
                    return delayAfterPensionLiquidation <= 1 ? 1.2 : 1.0
                }
                
            case 16...19:
                // (1) Liquidation dans l'année date d'obtention du taux plein au régime général + 4 ans
                if age >= ageTauxPleinLegal {
                    // (2) on a dépassé l'âge d'obtention du taux plein légal
                    //     => taux plein
                    return 1.0
                } else {
                    // (2) les 3 années suivant la date d'obtention du taux plein légal (et avant 67 ans)
                    //     => minoration de 10% pendant 3 ans s’applique au montant de votre retraite complémentaire
                    return delayAfterPensionLiquidation <= 1 ? 1.3 : 1.0
                }
                
            case 20...:
                // ce cas ne devrait pas se produire car (67-62) * 4 = 20
                return 1.0
                
           default:
                return nil
        }
    }
    
    /// Calcul du coefficient de majoration pour enfants nés ou élevés
    /// - Parameter nbEnfantNe: nombre d'enfants nés ou élevés
    /// - Returns: coefficient de majoration [0, 1]
    /// - Note:
    ///   - [agirc-arrco.fr](https://lesexpertsretraite.agirc-arrco.fr/questions/1769054-retraite-complementaire-agirc-arrco-majorations-liees-enfants)
    ///   - [previssima.fr](https://www.previssima.fr/question-pratique/retraite-agirc-arrco-quelles-sont-les-majorations-pour-enfants.html)
    func coefMajorationPourEnfantNe(nbEnfantNe: Int) -> Double {
        switch nbEnfantNe {
            case 3...:
                return 1.0 + model.majorationPourEnfant.majorPourEnfantsNes / 100.0
            default:
                return 1.0
        }
    }
    
    /// Calcul de la mojoration de pension en € pour enfants nés ou élevés
    /// - Parameters:
    ///   - pensionBrute: montant de la pension brute
    ///   - nbEnfantNe: nombre d'enfants nés ou élevés
    /// - Returns: mojoration de pension en €
    func majorationPourEnfantNe(pensionBrute : Double,
                                nbEnfantNe   : Int) -> Double {
        let coefMajoration = coefMajorationPourEnfantNe(nbEnfantNe: nbEnfantNe)
        let majoration = pensionBrute * (coefMajoration - 1.0)
        // plafonnement de la majoration
        return min(majoration, model.majorationPourEnfant.plafondMajoEnfantNe)
    }
    
    /// Calcul du coefficient de majoration pour enfant à charge
    /// - Parameter nbEnfantACharge: nb d'enfant de moins de 18 ans ou de 21 ans à charge ou de 25 faisant des études
    /// - Returns: coefficient de majoration [0, 1]
    /// - Note:
    ///   - [agirc-arrco.fr](https://lesexpertsretraite.agirc-arrco.fr/questions/1769054-retraite-complementaire-agirc-arrco-majorations-liees-enfants)
    ///   - [previssima.fr](https://www.previssima.fr/question-pratique/retraite-agirc-arrco-quelles-sont-les-majorations-pour-enfants.html)
    func coefMajorationPourEnfantACharge(nbEnfantACharge : Int) -> Double {
        switch nbEnfantACharge {
            case 1...:
                return 1.0 + Double(nbEnfantACharge) * model.majorationPourEnfant.majorParEnfantACharge / 100.0
            default:
                return 1.0
        }
    }
}
