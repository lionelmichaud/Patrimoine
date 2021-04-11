//
//  UserSettings.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Foil

// MARK: - Enumération de nature d'une propriété

enum OwnershipNature: String, PickableEnum {
    case generatesRevenue = "Uniquement les biens génèrant revenu/dépense"
    case sellable         = "Uniquement les biens cessibles"
    case all              = "Tous les biens"
    
    var pickerString: String {
        return self.rawValue
    }
}

enum AssetEvaluationMethod: String, PickableEnum {
    case totalValue = "Valeur totale"
    case ownedValue = "Valeur possédée"
    
    var pickerString: String {
        return self.rawValue
    }
}

struct UserSettings {
    static var shared = UserSettings()
    static let simulateVolatility    = "simulateVolatility"
    static let ownershipSelection    = "ownershipSelection"
    static let assetEvaluationMethod = "assetEvaluationMethod"

    @WrappedDefault(keyName: UserSettings.simulateVolatility,
                    defaultValue: false)
    var simulateVolatility: Bool
    
    @WrappedDefault(keyName: UserSettings.ownershipSelection,
                    defaultValue: OwnershipNature.all.rawValue)
    var ownershipSelectionString: String
    var ownershipSelection: OwnershipNature {
        get {
            OwnershipNature(rawValue: ownershipSelectionString) ?? OwnershipNature.all
        }
        set {
            ownershipSelectionString = newValue.rawValue
        }
    }
    
    @WrappedDefault(keyName: UserSettings.assetEvaluationMethod,
                    defaultValue: AssetEvaluationMethod.ownedValue.rawValue)
    var assetEvaluationMethodString: String
    var assetEvaluationMethod: AssetEvaluationMethod {
        get {
            AssetEvaluationMethod(rawValue: assetEvaluationMethodString) ?? AssetEvaluationMethod.ownedValue
        }
        set {
            assetEvaluationMethodString = newValue.rawValue
        }
    }

}
