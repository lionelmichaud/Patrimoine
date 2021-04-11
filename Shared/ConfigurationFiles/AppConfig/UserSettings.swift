//
//  UserSettings.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Foil

struct UserSettings {
    static var shared = UserSettings()
    static let simulateVolatility = "simulateVolatility"
    static let ownershipSelection = "ownershipSelection"

    @WrappedDefault(keyName: UserSettings.simulateVolatility,
                    defaultValue: false)
    var simulateVolatility: Bool
    
    @WrappedDefault(keyName: UserSettings.ownershipSelection,
                    defaultValue: OwnershipNature.fullOwners.rawValue)
    var ownershipSelectionString: String
    var ownershipSelection: OwnershipNature {
        get {
            OwnershipNature(rawValue: ownershipSelectionString)!
        }
        set {
            ownershipSelectionString = newValue.rawValue
        }
    }
}
