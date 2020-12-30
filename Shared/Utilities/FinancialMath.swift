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

/// Valeur future d'un investissement à capital initial et versements périodiques
/// - Parameters:
///  - payement: versement périodique
///  - interestRate: Représente le taux d’intérêt
///  - nbPeriod: Représente le nombre de versements
///  - initialValue: Représente la valeur actuelle ou la valeur que représente à la date d’aujourd’hui une série de versements futurs ;
///                   il s’agit du principal de l’emprunt
/// - Returns: Valeur future en fin de période (yc les intérêts de la période échue)
///
///  - Important: Penser à annualiser les taux et le nb de périodes
///
public func futurValue (payement     : Double,
                        interestRate : Double,
                        nbPeriod     : Int,
                        initialValue : Double = 0.0) -> Double {
    guard nbPeriod.isPOZ else {
        customLog.log(level: .fault, "futurValue/nbPeriod < 0 = \(nbPeriod, privacy: .public)")
        fatalError("futurValue/nbPeriod < 0 = \(nbPeriod)")
    }
    let a = initialValue * pow((1+interestRate), Double(nbPeriod))
    let b = (interestRate == 0.0 ?
                payement * Double(nbPeriod) :
                payement * (pow((1+interestRate), Double(nbPeriod)) - 1) / interestRate)
    return a + b
}

/// Montant du remboursement périodique d'un emprunt: capital + intérêt
/// - Parameters:
///  - loanedValue: (-) Représente la valeur actuelle ou la valeur que représente à la date d’aujourd’hui une série de remboursements futurs ;
///                  il s’agit du principal de l’emprunt
///  - interestRate: Représente le taux d’intérêt de l’emprunt. Annuel.
///  - nbPeriod:     Représente le nombre de remboursements pour l’emprunt. En années.
/// - Returns: Montant du remboursement périodique. Annuel.
/// - Note: https://formulecredit.com/mensualite.php
/// - Important: Penser à annualiser les taux et le nb de périodes
/// - Important: loanedValue doit être négatif (-)
public func loanPayement (loanedValue  : Double,
                          interestRate : Double,
                          nbPeriod     : Int) -> Double {
    return loanedValue * interestRate / (1.0 - pow(1+interestRate/12, Double(-nbPeriod*12)))
}

/// Valeur résiduelle de l'emprunt en année courante
/// - Parameters:
///  - loanedValue: Représente la valeur actuelle ou la valeur que représente à la date d’aujourd’hui une série de remboursements futurs ;
///                            il s’agit du principal de l’emprunt
///  - interestRate:  Représente le taux d’intérêt de l’emprunt. Annuel.
///  - firstYear:
///  - lastYear:
///  - currentYear:
/// - Returns: Valeur résiduelle de l'emprunt
///   - firstYear: première année de remboursement
///   - lastYear: dernière année de remboursement
///   - currentYear: année courante
/// - Important: Penser à annualiser les taux et le nb de périodes
func residualValue(loanedValue  : Double,
                   interestRate : Double,
                   firstYear    : Int,
                   lastYear     : Int,
                   currentYear  : Int) -> Double {
    guard lastYear >= firstYear else {
        customLog.log(level: .fault, "lastYear \(lastYear, privacy: .public) < firstYear \(firstYear, privacy: .public)")
        fatalError("lastYear \(lastYear) < firstYear \(firstYear)")
    }
    // Swift.print("currentYear = \(currentYear)")
    let nbPeriod = (lastYear - firstYear + 1)
    // Swift.print("nbPeriod = \(nbPeriod)")
    let payement = loanPayement(loanedValue  : loanedValue,
                                interestRate : interestRate,
                                nbPeriod     : nbPeriod)
    // Swift.print("payement = \(payement)")
    let residualValue = payement * (1 - pow((1 + interestRate), Double((currentYear - firstYear) - (lastYear - firstYear)))) / interestRate
    // Swift.print("residualValue = \(residualValue)")
    return residualValue
}
