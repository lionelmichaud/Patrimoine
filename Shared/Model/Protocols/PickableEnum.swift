//
//  PickableEnum.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Protocol PickableEnum pour Picker d'un Enum

protocol PickableEnum: CaseIterable, Hashable {
    var pickerString: String { get }
    var displayString: String { get }
}

// implémntation par défaut
extension PickableEnum {
    // default implementation
    var displayString: String { pickerString }
}

// MARK: - Protocol PickableEnum & Identifiable pour Picker d'un Enum

protocol PickableIdentifiableEnum: PickableEnum, Identifiable { }

// MARK: - Protocol Versionable pour versionner des données

protocol Versionable {
    var version : Version { get set }
}
