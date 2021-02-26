//
//  Adult+Pension.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

extension Adult {
    /// true si est vivant à la fin de l'année et année égale ou postérieur à l'année de liquidation de la pension du régime général
    /// - Parameter year: première année incluant des revenus
    func isPensioned(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (dateOfPensionLiquid.year <= year)
    }
    
    /// true si est vivant à la fin de l'année et année égale ou postérieur à l'année de liquidation de la pension du régime complémentaire
    /// - Parameter year: première année incluant des revenus
    func isAgircPensioned(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (dateOfAgircPensionLiquid.year <= year)
    }
    
    func pensionRegimeGeneral(during year: Int)
    -> (brut: Double, net: Double) {
        // pension du régime général
        if let (brut, net) =
            Retirement.model.regimeGeneral.pension(
                birthDate                : birthDate,
                dateOfRetirement         : dateOfRetirement,
                dateOfEndOfUnemployAlloc : dateOfEndOfUnemployementAllocation,
                dateOfPensionLiquid      : dateOfPensionLiquid,
                lastKnownSituation       : lastKnownPensionSituation,
                nbEnfant                 : 3,
                during                   : year) {
            return (brut, net)
        } else {
            return (0, 0)
        }
    }
    
    func pensionRegimeAgirc(during year: Int)
    -> (brut: Double, net: Double) {
        if let pensionAgirc =
            Retirement.model.regimeAgirc.pension(
                lastAgircKnownSituation  : lastKnownAgircPensionSituation,
                birthDate                : birthDate,
                lastKnownSituation       : lastKnownPensionSituation,
                dateOfRetirement         : dateOfRetirement,
                dateOfEndOfUnemployAlloc : dateOfEndOfUnemployementAllocation,
                dateOfPensionLiquid      : dateOfAgircPensionLiquid,
                nbEnfantNe               : nbOfChildren(),
                nbEnfantACharge          : nbOfFiscalChildren(during: year),
                during                   : year) {
            return (pensionAgirc.pensionBrute,
                    pensionAgirc.pensionNette)
        } else {
            return (0, 0)
        }
    }
    
    /// Calcul de la pension de retraite
    /// - Parameter year: année
    /// - Returns: pension brute, nette de charges sociales, taxable à l'IRPP
    func pension(during year   : Int,
                 withReversion : Bool = true) -> BrutNetTaxable {
        guard isAlive(atEndOf: year) else {
            return BrutNetTaxable(brut: 0, net: 0, taxable: 0)
        }
        var brut = 0.0
        var net  = 0.0
        // pension du régime général
        if isPensioned(during: year) {
            let pension = pensionRegimeGeneral(during: year)
            let nbWeeks = (dateOfPensionLiquidComp.year == year ? (52 - dateOfPensionLiquid.weekOfYear).double() : 52)
            brut += pension.brut * nbWeeks / 52
            net  += pension.net  * nbWeeks / 52
        }
        // ajouter la pension du régime complémentaire
        if isAgircPensioned(during: year) {
            let pension = pensionRegimeAgirc(during: year)
            let nbWeeks = (dateOfAgircPensionLiquidComp.year == year ? (52 - dateOfAgircPensionLiquid.weekOfYear).double() : 52)
            brut += pension.brut * nbWeeks / 52
            net  += pension.net  * nbWeeks / 52
        }
        if withReversion {
            // ajouter la pension de réversion s'il y en a une
            if let pensionReversion = Adult.adultRelativesProvider.spouseOf(self)?.pensionReversionForSpouse(during: year) {
                brut += pensionReversion.brut
                net  += pensionReversion.net
            }
        }
        let taxable = try! Fiscal.model.pensionTaxes.taxable(brut: brut, net: net)
        return BrutNetTaxable(brut: brut, net: net, taxable: taxable)
    }
    
    /// Calcul de la pension de réversion laissée au conjoint
    /// - Parameter year: année
    /// - Returns: pension de réversion laissée au conjoint
    /// - Warning: pension laissée au conjoint
    func pensionReversionForSpouse(during year: Int)
    -> (brut: Double, net: Double)? {
        // la personne est décédée
        guard !isAlive(atEndOf: year) else {
            // la personne est vivante => pas de pension de réversion
            return nil
        }
        // le conjoint existe
        guard let spouse = Adult.adultRelativesProvider.spouseOf(self) else {
            return nil
        }
        // le conjoint est vivant
        guard spouse.isAlive(atEndOf: year) else {
            return nil
        }
        // somme des pensions brutes l'année précédent le décès
        // et de l'année courante pour le conjoint survivant
        let yearBeforeDeath = self.yearOfDeath - 1
        guard isPensioned(during: yearBeforeDeath) else {
            // la personne n'était pas pensionnée avant son décès => pas de pension de réversion
            return nil
        }
        let pensionDuDecede         = self.pension(during        : yearBeforeDeath,
                                                   withReversion : false)
        let pensionDuConjoint       = spouse.pension(during        : year,
                                                     withReversion : false)
        let pensionTotaleAvantDeces = (brut: pensionDuDecede.brut + pensionDuConjoint.brut,
                                       net : pensionDuDecede.net  + pensionDuConjoint.net)
        // la pension du conjoint survivant, avec réversion, est limitée à un % de la somme des deux
        let pensionBruteApresDeces =
            Retirement.model.reversion.pensionReversion(pensionDecedent : pensionDuDecede.brut,
                                                        pensionSpouse   : pensionDuConjoint.brut)
        // le complément de réversion est calculé en conséquence
        let reversionBrut = zeroOrPositive(pensionBruteApresDeces - pensionDuConjoint.brut)
        let reversionNet  = reversionBrut * (pensionTotaleAvantDeces.net / pensionTotaleAvantDeces.brut)
        return (reversionBrut, reversionNet)
    }
}
