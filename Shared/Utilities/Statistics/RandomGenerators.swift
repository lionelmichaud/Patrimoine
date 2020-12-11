//
//  Distributions.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.Distributions")

/// Types  possibles de générateur aléatoire
enum RandomGeneratorEnum: String, PickableEnum {
    case uniform  = "Loie Uniforme"
    case discrete = "Loie Discrete"
    case beta     = "Loie Beta"
    
    var pickerString: String {
        return self.rawValue
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

    // MARK: - Type Properties
    
    static var cdfCurveSamplesNumber : Int = 1000
    
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
    typealias Number = Double
    typealias Curve  = [PointReal<Number>]

    // MARK: - Properties
    
    var pdf  : [Point]
    var cdf  : [Double]? // probabilité cumulée d'occurence (dernier = 100%)
    var minX : Number? { // valeur minimale de X
        pdf.min(by: { return ($0.x < $1.x) })?.x
    }
    var maxX         : Number? { // valeur minimale de X
        pdf.max(by: { return ($0.x > $1.x) })?.x
    }
    var cdfCurve : Curve? { // courbe CDF mémorisée au premier appel de initialize()
        precondition(cdf != nil, "DiscreteRandomGenerator.cdfCurve: propriété cdf non initialisée")
        precondition(cdf?.count == pdf.count, "DiscreteRandomGenerator.cdfCurve: longeur de pdf <> longeur de cdf")
        var curve = Curve()
        for idx in pdf.indices {
            curve.append(PointReal<Double>(x: pdf[idx].x, y: cdf![idx]))
        }
        return curve
    }

    // MARK: - Methods
    
    /// Vérifie la validité des données lues en fichier JSON
    /// Si invalide FatalError
    func checkValidity() {
        // valeurs possibles croissantes pour la variable aléatoire
        guard !pdf.isEmpty else {
            customLog.log(level: .fault, "Tableau de valeurs vide dans \(Self.self, privacy: .public)")
            fatalError("Tableau de valeurs vide dans \(Self.self)")
        }
        guard pdf.isSorted({ $0.x < $1.x }) else {
            customLog.log(level: .fault, "Valeurs possibles non croisantes dans \(Self.self, privacy: .public)")
            fatalError("Valeurs possibles non croisantes dans \(Self.self)")
        }
        // la somme des probabilités d'occurence pour toutes les valeurs = 100%
        guard pdf.reduce(.zero, { (result, point) in result + point.y }).isApproximatelyEqual(to: 1.0, absoluteTolerance: 0.0001) else {
            customLog.log(level: .fault, "Somme de probabiltés différente de 100% dans \(Self.self, privacy: .public)")
            fatalError("Somme de probabiltés différente de 100% dans \(Self.self) = \(pdf.reduce(.zero, { (result, point) in result + point.y }))")
        }
        return
    }
    
    /// Initialize les valeurs à la première utilisation
    mutating func initialize() {
        checkValidity()
        var sum = 0.0
        cdf = []
        for i in pdf.indices {
            sum += pdf[i].y
            cdf?.append(sum)
        }
    }
    
    /// Retourne une valeur aléatoire par la métthode inverse
    mutating func next() -> Double {
        if cdf == nil { initialize() }
        let rnd = Double.random(in: 0.0 ... 1.0)
        if let idx = cdf!.firstIndex(where: { rnd <= $0 }) {
            return pdf[idx].x
        } else {
            return pdf[0].x
        }
    }
}
