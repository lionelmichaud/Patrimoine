//
//  ItemSelectionList.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "ItemSelection")

// MARK: - Liste des items affichés sur un Graph et sélectionnables individuellement

typealias ItemSelection = (label: String, selected: Bool)
typealias ItemSelectionList = [ItemSelection]

extension ItemSelectionList {
    /// retourne true si la liste d'items contient l'item sélectionné
    /// - Parameters:
    ///   - name: nom de l'item recherché
    ///   - itemSelection: liste d'item
    /// - Returns: true si la liste d'items contient l'item sélectionné
    func contains(_ name: String) -> Bool {
        self.contains(where: { item in
            (item.label == name && item.selected)
        })
    }
    
    /// Vérifie si une ou plusieurs catégories ont étées secltionnées dans la liste du menu
    /// - Returns: retourne TRUE si une seule catégorie sélectionnée
    func onlyOneCategorySelected () -> Bool {
        let count = self.reduce(.zero, { result, element in result + (element.selected ? 1 : 0) })
        return count == 1
    }
    
    /// Retourne vrai si toutes les catégories de ls liste sont sélectionnées
    func allCategoriesSelected() -> Bool {
        let count = self.reduce(.zero, { result, element in result + (element.selected ? 1 : 0) })
        return count == self.count
    }
    
    /// Retourne vrai si aucune des catégories de ls liste n'est sélectionnées
    func noneCategorySelected() -> Bool {
        let count = self.reduce(.zero, { result, element in result + (element.selected ? 1 : 0) })
        return count == 0
    }
    
    /// Retourne le nom de la première catégorie sélectionnée dans la liste du menu
    /// - Returns: nom de la première catégorie sélectionnée dans la liste du menu
    func firstCategorySelected () -> String? {
        if let foundSelection = self.first(where: { $0.selected }) {
            return foundSelection.label
        } else {
            customLog.log(level: .error, "firstCategorySelected/foundSelection = false : catégorie non trouvée dans le menu")
            return nil
        }
    }
}
