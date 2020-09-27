//
//  Distributions.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 26/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
//import Numerics

/// Beta function
///
/// B(a, b) = ∫0..1 t^(a - 1) (1 - t)^(b - 1) dt
///
/// = 𝛤(a) 𝛤(b) / 𝛤(a + b)
public func beta(a: Double, b: Double) -> Double {
    if (a + b > 100) { return exp(lbeta(a: a, b: b)) }
    return tgamma(a) * tgamma(b) / tgamma(a + b)
}

/// Log of Beta function
///
/// log B(a, b) = log 𝛤(a) + log 𝛤(b) - log 𝛤(a + b)
public func lbeta(a: Double, b: Double) -> Double {
    return lgamma(a) + lgamma(b) - lgamma(a + b)
}

struct BetaDistribution: Distribution {
    typealias Number = Double
    
    // MARK: - Properties
    
    let alpha : Double
    let beta  : Double
    var minX  : Double?
    var maxX  : Double?

    // MARK: - Methods
    
    func pdf(x: Double) -> Double {
        if let minX = minX {
            precondition(x >= minX, "BetaDistribution: X < minX")
        } else {
            precondition(x >= 0.0, "BetaDistribution: X < 0")
        }
        if let maxX = maxX {
            precondition(x <= maxX, "BetaDistribution: X > maxX")
        } else {
            precondition(x <= 1.0, "BetaDistribution: X > 1")
        }
        return pow((1 - x), beta - 1) * pow(x, alpha - 1) * Patrimoine.beta(a: alpha, b: beta)
    }
}
