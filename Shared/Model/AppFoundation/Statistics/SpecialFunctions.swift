//
//  SpecialFunctions.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 27/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

/// Beta function
///
/// B(a, b) = ∫0..1 t^(a - 1) (1 - t)^(b - 1) dt
///
/// = 𝛤(a) 𝛤(b) / 𝛤(a + b)
public func beta(a: Double, b: Double) -> Double {
    if a + b > 100 { return exp(lbeta(a: a, b: b)) }
    return tgamma(a) * tgamma(b) / tgamma(a + b)
}

/// Log of Beta function
///
/// log B(a, b) = log 𝛤(a) + log 𝛤(b) - log 𝛤(a + b)
public func lbeta(a: Double, b: Double) -> Double {
    return lgamma(a) + lgamma(b) - lgamma(a + b)
}
