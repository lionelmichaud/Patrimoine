//
//  AppVersion.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct AppVersion: Decodable, Versionable {

    // MARK: - Singleton

    static let shared = AppVersion()

    // MARK: - Properties

    var version: Version

    // MARK: - Static Methods

    private init() {
        self = Bundle.main.decode(AppVersion.self,
                                  from                 : "AppVersion.json",
                                  dateDecodingStrategy : .iso8601,
                                  keyDecodingStrategy  : .useDefaultKeys)
        version.initializeWithBundleValues()
    }
    
    public var name: String? {
        version.name
    }
    
    public var theVersion : String? {
        version.version
    }
    public var date    : Date? {
        version.date
    }
    public var comment : String? {
        version.comment
    }
}
