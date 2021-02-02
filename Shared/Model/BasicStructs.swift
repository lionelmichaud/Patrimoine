//
//  BasicStructs.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import os
import Foundation
import SwiftUI

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "BasicStructs")

// MARK: - Liste des items affichés sur un Graph et sélectionnables individuellement

typealias ItemSelection = (label: String, selected: Bool)
typealias ItemSelectionList = [ItemSelection]

extension ItemSelectionList {
    /// retourne true si la liste d'items contient l'item sélectionné
    /// - Parameters:
    ///   - name: nom de l'item recherché
    ///   - itemSelection: liste d'item
    /// - Returns: true si la liste d'items contient l'item sélectionné
    func selectionContains(_ name: String) -> Bool {
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
    func NoneCategorySelected() -> Bool {
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

// MARK: - Versioning

///  - Note: [Reference](https://en.wikipedia.org/wiki/Software_versioning)
struct Version: Codable {
    
    // MARK: - Properties
    
    var name    : String?
    var version : String? // "Major.Minor.Patch"
    var date    : Date?
    var comment : String?

    // MARK: - Computed Properties
    
    var major   : Int? {
        guard let version = version else { return nil }
        if let major = version.split(whereSeparator: { $0 == "." }).first {
            return Int(major)
        } else {
            return nil
        }
    }
    var minor   : Int? {
        guard let version = version else { return nil }
        let parts = version.split(whereSeparator: { $0 == "." })
        if parts.count >= 1 {
            return Int(parts[1])
        } else {
            return nil
        }
    }
    var patch   : Int? {
        guard let version = version else { return nil }
        let parts = version.split(whereSeparator: { $0 == "." })
        if parts.count >= 2 {
            return Int(parts[2])
        } else {
            return nil
        }
    }

    // MARK: - Static Methods
    
    static func toVersion(major: Int,
                          minor: Int,
                          patch: Int?) -> String {
        if let patch = patch {
            return String(major) + "." + String(minor) + "." + String(patch)
        } else {
            return String(major) + "." + String(minor)
        }
    }
    
    // MARK: - Methods
    
    mutating func initializeWithBundleValues() {
        if version == nil {
            version = Bundle.mainAppVersion
        }
        if name == nil {
            name = Bundle.mainAppName
        }
        if date == nil {
            date = Bundle.mainBuildDate
        }
    }
}

// MARK: - Point(x, y)

struct Point: Codable, ExpressibleByArrayLiteral {
    typealias ArrayLiteralElement = Double
    
    var x: Double
    var y: Double
    
    init(arrayLiteral elements: Double...) {
        self.x = elements[0]
        self.y = elements[1]
    }
    
    init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}

// MARK: - Ordre de tri

enum SortingOrder {
    case ascending
    case descending
    
    var imageSystemName: String {
        switch self {
            case .ascending:
                return "arrow.up.circle"
            case .descending:
                return "arrow.down.circle"
        }
    }
    mutating func toggle() {
        switch self {
            case .ascending:
                self = .descending
            case .descending:
                self = .ascending
        }
    }
}

struct BrutNetTaxable {
    var brut    : Double
    var net     : Double
    var taxable : Double
}
