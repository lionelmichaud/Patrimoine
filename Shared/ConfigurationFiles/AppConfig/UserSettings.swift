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
    static let shared = UserSettings()
    static let simulateVolatility = "simulateVolatility"

    @WrappedDefault(keyName: UserSettings.simulateVolatility, defaultValue: false)
    var simulateVolatility: Bool
}
