//
//  Extensions+Bundle.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

//let appVersion = Bundle.mainAppVersion
extension Bundle {
    var appVersion: String? {
        self.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    static var mainAppVersion: String? {
        Bundle.main.appVersion
    }
}
