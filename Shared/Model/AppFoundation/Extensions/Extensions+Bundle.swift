//
//  Extensions+Bundle.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// let appVersion = Bundle.mainAppVersion
extension Bundle {
    var appVersion: String? {
        self.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var appName: String? {
        self.infoDictionary?["CFBundleDisplayName"] as? String
    }
    
    static var mainBuildDate: Date {
        if let infoPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
           let infoDate = infoAttr[.modificationDate] as? Date {
            return infoDate
        }
        return Date()
    }
    
    static var mainAppVersion: String? {
        Bundle.main.appVersion
    }
    static var mainAppName: String? {
        Bundle.main.appName
    }
}
