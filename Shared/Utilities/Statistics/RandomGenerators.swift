//
//  Distributions.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

fileprivate let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.Distributions")

/// Types  possibles de générateur aléatoire
enum RandomGeneratorEnum: Int, PickableEnum {
    case uniform
    case discrete
    case beta
    var pickerString: String {
        switch self {
            case .uniform:
                return "Loie Uniforme"
            case .discrete:
                return "Loie Discrete"
            case .beta:
                return "Loie Beta"
        }
    }
}


// MARK: - Générateur aléatoire selon une Loie de distribution BETA

/// Générateur aléatoire selon une Loie de distribution BETA
///
/// Usage:
///
///         var randomGenerator = BetaRandomGenerator
///                                   (minX  : minX,
///                                    maxX  : maxX,
///                                    alpha : alpha,
///                                    beta  : beta)
///         randomGenerator.initialize()
///         let rnd = randomGenerator.next()
///         let sequence = randomGenerator.sequence(of: nbRandomSamples)
///
///
/// - Note: [Reference](https://en.wikipedia.org/wiki/Beta_distribution)
///
/// ![Xcode icon](http://devimages.apple.com.edgekey.net/assets/elements/icons/128x128/xcode.png)
///
struct BetaRandomGenerator: RandomGenerator, Distribution, Codable {
    typealias Number = Double

    // MARK: - Properties
    
    var minX     : Number? // valeur minimale de X
    var maxX     : Number? // valeur minimale de X
    var pdfMax   : Number? // valeur max mémorisée au premier appel de initialize()
    var cdfCurve : Curve?  // courbe CDF mémorisée au premier appel de initialize()

    let alpha : Double
    let beta  : Double
    
    // MARK: - Methods
    
    func pdf(_ x: Double) -> Double {
        var xl = x
        if let minX = minX, let maxX = maxX {
            precondition(x >= minX, "BetaRandomGenerator: X < minX")
            precondition(x <= maxX + 0.0001, "BetaRandomGenerator: X > maxX")
            xl = (x - minX) / (maxX - minX)
            return pow((1 - xl), beta - 1.0) * pow(xl, alpha - 1.0) / Patrimoine.beta(a: alpha, b: beta) / (maxX - minX)
        } else {
            precondition(x >= 0.0, "BetaRandomGenerator: X < 0")
            precondition(x <= 1.0, "BetaRandomGenerator: X > 1")
            return pow((1 - xl), beta - 1.0) * pow(xl, alpha - 1.0) / Patrimoine.beta(a: alpha, b: beta)
        }
    }
}

// MARK: - Générateur aléatoire selon une Loie de distribution UNIFORME

/// Générateur aléatoire selon une Loie de distribution UNIFORME
///
/// Usage:
///
///         var randomGenerator = UniformRandomGenerator
///                                   (minX  : minX,
///                                    maxX  : maxX)
///         let rnd = randomGenerator.next()
///         let sequence = randomGenerator.sequence(of: nbRandomSamples)
///
/// - Note: [Reference](https://en.wikipedia.org/wiki/Uniform_distribution_(continuous))
///
struct UniformRandomGenerator: RandomGenerator, Codable {

    typealias Number = Double
    
    // MARK: - Properties
    
    var minX     : Number? // valeur minimale de X
    var maxX     : Number? // valeur minimale de X
    
    // MARK: - Methods
    
    mutating func next() -> Double {
        if let minX = minX, let maxX = maxX {
            return Double.random(in: minX ... maxX)
        } else {
            return Double.random(in: 0 ... 1)
        }
    }
}


// MARK: - Générateur aléatoire selon une Loie de distribution DISCRETE

/// Générateur aléatoire selon une Loie de distribution DISCRETE
///
/// Usage:
///
///         var randomGenerator = DiscreteRandomGenerator
///                                   (distribution: [[1.0, 0.2], [3.0, 0.5], [4.0, 0.3]])
///         let rnd = randomGenerator.next()
///         let sequence = randomGenerator.sequence(of: nbRandomSamples)
///
struct DiscreteRandomGenerator: RandomGenerator, Codable {
    var distribution : [Point]
    var pc           : [Double]? // probabilité cumulée d'occurence (dernier = 100%)

    /// Vérifie la validité des données lues en fichier JSON
    /// Si invalide FatalError
    func checkValidity() {
        // valeurs possibles croissantes pour la variable aléatoire
        guard !distribution.isEmpty else {
            customLog.log(level: .fault, "Tableau de valeurs vide dans \(Self.self, privacy: .public)")
            fatalError("Tableau de valeurs vide dans \(Self.self)")
        }
        guard distribution.isSorted( { $0.x < $1.x }) else {
            customLog.log(level: .fault, "Valeurs possibles non croisantes dans \(Self.self, privacy: .public)")
            fatalError("Valeurs possibles non croisantes dans \(Self.self)")
        }
        // la somme des probabilités d'occurence pour toutes les valeurs = 100%
        guard distribution.reduce(.zero, { (result, point) in result + point.y }) == 1.0 else {
            customLog.log(level: .fault, "Somme de probabiltés différente de 100% dans \(Self.self, privacy: .public)")
            fatalError("Somme de probabiltés différente de 100% dans \(Self.self)")
        }
        return
    }
    
    /// Initialize les valeurs à la première utilisation
    mutating func initialize() {
        checkValidity()
        var sum = 0.0
        pc = []
        for i in distribution.indices {
            sum += distribution[i].y
            pc?.append(sum)
        }
    }
    
    /// Retourne une valeur aléatoire
    mutating func next() -> Double {
        if pc == nil { initialize() }
        let rnd = Double.random(in: 0.0 ... 1.0)
        if let idx = pc!.firstIndex(where: { rnd <= $0 }) {
            return distribution[idx].x
        } else {
            return distribution[0].x
        }
    }
}
