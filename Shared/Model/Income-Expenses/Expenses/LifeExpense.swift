//
//  Expense.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Dictionnaire de Dépenses par catégorie (un tableau de dépenses par catégorie)

struct LifeExpenses: Codable {
    
    // properties
    
    var perCategory: [LifeExpenseCategory: ExpenseArray] = [:]
    
    // initialization
    
    /// Lire toutes les dépenses dans des fichiers au format JSON..
    /// Un fichier par catégorie de dépense.
    init() {
        for category in LifeExpenseCategory.allCases {
            perCategory[category] = ExpenseArray(fileNamePrefix: category.pickerString + "_")
        }
    }
    
    // methods
    
    /// Enregistrer toutes les dépenses dans des fichiers au format JSON..
    /// Un fichier par catégorie de dépense.
    func storeToFile() {
        for category in perCategory.keys {
            // encode to JSON file
            perCategory[category]?.storeItemsToFile()
        }
    }
    
    /// Somme de toutes les dépenses, toutes catégories confondues
    /// - Parameter atEndOf: année de calcul
    /// - Returns: dépenses totales
    func value(atEndOf: Int) -> Double {
        var sum = 0.0
        perCategory.forEach { (category, expenseArray) in
            sum += expenseArray.value(atEndOf: atEndOf)
        }
        return sum
    }
    
    /// Liste complète à plat de toutes les dépenses, toutes catégories confondues
    /// - Parameter atEndOf: année de calcul
    /// - Returns: liste complète à plat de toutes les dépenses
    func namedValueTable(atEndOf: Int) -> [(name: String, value: Double)] {
        var table = [(name: String, value: Double)]()
        perCategory.forEach { (category, expenseArray) in
            table += expenseArray.namedValueTable(atEndOf: atEndOf)
        }
        return table
    }
    
    func namedValuedTimeFrameTable()
    -> [(name: String, value: Double, prop: Bool, idx: Int, firstYearDuration: [Int])] {
        var table = [(name: String, value: Double, prop: Bool, idx: Int, firstYearDuration: [Int])]()
        var idx = 0
        perCategory.sortedReversed(by: \.key.displayString).forEach { (category, expenseArray) in
            let nbItem = expenseArray.items.count
            for expIdx in 0..<nbItem {
                table.append((name              : expenseArray[nbItem-1-expIdx].name,
                              value             : expenseArray[nbItem-1-expIdx].value,
                              prop             : expenseArray[nbItem-1-expIdx].proportional,
                              idx               : idx,
                              firstYearDuration : [expenseArray[nbItem-1-expIdx].firstYear,
                                                   expenseArray[nbItem-1-expIdx].lastYear - expenseArray[nbItem-1-expIdx].firstYear + 1]))
                idx += 1
            }
        }
        return table
    }
    
    /// Liste dles dépenses par catégorie
    /// - Parameter atEndOf: année de calcul
    /// - Returns: liste des dépenses par catégorie
    func namedValueTable(atEndOf: Int) -> [LifeExpenseCategory: [(name: String, value: Double)]] {
        var dico = [LifeExpenseCategory: [(name: String, value: Double)]]()
        for category in LifeExpenseCategory.allCases {
            if let exps = perCategory[category] {
                dico[category] = exps.namedValueTable(atEndOf: atEndOf)
            }
        }
        return dico
    }
    
    /// Liste dles dépenses d'une catégorie donnée
    /// - Parameters:
    ///   - atEndOf: année de calcul
    ///   - inCategory: catégorie de dépenses à prendre
    /// - Returns: liste des dépenses de cette catégorie
    func namedValueTable(atEndOf: Int, inCategory: LifeExpenseCategory) -> [(name: String, value: Double)] {
        if let exps = perCategory[inCategory] {
            return exps.namedValueTable(atEndOf: atEndOf)
        } else {
            return []
        }
    }
    
    func print() {
        for category in LifeExpenseCategory.allCases {
            perCategory[category]?.print()
        }
    }
}

// MARK: - Tableau de Dépenses

typealias ExpenseArray = ItemArray<LifeExpense>

// MARK: - Dépense de la famille

struct LifeExpense: Identifiable, Codable, Hashable, NameableAndValueable {
    
    // MARK: - Static properties

    static var family: Family?
    
    // MARK: - Properties
    
    var id           = UUID()
    var name         : String = ""
    var value        : Double = 0.0
    var proportional : Bool   = false
    var timeSpan     : LifeExpenseTimeSpan

    // MARK: - Computed properties
    
    var firstYear: Int { // computed
        timeSpan.firstYear
    }
    
    var lastYear: Int { // computed
        timeSpan.lastYear
    }
    
    // MARK: - Initialization
    
    init(name: String, timeSpan: LifeExpenseTimeSpan, proportional: Bool = false, value: Double) {
        self.name         = name
        self.value        = value
        self.proportional = proportional
        self.timeSpan     = timeSpan
    }
    
    // MARK: - Methods
    
    func value(atEndOf year: Int) -> Double {
        if timeSpan.contains(year) {
            if proportional {
                if let family = LifeExpense.family {
                    return value * Double(family.nbOfAdultAlive(atEndOf: year) + family.nbOfFiscalChildren(during: year))
                } else {
                    return 0
                }
            } else {
                return value
            }
        } else {
            return 0.0
        }
    }
    
    func print() {
        Swift.print("    category: \(name) ")
        Swift.print("      time span:    \(timeSpan)")
        Swift.print("      amount:       \(value) €")
        Swift.print("      proportional: \(proportional)")
    }
}

extension LifeExpense: Comparable {
    static func < (lhs: LifeExpense, rhs: LifeExpense) -> Bool { (lhs.name < rhs.name) }
}

