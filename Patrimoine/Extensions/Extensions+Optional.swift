//
//  Extensions+Optional.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

/// https://stackoverflow.com/questions/57021722/swiftui-optional-textfield
/// Usage: TextField($test.bound)
extension Optional where Wrapped == String {
    var _bound: String? {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
    public var bound: String {
        get {
            return _bound ?? ""
        }
        set {
            _bound = newValue.isEmpty ? nil : newValue
        }
    }
}
