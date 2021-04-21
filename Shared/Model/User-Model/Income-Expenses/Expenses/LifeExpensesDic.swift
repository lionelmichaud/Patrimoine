//
//  LifeExpensesDic.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 19/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Dictionnaire de Dépenses par catégorie (un tableau de dépenses par catégorie)

typealias LifeExpensesDic = DictionaryOfNameableValuableArray<LifeExpenseCategory, LifeExpenseArray>

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
            perCategory.sortedReversed(by: \.key.displayString).forEach { (_, expenseArray) in
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
