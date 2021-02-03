//
//  RateGrid.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 14/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

enum RateGridError: Error {
    case slicesNotAscending
    case notInRightSlice
    case negativeFloor
}

// MARK: - Tranche de barême
struct RateSlice: Codable {
    let floor : Double // euro
    let rate  : Double // %
    var disc  : Double // euro
    
    /// Calcule la taxe ou l'impôt pour un montant taxable donné situé dans cette tranche
    /// - Parameter taxableValue: montant taxable
    /// - Returns: montant de la taxe ou de l'impôt
    func tax(for taxableValue: Double) throws -> Double {
        guard taxableValue >= floor else {
            throw RateGridError.notInRightSlice
        }
        return taxableValue * rate - disc
    }
}

// MARK: - Barême fiscal
typealias RateGrid = [RateSlice]

extension RateGrid {
    
    /// Vérifie la validité des données d'entrées du barême
    func checkValidity() throws {
        guard self.allSatisfy({ $0.floor >= 0.0 }) else {
            throw RateGridError.negativeFloor
        }
        for idx in self.startIndex+1 ..< self.endIndex where self[idx].floor <= self[idx-1].floor {
            throw RateGridError.slicesNotAscending
        }
    }
    
    /// Initialise les coefficients du barême
    mutating func initialize() throws {
        try checkValidity()
        for idx in self.startIndex ..< self.endIndex {
            if idx == 0 {
                self[idx].disc = self[idx].floor * (self[idx].rate - 0)
            } else {
                self[idx].disc =
                    self[idx-1].disc +
                    self[idx].floor * (self[idx].rate - self[idx-1].rate)
            }
        }
    }
    
    /// Retrourne la tranche du barême dans laquelle se trouve une valeur recherchée
    /// - Parameter taxableValue: valeur recherchée
    /// - Returns: tranche du barême dans laquelle se trouve une valeur recherchée (nil si non trouvée)
    func slice(containing taxableValue: Double) -> RateSlice? {
        last(where: { $0.floor <= taxableValue})
    }
    
    /// Retrourne l'index de la tranche du barême dans laquelle se trouve une valeur recherchée
    /// - Parameter taxableValue: valeur recherchée
    /// - Returns: index de la tranche du barême dans laquelle se trouve une valeur recherchée (nil si non trouvée)
    func sliceIndex(containing taxableValue: Double) -> Int? {
        lastIndex(where: { $0.floor <= taxableValue})
    }
    
    /// Retourne la taxe ou l'impôt pour un montant taxable donné selon le barême
    /// - Parameter taxableValue: montant taxable
    /// - Returns: montant de la taxe ou de l'impôt (nil si hors barême)
    func tax(for taxableValue: Double) -> Double? {
        guard let slice = slice(containing: taxableValue) else { return nil }
        return try! slice.tax(for: taxableValue)
    }
}

protocol RateGridable {
    var grid: RateGrid { get set }
    
    /// Initialise les coefficients du barême
    mutating func initializeGrid() throws
    
    /// Retrourne la tranche du barême dans laquelle se trouve une valeur recherchée
    /// - Parameter taxableValue: valeur recherchée
    /// - Returns: tranche du barême dans laquelle se trouve une valeur recherchée (nil si non trouvée)
    func slice(containing taxableValue: Double) -> RateSlice?
    
    /// Retrourne l'index de la tranche du barême dans laquelle se trouve une valeur recherchée
    /// - Parameter taxableValue: valeur recherchée
    /// - Returns: index de la tranche du barême dans laquelle se trouve une valeur recherchée (nil si non trouvée)
    func sliceIndex(containing taxableValue: Double) -> Int?
    
    /// Retourne la taxe ou l'impôt pour un montant taxable donné selon le barême
    /// - Parameter taxableValue: montant taxable
    /// - Returns: montant de la taxe ou de l'impôt (nil si hors barême)
    func tax(for taxableValue: Double) -> Double?
}

extension RateGridable {
    mutating func initializeGrid() throws {
        try grid.initialize()
    }
    func slice(containing taxableValue: Double) -> RateSlice? {
        grid.slice(containing: taxableValue)
    }
    func sliceIndex(containing taxableValue: Double) -> Int? {
        grid.sliceIndex(containing: taxableValue)
    }
    
    func tax(for taxableValue: Double) -> Double? {
        grid.tax(for: taxableValue)
    }
}
