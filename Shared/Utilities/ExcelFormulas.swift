//
//  ExcelFormulas.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

class ExcelFormulas {
    /// calcule le remboursement d’un emprunt sur la base de remboursements et d’un taux d’intérêt constants
    /// - Parameters:
    ///   - rate: Représente le taux d’intérêt de l’emprunt
    ///   - nper: Représente le nombre de remboursements pour l’emprunt
    ///   - pv: Représente la valeur actuelle ou la valeur que représente à la date d’aujourd’hui une série de remboursements futurs ;
    ///          il s’agit du principal de l’emprunt
    ///   - fv: Représente la valeur capitalisée, c’est-à-dire le montant que vous souhaitez obtenir après le dernier paiement.
    ///          Si vc est omis, la valeur par défaut est 0 (zéro), c’est-à-dire que la valeur capitalisée d’un emprunt est égale à 0.
    ///   - type: Représente le nombre 0 (zéro) ou 1 et indique quand les paiements doivent être effectués. 0 : en fin de période.
    ///            1 : en début de période
    func pmt(rate : Double, nper : Double, pv : Double, fv : Double = 0, type : Double = 0) -> Double {
        return ((-pv * pvif(rate: rate, nper: nper) - fv) / ((1.0 + rate * type) * fvifa(rate: rate, nper: nper)))
    }
    
    func pow1pm1(x : Double, y : Double) -> Double {
        return (x <= -1) ? pow((1 + x), y) - 1 : exp(y * log(1.0 + x)) - 1
    }
    
    func pow1p(x : Double, y : Double) -> Double {
        return (abs(x) > 0.5) ? pow((1 + x), y) : exp(y * log(1.0 + x))
    }
    
    /// The present value interest factor (PVIF) is a tool that is used to simplify the calculation for determining the present value
    /// of a sum of money to be received at some future point in time. PVIFs are often presented in the form of a table with values
    /// for different time periods and interest rate combinations
    /// - Parameters:
    ///   - rate: Représente le taux d’intérêt de l’emprunt
    ///   - nper: Représente le nombre de remboursements pour l’emprunt
    func pvif(rate : Double, nper : Double) -> Double {
        return pow1p(x: rate, y: nper)
    }
    
    /// FVIFA (Future Value Interest Factor Annuity)
    /// - Parameters:
    ///   - rate: Représente le taux d’intérêt de l’emprunt
    ///   - nper: Représente le nombre de remboursements pour l’emprunt
    func fvifa(rate : Double, nper : Double) -> Double {
        return (rate == 0) ? nper : pow1pm1(x: rate, y: nper) / rate
    }
    
    /// Renvoie le nombre de versements nécessaires pour rembourser un emprunt à taux d’intérêt constant,
    /// sachant que ces versements doivent être constants et périodiques
    /// - Parameters:
    ///   - rate: Représente le taux d’intérêt de l’emprunt
    ///   - pv: Représente la valeur actuelle ou la valeur que représente à la date d’aujourd’hui une série de remboursements futurs ;
    ///          il s’agit du principal de l’emprunt
    ///   - pmt: Représente le montant d’un versement périodique ; celui-ci reste constant pendant toute la durée de l’opération.
    ///           En règle générale, vpm comprend le principal et les intérêts, mais aucune autre charge, ni impôt
    func nper(rate: Double, pv: Double, pmt: Double) -> Double {
        return log(pow((1-pv*rate/pmt), -1))/log(1+rate)
    }
    
    /// calcule la valeur actuelle d’un emprunt ou d’un investissement sur la base d’un taux d’intérêt constant.
    /// - Parameters:
    ///   - rate: Représente le taux d’intérêt de l’emprunt
    ///   - nper: Représente le nombre de remboursements pour l’emprunt
    ///   - pmt: Représente le montant du paiement pour chaque période et reste constant pendant toute la durée de l’opération.
    ///          En règle générale, vpm comprend le montant principal et les intérêts mais exclut toute autre charge ou tout autre impôt.
    ///          Par exemple, le paiement mensuel d’un emprunt d’une $10 000, d’une durée de quatre ans sur 12% est $263,33.
    ///          Vous devez entrer-263,33 dans la formule comme VPM. Si l’argument vpm est omis, vous devez inclure l’argument vc
    func pv(rate: Double, nper: Double, pmt: Double) -> Double {
        return pmt * ((1 - pow((1 + rate), -nper)) / rate)
    }
}
