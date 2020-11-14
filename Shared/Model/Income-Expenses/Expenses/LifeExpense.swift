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

typealias LifeExpensesDic = DictionaryOfItemArray<LifeExpenseCategory, ExpenseArray>

extension LifeExpensesDic {
    /// Retourne un tableau des noms des dépenses dans une catégorie donnée
    func expensesNameArray(of thisCategory: LifeExpenseCategory) -> [String] {
        var table = [String]()
        // on prend une seule catégorie
        var idx = 0
        if let expenseArray = perCategory[thisCategory] {
            let nbItem = expenseArray.items.count
            for expIdx in 0..<nbItem {
                table.append(expenseArray[nbItem - 1 - expIdx].name)
                idx += 1
            }
        }
        return table
    }
    
    /// Utiliser pour générer le graphe de la vue de synthèses des dépenses
    /// - Returns: table
    func namedValuedTimeFrameTable(category: LifeExpenseCategory?)
    -> [(name: String,
         value: Double,
         prop: Bool,
         idx: Int,
         firstYearDuration: [Int])] {
        var table = [(name: String, value: Double, prop: Bool, idx: Int, firstYearDuration: [Int])]()
        
        if category == nil {
            // on prend toutes les catégories
            var idx = 0
            perCategory.sortedReversed(by: \.key.displayString).forEach { (category, expenseArray) in
                let nbItem = expenseArray.items.count
                for expIdx in 0..<nbItem {
                    if let firstYear = expenseArray[nbItem - 1 - expIdx].firstYear,
                       let lastYear  = expenseArray[nbItem - 1 - expIdx].lastYear {
                        table.append((name              : expenseArray[nbItem - 1 - expIdx].name.truncate(to: 20, addEllipsis: true),
                                      value             : expenseArray[nbItem - 1 - expIdx].value,
                                      prop              : expenseArray[nbItem - 1 - expIdx].proportional,
                                      idx               : idx,
                                      firstYearDuration : [firstYear, lastYear - firstYear + 1]))
                    }
                    idx += 1
                }
            }
            
        } else {
            // on prend une seule catégorie
            var idx = 0
            if let expenseArray = perCategory[category!] {
                let nbItem = expenseArray.items.count
                for expIdx in 0..<nbItem {
                    if let firstYear = expenseArray[nbItem - 1 - expIdx].firstYear,
                       let lastYear  = expenseArray[nbItem - 1 - expIdx].lastYear {
                        table.append((name              : expenseArray[nbItem - 1 - expIdx].name.truncate(to: 20, addEllipsis: true),
                                      value             : expenseArray[nbItem - 1 - expIdx].value,
                                      prop              : expenseArray[nbItem - 1 - expIdx].proportional,
                                      idx               : idx,
                                      firstYearDuration : [firstYear, lastYear - firstYear + 1]))
                    }
                    idx += 1
                }
            }
        }
        
        return table
    }
}
//struct LifeExpensesDic: Codable {
//
//    // properties
//
//    var perCategory: [LifeExpenseCategory: ExpenseArray] = [:]
//
//    // initialization
//
//    /// Lire toutes les dépenses dans des fichiers au format JSON.
//    /// Un fichier par catégorie de dépense.
//    /// nom du fichier "Category_LifeExpense.json"
//    init() {
//        for category in LifeExpenseCategory.allCases {
//            perCategory[category] = ExpenseArray(fileNamePrefix: category.pickerString + "_")
//        }
//    }
//
//    // methods
//
//    /// Enregistrer toutes les dépenses dans des fichiers au format JSON..
//    /// Un fichier par catégorie de dépense.
//    func storeToFile() {
//        for category in perCategory.keys {
//            // encode to JSON file
//            perCategory[category]?.storeItemsToFile()
//        }
//    }
//
//    /// Somme de toutes les dépenses, toutes catégories confondues
//    /// - Parameter atEndOf: année de calcul
//    /// - Returns: dépenses totales
//    func value(atEndOf: Int) -> Double {
//        var sum = 0.0
//        perCategory.forEach { (category, expenseArray) in
//            sum += expenseArray.value(atEndOf: atEndOf)
//        }
//        return sum
//    }
//
//    /// Utiliser pour générer le graphe de la vue de synthèses des dépense
//    /// - Returns: table
//    func namedValuedTimeFrameTable()
//    -> [(name: String, value: Double, prop: Bool, idx: Int, firstYearDuration: [Int])] {
//        var table = [(name: String, value: Double, prop: Bool, idx: Int, firstYearDuration: [Int])]()
//        var idx = 0
//        perCategory.sortedReversed(by: \.key.displayString).forEach { (category, expenseArray) in
//            let nbItem = expenseArray.items.count
//            for expIdx in 0..<nbItem {
//                table.append((name              : expenseArray[nbItem-1-expIdx].name,
//                              value             : expenseArray[nbItem-1-expIdx].value,
//                              prop             : expenseArray[nbItem-1-expIdx].proportional,
//                              idx               : idx,
//                              firstYearDuration : [expenseArray[nbItem-1-expIdx].firstYear,
//                                                   expenseArray[nbItem-1-expIdx].lastYear - expenseArray[nbItem-1-expIdx].firstYear + 1]))
//                idx += 1
//            }
//        }
//        return table
//    }
//
//    /// Liste complète à plat de toutes les dépenses valorisées, toutes catégories confondues
//    /// - Parameter atEndOf: année de calcul
//    /// - Returns: liste complète à plat de toutes les dépenses
//    func namedValueTable(atEndOf: Int) -> NamedValueArray {
//        var table = NamedValueArray()
//        perCategory.forEach { (category, expenseArray) in
//            table += expenseArray.namedValueTable(atEndOf: atEndOf)
//        }
//        return table
//    }
//
//    /// Dictionnaire des dépenses valorisées  par catégorie
//    /// - Parameter atEndOf: année de calcul
//    /// - Returns: dictionnaire des dépenses par catégorie
//    func namedValueTable(atEndOf: Int) -> [LifeExpenseCategory: NamedValueArray] {
//        var dico = [LifeExpenseCategory: NamedValueArray]()
//        for category in LifeExpenseCategory.allCases {
//            if let exps = perCategory[category] {
//                dico[category] = exps.namedValueTable(atEndOf: atEndOf)
//            }
//        }
//        return dico
//    }
//
//    /// Liste des dépenses valorisées d'une catégorie donnée
//    /// - Parameters:
//    ///   - atEndOf: année de calcul
//    ///   - inCategory: catégorie de dépenses à prendre
//    /// - Returns: liste des dépenses de cette catégorie
//    func namedValueTable(atEndOf: Int, inCategory: LifeExpenseCategory) -> NamedValueArray {
//        if let exps = perCategory[inCategory] {
//            return exps.namedValueTable(atEndOf: atEndOf)
//        } else {
//            return []
//        }
//    }
//
//    func print() {
//        for category in LifeExpenseCategory.allCases {
//            perCategory[category]?.print()
//        }
//    }
//}

// MARK: - Tableau de Dépenses

struct ExpenseArray: NameableValuableArray {
    
    // MARK: - Properties
    
    var items             = [LifeExpense]()
    var fileNamePrefix    : String
    
    // MARK: - Initializers
    
    init(fileNamePrefix: String = "") {
        self = Bundle.main.decode(ExpenseArray.self,
                                  from                 : fileNamePrefix + String(describing: Item.self) + ".json",
                                  dateDecodingStrategy : .iso8601,
                                  keyDecodingStrategy  : .useDefaultKeys)
    }
}
//typealias ExpenseArray = ItemArray<LifeExpense>

// MARK: - Dépense de la famille

struct LifeExpense: Identifiable, Codable, Hashable, NameableValuable {
    
    // MARK: - Static properties
    
    static var family: Family?
    static var simulationMode : SimulationModeEnum = .deterministic
    
    // MARK: - Static Methods
    
    /// Définir le mode de simulation à utiliser pour tous les calculs futurs
    /// - Parameter simulationMode: mode de simulation à utiliser
    static func setSimulationMode(to simulationMode : SimulationModeEnum) {
        LifeExpense.simulationMode = simulationMode
    }
    
    /// Calcule le facteur aléatoire de correction à appliquer
    /// - Note: valeur > 1.0
    static var correctionFactor: Double {
        1.0 + SocioEconomy.model.expensesUnderEvaluationrate.value(withMode: simulationMode) / 100.0
    }
    
    // MARK: - Properties
    
    var id           = UUID()
    var name         : String = ""
    var value        : Double = 0.0
    var proportional : Bool   = false
    var timeSpan     : LifeExpenseTimeSpan
    
    // MARK: - Computed properties
    
    var firstYear: Int? { // computed
        timeSpan.firstYear
    }
    
    var lastYear: Int? { // computed
        timeSpan.lastYear
    }
    
    // MARK: - Initializers
    
    init(name: String, timeSpan: LifeExpenseTimeSpan, proportional: Bool = false, value: Double) {
        self.name         = name
        self.value        = value
        self.proportional = proportional
        self.timeSpan     = timeSpan
    }
    
    init() {
        self = LifeExpense(name     : "",
                           timeSpan : .permanent,
                           value    : 0.0)
    }
    
    // MARK: - Methods
    
    func value(atEndOf year: Int) -> Double {
        if timeSpan.contains(year) {
            if proportional {
                if let family = LifeExpense.family {
                    let nbMembers = (family.nbOfAdultAlive(atEndOf: year) + family.nbOfFiscalChildren(during: year)).double()
                    return value * LifeExpense.correctionFactor * nbMembers
                } else {
                    return 0
                }
            } else {
                return value * LifeExpense.correctionFactor
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
