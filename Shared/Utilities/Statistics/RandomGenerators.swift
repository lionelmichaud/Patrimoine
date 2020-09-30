//
//  Distributions.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//
 
import Foundation
import os

// https://en.wikipedia.org/wiki/Beta_distribution

fileprivate let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.Distributions")

// MARK: - Générateur aléatoire selon une Loie de distribution Gamma

// https://en.wikipedia.org/wiki/Beta_distribution
struct BetaRandomGenerator: Codable, RandomGenerator {
    let min   : Double
    let max   : Double
    let alpha : Double
    let beta  : Double
    
    /// Retourne une valeur aléatoire
    func next() -> Double {
        (min - max) / 2.0
    }
}

struct BetaRG: RandomGenerator, Distribution {
    typealias Number = Double
    
    // MARK: - Properties
    
    var minX  : Double?
    var maxX  : Double?
    
    let alpha : Double
    let beta  : Double
    
    // MARK: - Methods
    
    func pdf(_ x: Double) -> Double {
        var xl = x
        if let minX = minX, let maxX = maxX {
            precondition(x >= minX, "BetaDistribution: X < minX")
            precondition(x <= maxX + 0.0001, "BetaDistribution: X > maxX")
            xl = (x - minX) / (maxX - minX)
            return pow((1 - xl), beta - 1.0) * pow(xl, alpha - 1.0) / Patrimoine.beta(a: alpha, b: beta) / (maxX - minX)
        } else {
            precondition(x >= 0.0, "BetaDistribution: X < 0")
            precondition(x <= 1.0, "BetaDistribution: X > 1")
            return pow((1 - xl), beta - 1.0) * pow(xl, alpha - 1.0) / Patrimoine.beta(a: alpha, b: beta)
        }
    }

}

// MARK: - Générateur aléatoire selon une Loie de distribution discrete

struct DiscreteRandomGenerator: Codable, RandomGenerator {
    let x  : [Double] // valeurs possibles croissantes pour la variable aléatoire
    let p  : [Double] // probabilité d'occurence pour chaque valeur possible (somme = 100%)
    var pc : [Double]? // probabilité cumulée d'occurence (dernier = 100%)
    
    /// Vérifie la validité des données lues en fichier JSON
    /// Si invalide FatalError
    func checkValidity() {
        // valeurs possibles croissantes pour la variable aléatoire
        guard !x.isEmpty else {
            customLog.log(level: .fault, "Tableau de valeurs vide dans \(Self.self, privacy: .public)")
            fatalError("Tableau de valeurs vide dans \(Self.self)")
        }
        guard x.isSorted(<) else {
            customLog.log(level: .fault, "Valeurs possibles non croisantes dans \(Self.self, privacy: .public)")
            fatalError("Valeurs possibles non croisantes dans \(Self.self)")
        }
        // la somme des probabilités d'occurence pour toutes les valeurs = 100%
        guard p.sum() == 1.0 else {
            print(x.sum())
            customLog.log(level: .fault, "Somme de probabiltés différente de 100% dans \(Self.self, privacy: .public)")
            fatalError("Somme de probabiltés différente de 100% dans \(Self.self)")
        }
        // nombre de valeurs = nombre de probabilités
        guard x.count == p.count else {
            customLog.log(level: .fault, "Nombre de valeurs != nombre de probabilités dans \(Self.self, privacy: .public)")
            fatalError("Nombre de valeurs != nombre de probabilités dans \(Self.self)")
        }
        return
    }
    
    /// Initialize les valeurs à la première utilisation
    mutating func initializedPc() {
        checkValidity()
        var sum = 0.0
        pc = []
        for i in 0..<p.count {
            sum += p[i]
            pc?.append(sum)
        }
    }
    
    /// Retourne une valeur aléatoire
    mutating func next() -> Double {
        if pc == nil { initializedPc() }
        let rnd = Double.random(in: 0.0 ... 1.0)
        print("rnd = ", rnd)
        if let idx = pc!.lastIndex(where: { rnd >= $0 }) {
            print("random = ", x[idx + 1])
            return x[idx]
        } else {
            print("random = ", x[0])
            return x[0]
        }
    }
}
