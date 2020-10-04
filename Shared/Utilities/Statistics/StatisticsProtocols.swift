//
//  StatisticsProtocols.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 26/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Numerics

// MARK: - Protocol Distribution statistique entre minX et maxX

struct PointReal<Number: Real> : Codable where Number: Codable {
    var x: Number
    var y: Number
}

protocol Distribution {
    associatedtype Number: Real, Codable
    typealias Curve = [PointReal<Number>]
    
    // MARK: - Properties
    
    var minX     : Number? { get set } // valeur minimale de X
    var maxX     : Number? { get set } // valeur minimale de X
    var pdfMax   : Number? { get set } // valeur max mémorisée au premier appel de initialize()
    var cdfCurve : Curve?  { get set } // courbe CDF mémorisée au premier appel de initialize()
    
    // MARK: - Methods
    
    /// Initialiser les variables qui ne changeront jamais: pdfMax et cdfCurve
    mutating func initialize() // impémentation par défaut
    
    /// Densité de probabilité en un point x
    /// - Parameter x: x dans [minX, maxX]
    func pdf(_ x: Number) -> Number
    
    /// Densité de probabilité cumulée en un point x
    /// - Parameter x: x dans [minX, maxX]
    func cdf(x: Number) -> Number // impémentation par défaut
}
// implémentation par défaut
extension Distribution {
    mutating func initialize() {
        func computedPdfMax() -> Number {
            var maxPdf = -Number.infinity
            let nbSample = 1000
            let step = (maxX - minX) / Number(nbSample - 1)
            func x(_ i: Int) -> Number { minX + Number(i) * step }
            for i in 0..<nbSample {
                let p = pdf(x(i))
                if p > maxPdf {
                    maxPdf = p
                }
            }
            return maxPdf
        }
        
        func computedCdfCurve(length: Int) -> Curve {
            let step = (maxX - minX) / Number(length - 1)
            func x(_ i: Int) -> Number { minX + Number(i) * step }
            var s = Number.zero
            
            var curve = Curve()
            for i in 0..<length-1 {
                curve.append(PointReal(x: x(i), y: s))
                // surface du trapèze élémentaire entre deux points x successifs
                let ds = (x(i+1) - x(i)) * (pdf(x(i)) + pdf(x(i+1))) / 2
                // intégrale sur [minX, x]
                s += ds
            }
            return curve
        }
        
        let minX = self.minX ?? Number.zero
        let maxX = self.maxX ?? Number(1)

        precondition(minX < maxX, "Distribution.initialize: minX >= maxX")

        // initialiser la valeur de pdfMax
        self.pdfMax = computedPdfMax()
        
        // initialiser la courbe de CDF
        self.cdfCurve = computedCdfCurve(length: 100)
    }
    
    func cdf(x: Number) -> Number {
        guard let curve = cdfCurve else {
            fatalError("Distribution.cdf: CDF curve not initialized")
        }
        guard let idx = curve.firstIndex(where: { x <= $0.x }) else {
            fatalError("Distribution.cdf: x out of bound")
        }
        if idx > 0 {
            let k = (x - curve[idx-1].x) / (curve[idx].x - curve[idx-1].x)
            return curve[idx-1].y + k * (curve[idx].y - curve[idx-1].y)
        } else {
            return curve[idx].y
        }
    }
}

// MARK: - Protocol Générateur Aléatoire

protocol RandomGenerator {
    associatedtype Number: Real
    
    // MARK: - Methods
    
    mutating func next() -> Number
    mutating func sequence(of length: Int) -> [Number] // impémentation par défaut
}
// implémentation par défaut
extension RandomGenerator {
    mutating func sequence(of length: Int) -> [Number] {
        precondition(length >= 1, "RandomGenerator.sequence: length < 1")
        var seq = [Number]()
        for _ in 1...length {
            seq.append(next())
        }
        return seq
    }
}
// implémentation par défaut uniquement pour les types conformes au protocol Distribution
extension RandomGenerator where Self: Distribution, Number: Randomizable {
    
    /// Génération aléatoire par la méthode de Rejection sampling
    /// - Returns: valeur aléatoire suivant la fonction de distribution pdf(x)
    ///
    ///  - Note: [Reference](https://en.wikipedia.org/wiki/Rejection_sampling)
    mutating func next() -> Number {
        /*
         Rejection sampling works as follows:
         1. Sample a point on the x-axis from the proposal distribution.
         2. Draw a vertical line at this x-position, up to the maximum y-value of the proposal distribution.
         3. Sample uniformly along this line from 0 to the maximum of the probability density function. If the sampled value is greater than the value of the desired distribution at this vertical line, reject the x-value and return to step 1; else the x-value is a sample from the desired distribution.
         */
        repeat {
            /// Step 1. Sample a point on the x-axis from the proposal distribution.
            let range = (minX ?? .zero) ... (maxX ?? Number(1))
            let x = Number.randomized(in: range)
            /// Step 2. Draw a vertical line at this x-position, up to the maximum y-value of the proposal distribution.
            guard let ymax = pdfMax else {
                fatalError("RandomGenerator.next(): pdfMax not initialized")
            }
            guard ymax.isFinite else {
                return .zero
            }
            /// Step3. Sample uniformly along this line from 0 to the maximum of the probability density function.
            let y = Number.randomized(in: .zero ... ymax)
            if y <= pdf(x) {
                /// Step3. If the sampled value is greater than the value of the desired distribution at this vertical line, reject the x-value and return to step 1; else the x-value is a sample from the desired distribution.
                return x
            }
        } while true
    }
}

// MARK: - Protocol de service générateur aléatoire dans un interval

protocol Randomizable: Comparable {
    static func randomized(in range: ClosedRange<Self>) -> Self
}
