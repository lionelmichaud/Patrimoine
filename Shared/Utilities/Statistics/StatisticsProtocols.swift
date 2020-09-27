//
//  StatisticsProtocols.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 26/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Numerics

// MARK: - Protocol Randomizer pour générer un nombre aléatoire

protocol Randomizer {
    associatedtype Number: Real
    
    // MARK: - Methods
    
    mutating func next() -> Number
    mutating func sequence(of length: Int) -> [Number]
}
// implémentation par défaut
extension Randomizer {
    mutating func sequence(of length: Int) -> [Number] {
        var seq = [Number]()
        for _ in 1...length {
            seq.append(next())
        }
        return seq
    }
}

// MARK: - Dsitribution statistique entre minX et maxX

protocol Distribution {
    associatedtype Number: Real
    
    // MARK: - Properties
    
    var minX: Number? { get set } // valeur minimale de X
    var maxX: Number? { get set } // valeur minimale de X
    
    // MARK: - Methods
    
    func pdf(x: Number) -> Number
}
