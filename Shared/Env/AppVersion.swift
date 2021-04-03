//
//  AppVersion.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct AppVersion: Decodable {

    // MARK: - Singleton

    static let shared = AppVersion()

    // MARK: - Properties

    var appVersion: Version

    // MARK: - Static Methods

    init() {
        self = Bundle.main.decode(AppVersion.self,
                                  from                 : "AppVersion.json",
                                  dateDecodingStrategy : .iso8601,
                                  keyDecodingStrategy  : .useDefaultKeys)
        appVersion.initializeWithBundleValues()
    }
}
