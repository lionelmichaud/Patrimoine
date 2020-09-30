//
//  StatisticsProtocols.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 26/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Numerics

// MARK: - Distribution statistique entre minX et maxX

protocol Distribution {
    associatedtype Number: Real
    typealias Point = (x: Number, y: Number)
    typealias Curve = [Point]
    
    // MARK: - Properties
    
    var minX: Number? { get set } // valeur minimale de X
    var maxX: Number? { get set } // valeur minimale de X
    
    // MARK: - Methods
    
    /// Densité de probabilité en un point x
    /// - Parameter x: x dans [minX, maxX]
    func pdf(_ x: Number) -> Number
    
    /// Calcule le maximum de la fonction pdf(x)
    func pdfMax() -> Number
    
    /// Calcul la courbe de Densité de probabilité cumulée
    /// - Parameter length: nombre de points sur la courbe
    func cdfCurve(length: Int) -> Curve
    
    /// Densité de probabilité cumulée en un point x
    /// - Parameter x: x dans [minX, maxX]
    func cdf(x: Number, curve: Curve) -> Number
}
// implémentation par défaut
extension Distribution {
    
    func pdfMax() -> Number {
        let minX = self.minX ?? .zero
        let maxX = self.maxX ?? Number(1)
        var maxPdf = Number.zero
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
    
    func cdfCurve(length: Int) -> Curve {
        let minX = self.minX ?? .zero
        let maxX = self.maxX ?? Number(1)
        let step = (maxX - minX) / Number(length - 1)
        func x(_ i: Int) -> Number { minX + Number(i) * step }
        var s = Number.zero
        
        var curve = Curve()
        for i in 0..<length-1 {
            curve.append((x: x(i), y: s))
            // surface du trapèze élémentaire entre deux points x successifs
            let ds = (x(i+1) - x(i)) * (pdf(x(i)) + pdf(x(i+1))) / 2
            // intégrale sur [minX, x]
            s += ds
        }
        return curve
    }
    
    func cdf(x: Number, curve: Curve) -> Number {
        guard let idx = curve.firstIndex(where: { $0.x >= x }) else {
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

// MARK: - Protocol Randomizer pour générer un nombre aléatoire

protocol RandomGenerator {
    associatedtype Number: Real
    
    // MARK: - Methods
    
    mutating func next() -> Number
    mutating func sequence(of length: Int) -> [Number]
}
// implémentation par défaut
extension RandomGenerator {
    mutating func sequence(of length: Int) -> [Number] {
        var seq = [Number]()
        for _ in 1...length {
            seq.append(next())
        }
        return seq
    }
}
// implémentation par défaut uniquement pour les types conformes au protocol Distribution
extension RandomGenerator where Self: Distribution {
    mutating func next() -> Number {
        return Number(2)
    }
}

//protocol RandomGeneratorFromDistribution: RandomGenerator {
//
//    // MARK: - Methods
//
//    mutating func next() -> Number
//}
//// implémentation par défaut
//extension RandomGeneratorFromDistribution {
//    mutating func next() -> Number {
//        return Number.zero
//    }
//}
