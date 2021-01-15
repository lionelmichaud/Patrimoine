//
//  FinancialMath.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//
// https://gist.github.com/glaucocustodio/58f86d7e5f184f7b6f2c

import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "FinancialMath")

enum FinancialMathError: Error {
    case negativeNbPeriod
    case periodOutOfBound
}
/// Valeur future d'un investissement à capital initial et versements périodiques
/// Les versements sont fait en fin d'année.
/// - Parameters:
///  - payement: versement périodique
///  - interestRate: Représente le taux d’intérêt par période. (100% = 1.0)
///  - nbPeriod: Représente le nombre de versements. Par période.
///  - initialValue: Représente la valeur actuelle ou la valeur que représente à la date d’aujourd’hui une série de versements futurs ;
///                   il s’agit du principal de l’emprunt
/// - Returns: Valeur future en fin de période (yc les intérêts de la période échue)
/// - Important: Penser à mettre les taux et le nb de périodes en accords (taux par période)
///
public func futurValue (payement     : Double,
                        interestRate : Double,
                        nbPeriod     : Int,
                        initialValue : Double = 0.0) throws -> Double {
    guard nbPeriod.isPOZ else {
        customLog.log(level: .fault, "futurValue/nbPeriod < 0 = \(nbPeriod, privacy: .public)")
        throw FinancialMathError.negativeNbPeriod
    }
    let a = initialValue * pow((1+interestRate), Double(nbPeriod))
    let b = (interestRate == 0.0 ?
                payement * Double(nbPeriod) :
                payement * (pow((1+interestRate), Double(nbPeriod)) - 1) / interestRate)
    return a + b
}

/// Montant du remboursement périodique d'un emprunt: capital + intérêt.
/// Les remboursements sont fait en fin d'année.
/// - Parameters:
///   - loanedValue: (-) Représente la valeur actuelle ou la valeur que représente à la date d’aujourd’hui une série de remboursements futurs ;
///                     il s’agit du principal de l’emprunt
///   - interestRate: Représente le taux d’intérêt de l’emprunt. Par période. (100% = 1.0)
///   - nbPeriod:     Représente le nombre de remboursements pour l’emprunt.
/// - Returns: Montant du remboursement périodique.
/// - Note: [Reference](https://formulecredit.com/mensualite.php)
/// - Important:
///   - Penser à mettre les taux et le nb de périodes en accords (taux par période)
///   - loanedValue doit être négatif (-)
public func loanPayement (loanedValue  : Double,
                          interestRate : Double,
                          nbPeriod     : Int) -> Double {
    return loanedValue * interestRate / (1.0 - pow(1+interestRate, Double(-nbPeriod)))
}

/// Valeur résiduelle de l'emprunt à la fin de l'année courante.
/// - Parameters:
///   - loanedValue: Représente la valeur actuelle ou la valeur que représente à la date d’aujourd’hui une série de remboursements futurs ;
///                  il s’agit du principal de l’emprunt
///   - interestRate:  Représente le taux d’intérêt de l’emprunt. Par période. (100% = 1.0)
///   - firstPeriod: première période de remboursement
///   - lastPeriod: dernière période de remboursement
///   - currentPeriod: fin de la période
/// - Returns: Valeur résiduelle de l'emprunt
/// - Important:
///   - Penser à mettre les taux et le nb de périodes en accords (taux par période)
/// - Warning:
///   - L'avaluation est faite en fin de période donc la valuer résiduelle = montant emprunté à la fin de l'a période précédant la 1ère période de remboursement.
func residualValue(loanedValue   : Double,
                   interestRate  : Double,
                   firstPeriod   : Int,
                   lastPeriod    : Int,
                   currentPeriod : Int) throws -> Double {
    guard lastPeriod >= firstPeriod else {
        throw FinancialMathError.periodOutOfBound
    }
    guard ((firstPeriod-1)...lastPeriod).contains(currentPeriod) else {
        throw FinancialMathError.periodOutOfBound
    }
    // Swift.print("currentYear = \(currentYear)")
    let nbPeriod = (lastPeriod - firstPeriod + 1)
    // Swift.print("nbPeriod = \(nbPeriod)")
    let payement = loanPayement(loanedValue  : loanedValue,
                                interestRate : interestRate,
                                nbPeriod     : nbPeriod)
    // Swift.print("payement = \(payement)")
    let residualValue = payement * (1 - pow((1 + interestRate), Double((currentPeriod - firstPeriod) - (lastPeriod - firstPeriod)))) / interestRate
    // Swift.print("residualValue = \(residualValue)")
    return residualValue
}
